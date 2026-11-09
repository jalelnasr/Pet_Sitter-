import 'dart:async';

import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/utils/format.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Liste des conversations, rafraîchie régulièrement tant que l'écran est ouvert.
class MessagesViewModel extends ViewModel {
  MessagesViewModel(this._messages, {this.asSitter = false, Duration? refreshEvery = const Duration(seconds: 15)}) {
    load();
    if (refreshEvery != null) {
      _timer = Timer.periodic(refreshEvery, (_) => load(silent: true));
    }
  }

  final MessageRepository _messages;
  final bool asSitter;
  Timer? _timer;

  List<Conversation> _conversations = const [];
  List<Conversation> get conversations => _conversations;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool get isEmpty => !_loading && _error == null && _conversations.isEmpty;
  int get unreadTotal => _conversations.fold(0, (sum, c) => sum + c.unread);

  /// [silent] : rafraîchissement en arrière-plan, sans indicateur ni message d'erreur.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = _conversations.isEmpty;
      _error = null;
      notify();
    }
    try {
      _conversations = await _messages.conversations(asSitter: asSitter);
      _error = null;
    } on MessagingException catch (e) {
      if (!silent || _conversations.isEmpty) _error = e.message;
    } finally {
      _loading = false;
      notify();
    }
  }

  /// La conversation vient d'être ouverte : sa pastille disparaît sans attendre le serveur.
  void markOpened(Conversation c) {
    _conversations = [for (final x in _conversations) x.id == c.id ? x.copyWith(unread: 0) : x];
    notify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Conversation (messages envoyés au serveur, nouveaux messages récupérés régulièrement)
/// et journal de garde.
class ChatViewModel extends ViewModel {
  ChatViewModel({
    required MessageRepository messages,
    required PetRepository pets,
    required SitterSpaceRepository sitterSpace,
    Conversation? conversation,
    this.asSitter = false,
    Duration? pollEvery = const Duration(seconds: 4),
  }) : _repo = messages,
       _conversation = conversation,
       _journal = messages.journal(),
       _owner = pets,
       _sitter = sitterSpace.me,
       caredPets = pets.myPets().take(2).toList() {
    load();
    if (pollEvery != null) {
      _timer = Timer.periodic(pollEvery, (_) => refresh());
    }
  }

  final MessageRepository _repo;
  final Map<String, List<LogEntry>> _journal;
  final PetRepository _owner;
  final Sitter _sitter;
  Timer? _timer;

  /// Vrai quand c'est le sitter qui consulte (il peut alors écrire dans le journal).
  final bool asSitter;

  /// Animaux gardés (démonstration : Simba et Kiwi).
  final List<Pet> caredPets;

  Conversation? _conversation;
  Conversation? get conversation => _conversation;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Aucune conversation à afficher (ouverture sans conversation précise et liste vide).
  bool _noConversation = false;
  bool get noConversation => _noConversation;

  bool _refreshing = false;
  int _tempIds = 0;

  // ———— Assistant IA

  /// Message refusé par l'assistant (arnaque, insulte) en attente de la décision de l'expéditeur.
  ({String text, String reason})? _riskWarning;
  ({String text, String reason})? get riskWarning => _riskWarning;

  List<String> _suggestions = const [];
  List<String> get suggestions => _suggestions;

  bool _suggestionsLoading = false;
  bool get suggestionsLoading => _suggestionsLoading;

  /// Vrai quand les suggestions viennent de l'IA (Groq), faux pour les règles locales.
  bool _suggestionsFromAi = false;
  bool get suggestionsFromAi => _suggestionsFromAi;

  // ———— En-tête

  String get otherName {
    final c = _conversation;
    if (c != null) return c.name;
    return asSitter ? '${_owner.ownerFirstName} B.' : '${_sitter.firstName} ${_sitter.lastInitial}';
  }

  String get otherPhoto => _conversation?.photo ?? (asSitter ? _owner.ownerPhoto : _sitter.photo);

  String get contextLabel => _conversation?.context ?? '';

  /// Le journal de garde n'est proposé que pendant une garde en cours.
  bool get hasJournal => _conversation?.live ?? false;

  /// Un message est « à moi » selon le point de vue courant (déjà résolu par le dépôt).
  bool isMine(ChatMessage m) => m.mine;

  /// Libellé du jour à afficher avant le message [i] (premier message du jour), sinon nul.
  String? dayLabelBefore(int i) {
    final current = _messages[i].sentAt;
    if (current == null) return null;
    if (i == 0) return chatDayLabel(current);
    final previous = _messages[i - 1].sentAt;
    return previous == null || !sameDay(previous, current) ? chatDayLabel(current) : null;
  }

  /// Dernier message envoyé par moi et lu par l'autre (pour afficher « Lu »).
  String? get lastReadMineId => _messages
      .lastWhere((m) => m.mine && m.read && !m.deleted && m.id != null,
          orElse: () => const ChatMessage(false, MsgKind.text, '', ''))
      .id;

  // ———— Chargement

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      if (_conversation == null) {
        final list = await _repo.conversations(asSitter: asSitter);
        if (list.isEmpty) {
          _noConversation = true;
          return;
        }
        _conversation = list.first;
      }
      final items = await _repo.messages(_conversation!.id);
      _messages
        ..clear()
        ..addAll(items);
      await _markRead();
    } on MessagingException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notify();
    }
  }

  /// Relit la dernière page de messages : nouveaux messages, mais aussi suppressions
  /// et accusés de lecture des messages déjà affichés.
  Future<void> refresh() async {
    final c = _conversation;
    if (c == null || _loading || _refreshing) return;
    _refreshing = true;
    try {
      final fresh = await _repo.messages(c.id);
      final byId = {for (final m in fresh) m.id: m};
      var changed = false;
      for (var i = 0; i < _messages.length; i++) {
        final updated = byId[_messages[i].id];
        final current = _messages[i];
        if (updated != null &&
            (updated.deleted != current.deleted || updated.read != current.read || updated.text != current.text)) {
          _messages[i] = updated;
          changed = true;
        }
      }
      final known = _messages.map((m) => m.id).toSet();
      final added = fresh.where((m) => !known.contains(m.id)).toList();
      if (added.isNotEmpty) {
        // Avant les messages encore en cours d'envoi, pour garder l'ordre chronologique.
        final pending = _messages.indexWhere((m) => m.id?.startsWith('tmp-') ?? false);
        _messages.insertAll(pending < 0 ? _messages.length : pending, added);
        changed = true;
        if (added.any((m) => !m.mine && !m.deleted)) await _markRead();
      }
      if (changed) notify();
    } on MessagingException {
      // Rafraîchissement silencieux : on réessaiera au prochain passage.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _markRead() async {
    final c = _conversation;
    if (c == null || !_messages.any((m) => !m.mine && !m.read)) return;
    try {
      await _repo.markRead(c.id);
    } on MessagingException {
      // Sans gravité : la pastille restera jusqu'au prochain passage.
    }
  }

  // ———— Envoi

  /// Affiche le message tout de suite (« envoi… »), puis le remplace par la version du serveur.
  Future<void> send(String text) async {
    final t = text.trim();
    final c = _conversation;
    if (t.isEmpty || c == null) return;
    final now = DateTime.now();
    final pending = ChatMessage(true, MsgKind.text, t, clockTime(now),
        id: 'tmp-${_tempIds++}', sentAt: now, status: MsgStatus.sending);
    _messages.add(pending);
    _error = null;
    _suggestions = const [];
    notify();
    await _deliver(pending);
  }

  /// Renvoie un message dont l'envoi a échoué.
  Future<void> retry(ChatMessage failed) async {
    final index = _messages.indexWhere((m) => m.id == failed.id);
    if (index < 0) return;
    final pending = failed.copyWith(status: MsgStatus.sending);
    _messages[index] = pending;
    notify();
    await _deliver(pending);
  }

  Future<void> _deliver(ChatMessage pending, {bool confirmRisk = false}) async {
    try {
      final saved = await _repo.send(_conversation!.id, pending.text, confirmRisk: confirmRisk);
      final index = _messages.indexWhere((m) => m.id == pending.id);
      // Le rafraîchissement a pu ramener le message entre-temps : pas de doublon.
      if (_messages.any((m) => m.id == saved.id)) {
        if (index >= 0) _messages.removeAt(index);
      } else if (index >= 0) {
        _messages[index] = saved;
      }
    } on RiskyMessageException catch (e) {
      // Rien n'a été envoyé : la bulle disparaît et l'expéditeur décide (modifier ou confirmer).
      _messages.removeWhere((m) => m.id == pending.id);
      _riskWarning = (text: pending.text, reason: e.message);
    } on MessagingException catch (e) {
      final index = _messages.indexWhere((m) => m.id == pending.id);
      if (index >= 0) _messages[index] = pending.copyWith(status: MsgStatus.failed);
      _error = e.message;
    }
    notify();
  }

  /// L'expéditeur confirme l'envoi du message signalé : il part, marqué comme à risque pour le destinataire.
  Future<void> confirmRiskySend() async {
    final warning = _riskWarning;
    if (warning == null) return;
    _riskWarning = null;
    final now = DateTime.now();
    final pending = ChatMessage(true, MsgKind.text, warning.text, clockTime(now),
        id: 'tmp-${_tempIds++}', sentAt: now, status: MsgStatus.sending);
    _messages.add(pending);
    notify();
    await _deliver(pending, confirmRisk: true);
  }

  /// L'expéditeur renonce : renvoie le texte pour qu'il le modifie.
  String cancelRiskySend() {
    final text = _riskWarning?.text ?? '';
    _riskWarning = null;
    notify();
    return text;
  }

  /// Demande 3 réponses à l'assistant IA.
  Future<void> loadSuggestions() async {
    final c = _conversation;
    if (c == null || _suggestionsLoading) return;
    _suggestionsLoading = true;
    notify();
    try {
      final result = await _repo.suggestReplies(c.id);
      _suggestions = result.replies;
      _suggestionsFromAi = result.fromAi;
    } on MessagingException catch (e) {
      _error = e.message;
    } finally {
      _suggestionsLoading = false;
      notify();
    }
  }

  void clearSuggestions() {
    if (_suggestions.isEmpty) return;
    _suggestions = const [];
    notify();
  }

  // ———— Suppression

  /// Seul l'expéditeur supprime ses messages (envoyés ou dont l'envoi a échoué).
  bool canDelete(ChatMessage m) =>
      m.mine && !m.deleted && m.kind != MsgKind.system && m.status != MsgStatus.sending;

  /// Supprime le message pour tout le monde (affiché tout de suite, annulé en cas d'erreur).
  /// Un message dont l'envoi a échoué n'existe que sur l'appareil : il est simplement retiré.
  Future<void> deleteMessage(ChatMessage m) async {
    final c = _conversation;
    final index = _messages.indexWhere((x) => x.id == m.id);
    if (c == null || index < 0 || !canDelete(m)) return;
    if (m.status == MsgStatus.failed || (m.id?.startsWith('tmp-') ?? true)) {
      _messages.removeAt(index);
      notify();
      return;
    }
    _messages[index] = m.copyWith(deleted: true);
    _error = null;
    notify();
    try {
      final saved = await _repo.deleteMessage(c.id, m.id!);
      final i = _messages.indexWhere((x) => x.id == m.id);
      if (i >= 0) _messages[i] = saved;
    } on MessagingException catch (e) {
      final i = _messages.indexWhere((x) => x.id == m.id);
      if (i >= 0) _messages[i] = m;
      _error = e.message;
    }
    notify();
  }

  void dismissError() {
    _error = null;
    notify();
  }

  // ———— Journal de garde (démonstration)

  Map<String, List<LogEntry>> get journal => _journal;
  List<LogEntry> get today => _journal.values.first;

  int doneCount(LogKind k) => today.where((e) => e.kind == k && e.done).length;
  int totalCount(LogKind k) => today.where((e) => e.kind == k).length;
  int get photoCount => today.where((e) => e.photo != null).length + 3;

  /// Types d'entrées proposés selon les animaux gardés : pas de promenade sans chien.
  List<LogKind> get availableKinds => [
    LogKind.repas,
    LogKind.nouvelles,
    LogKind.soins,
    LogKind.nettoyage,
    if (caredPets.any((p) => p.species == Species.chien)) LogKind.promenade,
  ];

  void addEntry(LogKind kind) {
    today.insert(
      0,
      LogEntry(
        kind,
        'Maint.',
        kind.label,
        kind == LogKind.repas ? 'Simba : 40 g · Kiwi : graines' : 'Ajouté depuis l\'espace sitter',
      ),
    );
    notify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Nouveau message : recherche d'un membre puis ouverture de la conversation.
class NewMessageViewModel extends ViewModel {
  NewMessageViewModel(this._repo, {Duration debounce = const Duration(milliseconds: 300)}) : _debounce = debounce {
    search('');
  }

  final MessageRepository _repo;
  final Duration _debounce;
  Timer? _timer;
  int _requestId = 0;

  List<Member> _results = const [];
  List<Member> get results => _results;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _opening; // membre en cours d'ouverture
  bool isOpening(Member m) => _opening == m.id;

  void onQueryChanged(String q) {
    _timer?.cancel();
    _timer = Timer(_debounce, () => search(q));
  }

  Future<void> search(String q) async {
    final id = ++_requestId;
    _loading = true;
    _error = null;
    notify();
    try {
      final found = await _repo.searchMembers(q);
      if (id != _requestId) return; // une recherche plus récente a été lancée
      _results = found;
    } on MessagingException catch (e) {
      if (id == _requestId) _error = e.message;
    } finally {
      if (id == _requestId) {
        _loading = false;
        notify();
      }
    }
  }

  /// Ouvre la conversation avec [member] ; nul en cas d'erreur (message dans [error]).
  Future<Conversation?> open(Member member) async {
    _opening = member.id;
    _error = null;
    notify();
    try {
      return await _repo.openConversation(userId: member.id);
    } on MessagingException catch (e) {
      _error = e.message;
      return null;
    } finally {
      _opening = null;
      notify();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
