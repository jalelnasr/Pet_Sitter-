/// Messagerie et journal de garde.
///
/// - [MockMessageRepository] : conversations fictives en mémoire (sommaire, tests).
/// - [ApiMessageRepository] : backend Spring Boot (`/api/conversations`, `/api/users`).
///
/// Les messages renvoyés sont toujours vus par l'utilisateur courant : `mine` = envoyé par lui.
library;

import 'package:pet_sitter/adoption/api/api_client.dart';
import 'package:pet_sitter/core/utils/format.dart';
import 'package:pet_sitter/data/local/message_local_store.dart';
import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

/// Erreur lisible de la messagerie (réseau, droits, destinataire indisponible…).
class MessagingException implements Exception {
  const MessagingException(this.message, {this.code});
  final String message;
  final String? code;

  bool get isNetwork => code == 'NETWORK_ERROR' || code == 'TIMEOUT';

  @override
  String toString() => message;
}

/// Message jugé à risque par l'assistant IA (arnaque, insulte) : rien n'a été envoyé.
/// [message] explique pourquoi ; renvoyer avec `confirmRisk: true` pour confirmer.
class RiskyMessageException extends MessagingException {
  const RiskyMessageException(super.message) : super(code: 'RISKY_MESSAGE');
}

/// Réponses proposées par l'assistant ; [source] = llm (IA Groq), fallback ou local (règles).
class ReplySuggestions {
  const ReplySuggestions(this.replies, this.source);
  final List<String> replies;
  final String source;

  bool get fromAi => source == 'llm';
}

abstract class MessageRepository {
  /// Mes conversations, la plus récente d'abord. [asSitter] ne sert qu'aux données de démonstration.
  Future<List<Conversation>> conversations({bool asSitter = false});

  /// Ouvre (ou retrouve) la conversation avec un membre, avec un premier message facultatif.
  Future<Conversation> openConversation({required String userId, String? subject, String? firstMessage});

  /// Messages du plus ancien au plus récent ; [afterId] = seulement les nouveaux.
  Future<List<ChatMessage>> messages(String conversationId, {String? afterId});

  /// Envoie un message ; l'assistant IA l'analyse. Lève [RiskyMessageException] si le message
  /// est à risque élevé et que [confirmRisk] est faux.
  Future<ChatMessage> send(String conversationId, String text, {bool confirmRisk = false});

  /// Assistant IA : 3 réponses suggérées selon les derniers messages.
  Future<ReplySuggestions> suggestReplies(String conversationId);

  /// Supprime un de mes messages pour tout le monde ; renvoie la version « supprimée ».
  Future<ChatMessage> deleteMessage(String conversationId, String messageId);

  Future<void> markRead(String conversationId);

  Future<int> unreadCount();

  /// Annuaire : membres à qui écrire.
  Future<List<Member>> searchMembers(String query);

  /// Journal de garde (démonstration : il n'a pas encore de backend).
  Map<String, List<LogEntry>> journal();
}

// ————————————————————————————————————————————— Démonstration

class MockMessageRepository implements MessageRepository {
  MockMessageRepository({this.latency = const Duration(milliseconds: 250)}) {
    _seed();
  }

  final Duration latency;
  final Map<String, Conversation> _conversations = {};
  final Map<String, List<ChatMessage>> _messages = {};
  int _nextId = 1000;

  static final _members = [
    Member(id: 'amira', firstName: 'Amira', fullName: 'Amira K.', role: AppRole.petsitter, photoUrl: Mock.amira.photo, city: 'La Marsa'),
    Member(id: 'salma', firstName: 'Salma', fullName: 'Salma T.', role: AppRole.petsitter, photoUrl: Mock.salma.photo, city: 'Ariana'),
    Member(id: 'ines', firstName: 'Inès', fullName: 'Inès M.', role: AppRole.petsitter, photoUrl: Mock.ines.photo, city: 'Tunis'),
    Member(id: 'mehdi', firstName: 'Mehdi', fullName: 'Mehdi B.', role: AppRole.petsitter, photoUrl: Mock.mehdi.photo, city: 'Carthage'),
    Member(id: 'leila', firstName: 'Leïla', fullName: 'Leïla B.', role: AppRole.owner, photoUrl: Photos.leila, city: 'La Marsa'),
  ];

  Future<void> _wait() => Future.delayed(latency);

  /// Donne une date aux messages fictifs (les 3 premiers avant-hier, puis hier, puis aujourd'hui).
  static List<ChatMessage> _dated(List<ChatMessage> source, {required bool flip}) {
    final now = DateTime.now();
    return [
      for (final (i, m) in source.indexed)
        () {
          final day = now.subtract(Duration(days: i < 3 ? 2 : (i == 3 ? 1 : 0)));
          final parts = m.time.split(':');
          final at = parts.length == 2
              ? DateTime(day.year, day.month, day.day, int.tryParse(parts[0]) ?? 9, int.tryParse(parts[1]) ?? 0)
              : DateTime(day.year, day.month, day.day, i == 3 ? 18 : 8, i == 3 ? 5 : 0);
          return m.copyWith(mine: flip ? !m.mine : m.mine, id: 'm$i', sentAt: at, read: true);
        }(),
    ];
  }

  void _seed() {
    final ownerChat = _dated(Mock.chat, flip: false);
    final sitterChat = _dated(Mock.chat, flip: true);
    final today = DateTime.now();
    ChatMessage text(String id, bool mine, String t, DateTime at) =>
        ChatMessage(mine, MsgKind.text, t, clockTime(at), id: id, sentAt: at, read: true);

    void add(Conversation c, List<ChatMessage> msgs) {
      _conversations[c.id] = c;
      _messages[c.id] = msgs;
    }

    // Point de vue propriétaire
    add(
      Conversation(
        id: 'o-amira',
        otherUserId: 'amira',
        photo: Mock.amira.photo,
        name: 'Amira',
        lastMessage: 'Elle chante depuis 7 h 😄 Graines et pomme ok, eau changée.',
        time: '08:53',
        unread: 2,
        context: 'Garde en cours · Simba, Kiwi',
        live: true,
        lastMessageAt: today,
      ),
      [
        ...ownerChat,
        text('m7', false, 'Kiwi va très bien !', DateTime(today.year, today.month, today.day, 8, 52)),
        text('m8', false, 'Elle chante depuis 7 h 😄 Graines et pomme ok, eau changée.',
            DateTime(today.year, today.month, today.day, 8, 53)),
      ].map((m) => m.id == 'm7' || m.id == 'm8' ? m.copyWith(read: false) : m).toList(),
    );
    final yesterday = today.subtract(const Duration(days: 1));
    add(
      Conversation(
        id: 'o-salma',
        otherUserId: 'salma',
        photo: Mock.salma.photo,
        name: 'Salma',
        lastMessage: 'Je passerai vers 9 h pour nourrir Bulle et vérifier le filtre.',
        time: 'Hier',
        unread: 0,
        context: 'Confirmée · 23–26 oct.',
        live: false,
        lastMessageAt: yesterday,
      ),
      [
        text('s1', true, 'Bonjour Salma, pouvez-vous passer voir Bulle samedi ?', yesterday.subtract(const Duration(hours: 2))),
        text('s2', false, 'Je passerai vers 9 h pour nourrir Bulle et vérifier le filtre.', yesterday),
      ],
    );
    final monday = today.subtract(const Duration(days: 4));
    add(
      Conversation(
        id: 'o-ines',
        otherUserId: 'ines',
        photo: Mock.ines.photo,
        name: 'Inès',
        lastMessage: 'Bonjour ! Simba est-il habitué à rester seul la journée ?',
        time: chatListTime(monday),
        unread: 0,
        context: 'Demande en attente · 18–21 déc.',
        live: false,
        lastMessageAt: monday,
      ),
      [text('i1', false, 'Bonjour ! Simba est-il habitué à rester seul la journée ?', monday)],
    );

    // Point de vue pet sitter
    add(
      Conversation(
        id: 's-leila',
        otherUserId: 'leila',
        photo: Photos.leila,
        name: 'Leïla B.',
        lastMessage: 'Merci, ça me rassure beaucoup ! Et Kiwi ?',
        time: '08:50',
        unread: 0,
        context: 'Garde en cours · Simba, Kiwi',
        live: true,
        lastMessageAt: today,
      ),
      sitterChat,
    );
    add(
      Conversation(
        id: 's-sami',
        otherUserId: 'sami',
        photo: Photos.salma,
        name: 'Sami R.',
        lastMessage: 'Bonjour, accepteriez-vous un lapin âgé ?',
        time: 'Hier',
        unread: 1,
        context: 'Nouvelle demande · 1er–4 nov.',
        live: false,
        lastMessageAt: yesterday,
      ),
      [text('r1', false, 'Bonjour, accepteriez-vous un lapin âgé ?', yesterday).copyWith(read: false)],
    );
  }

  @override
  Future<List<Conversation>> conversations({bool asSitter = false}) async {
    await _wait();
    final prefix = asSitter ? 's-' : 'o-';
    final list = _conversations.values.where((c) => c.id.startsWith(prefix) || c.id.startsWith('n-')).toList()
      ..sort((a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(a.lastMessageAt ?? DateTime(0)));
    return list;
  }

  @override
  Future<Conversation> openConversation({required String userId, String? subject, String? firstMessage}) async {
    await _wait();
    final existing = _conversations.values.where((c) => c.otherUserId == userId).firstOrNull;
    final member = _members.where((m) => m.id == userId).firstOrNull;
    var conversation = existing ??
        Conversation(
          id: 'n-$userId',
          otherUserId: userId,
          photo: member?.photoUrl ?? '',
          name: member?.firstName ?? 'Membre',
          lastMessage: '',
          time: '',
          unread: 0,
          context: subject ?? '',
          live: false,
        );
    _conversations[conversation.id] = conversation;
    _messages.putIfAbsent(conversation.id, () => []);
    if (firstMessage != null && firstMessage.trim().isNotEmpty) {
      await send(conversation.id, firstMessage);
      conversation = _conversations[conversation.id]!;
    }
    return conversation;
  }

  @override
  Future<List<ChatMessage>> messages(String conversationId, {String? afterId}) async {
    await _wait();
    final all = _messages[conversationId];
    if (all == null) throw const MessagingException('Conversation introuvable.', code: 'NOT_FOUND');
    if (afterId == null) return List.of(all);
    final index = all.indexWhere((m) => m.id == afterId);
    return index < 0 ? const [] : all.sublist(index + 1);
  }

  /// Règles de démonstration (le vrai contrôle est fait par le backend et le service messaging_ai).
  static final _demoScam = RegExp(
    r"western\s*union|code (de (la|ta|votre) )?carte|payer? d'avance|envoie[sz]?(-moi| moi)? l'argent|\bcvv\b",
    caseSensitive: false,
  );
  /// Échantillon multilingue (la vraie liste, plus de 250 termes en 6 langues, est côté serveur).
  static final _demoInsult = RegExp(
    r'\b(connard|salop|idiot|cr[eé]tin|d[eé]bile|fuck|bitch|kahba|9a7ba|zebi|nayek|ta77an|vaffanculo)|قحب|زبي',
    caseSensitive: false,
  );

  static (MsgRisk, String?) demoAnalysis(String text) {
    if (_demoScam.hasMatch(text)) {
      return (
        MsgRisk.high,
        'Demande de paiement hors de l\'application ou de coordonnées bancaires : ne payez jamais à l\'avance '
            'par transfert d\'argent et ne partagez jamais le code de votre carte.',
      );
    }
    if (_demoInsult.hasMatch(text)) {
      return (
        MsgRisk.high,
        'Gros mot ou insulte détecté. Restez courtois : les messages irrespectueux peuvent être signalés.',
      );
    }
    return (MsgRisk.none, null);
  }

  /// Remplace les gros mots par des étoiles, première et dernière lettres gardées (« zebi » → « z**i »).
  static String demoCensor(String text) => text.replaceAllMapped(_demoInsult, (m) {
    final w = m[0]!;
    return w.length <= 2 ? '${w[0]}*' : '${w[0]}${'*' * (w.length - 2)}${w[w.length - 1]}';
  });

  @override
  Future<ChatMessage> send(String conversationId, String text, {bool confirmRisk = false}) async {
    await _wait();
    final original = text.trim();
    if (original.isEmpty) throw const MessagingException('Le message est vide.', code: 'EMPTY_MESSAGE');
    final list = _messages[conversationId];
    if (list == null) throw const MessagingException('Conversation introuvable.', code: 'NOT_FOUND');
    // Analyse sur le texte d'origine ; c'est la version censurée qui est enregistrée et affichée.
    final (risk, reason) = demoAnalysis(original);
    final content = demoCensor(original);
    if (risk == MsgRisk.high && !confirmRisk) throw RiskyMessageException(reason!);
    final now = DateTime.now();
    final message = ChatMessage(
      true,
      MsgKind.text,
      content,
      clockTime(now),
      id: 'm${_nextId++}',
      sentAt: now,
      risk: risk,
      riskReason: reason,
    );
    list.add(message);
    _conversations[conversationId] = _conversations[conversationId]!.copyWith(
      lastMessage: content,
      time: clockTime(now),
      lastMessageAt: now,
      lastMessageMine: true,
    );
    return message;
  }

  @override
  Future<ReplySuggestions> suggestReplies(String conversationId) async {
    await _wait();
    final last = (_messages[conversationId] ?? const <ChatMessage>[])
        .lastWhere((m) => !m.mine && m.kind == MsgKind.text, orElse: () => const ChatMessage(false, MsgKind.text, '', ''))
        .text
        .toLowerCase();
    if (last.contains('merci')) return const ReplySuggestions(['Avec plaisir !', 'Je vous en prie, à bientôt !', 'N\'hésitez pas si besoin.'], 'local');
    if (last.contains('?')) return const ReplySuggestions(['Oui, bien sûr.', 'Je vérifie et je vous réponds.', 'Pouvez-vous préciser ?'], 'local');
    return const ReplySuggestions(['Merci pour les nouvelles !', 'Super, ça me rassure !', 'Pouvez-vous m\'envoyer une photo ?'], 'local');
  }

  @override
  Future<ChatMessage> deleteMessage(String conversationId, String messageId) async {
    await _wait();
    final list = _messages[conversationId];
    final index = list?.indexWhere((m) => m.id == messageId) ?? -1;
    if (list == null || index < 0) throw const MessagingException('Message introuvable.', code: 'NOT_FOUND');
    if (!list[index].mine) {
      throw const MessagingException('Vous ne pouvez supprimer que vos propres messages.', code: 'FORBIDDEN');
    }
    final deleted = list[index].copyWith(deleted: true);
    list[index] = deleted;
    if (index == list.length - 1) {
      _conversations[conversationId] = _conversations[conversationId]!.copyWith(lastMessage: 'Message supprimé');
    }
    return deleted;
  }

  @override
  Future<void> markRead(String conversationId) async {
    final c = _conversations[conversationId];
    if (c != null) _conversations[conversationId] = c.copyWith(unread: 0);
    final list = _messages[conversationId];
    if (list != null) {
      for (var i = 0; i < list.length; i++) {
        if (!list[i].mine) list[i] = list[i].copyWith(read: true);
      }
    }
  }

  @override
  Future<int> unreadCount() async =>
      _conversations.values.where((c) => c.id.startsWith('o-')).fold<int>(0, (sum, c) => sum + c.unread);

  @override
  Future<List<Member>> searchMembers(String query) async {
    await _wait();
    final q = query.trim().toLowerCase();
    return _members.where((m) => q.isEmpty || m.fullName.toLowerCase().contains(q)).toList();
  }

  @override
  Map<String, List<LogEntry>> journal() => {
    for (final e in Mock.journal.entries) e.key: [...e.value],
  };
}

// ————————————————————————————————————————————— Backend

class ApiMessageRepository implements MessageRepository {
  ApiMessageRepository({ApiClient? client}) : _api = client ?? ApiClient();

  final ApiClient _api;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      if (e.code == 'RISKY_MESSAGE') throw RiskyMessageException(e.message);
      throw MessagingException(e.message, code: e.code);
    }
  }

  static DateTime? _date(dynamic value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;

  static Conversation _conversation(Map<String, dynamic> json) {
    final other = (json['otherUser'] as Map<String, dynamic>?) ?? const {};
    final at = _date(json['lastMessageAt']);
    final lastMessage = (json['lastMessage'] as String?) ?? '';
    final mine = json['lastMessageMine'] == true;
    return Conversation(
      id: '${json['id']}',
      otherUserId: other['id'] as String?,
      photo: (other['photoUrl'] as String?) ?? '',
      name: (other['fullName'] as String?) ?? (other['firstName'] as String?) ?? 'Membre',
      lastMessage: lastMessage.isEmpty ? 'Nouvelle conversation' : (mine ? 'Vous : $lastMessage' : lastMessage),
      time: at == null ? '' : chatListTime(at),
      unread: (json['unreadCount'] as num?)?.toInt() ?? 0,
      context: (json['subject'] as String?) ?? '',
      live: false,
      lastMessageAt: at ?? _date(json['createdAt']),
      lastMessageMine: mine,
    );
  }

  static ChatMessage _message(Map<String, dynamic> json) {
    final sentAt = _date(json['sentAt']) ?? DateTime.now();
    final system = json['type'] == 'SYSTEM';
    return ChatMessage(
      json['mine'] == true,
      system ? MsgKind.system : MsgKind.text,
      (json['content'] as String?) ?? '',
      system ? '' : clockTime(sentAt),
      id: '${json['id']}',
      sentAt: sentAt,
      read: json['readAt'] != null,
      risk: switch (json['risk']) {
        'HIGH' => MsgRisk.high,
        'LOW' => MsgRisk.low,
        _ => MsgRisk.none,
      },
      riskReason: json['riskReason'] as String?,
      deleted: json['deleted'] == true,
    );
  }

  @override
  Future<List<Conversation>> conversations({bool asSitter = false}) => _call(() async {
    final List<dynamic> json;
    try {
      json = await _api.get('/conversations') as List<dynamic>;
    } on ApiException catch (e) {
      // Pas de réseau : conversations enregistrées dans SQLite.
      if (e.statusCode != 0) rethrow;
      final saved = await _local.readConversations();
      if (saved.isEmpty) rethrow;
      return saved.map(_conversation).toList();
    }
    await _local.saveConversations(json.whereType<Map<String, dynamic>>().toList());
    return json.map((e) => _conversation(e as Map<String, dynamic>)).toList();
  });

  final _local = const MessageLocalStore();

  @override
  Future<Conversation> openConversation({required String userId, String? subject, String? firstMessage}) =>
      _call(() async {
        final json = await _api.post('/conversations', {
          'participantId': userId,
          if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
          if (firstMessage != null && firstMessage.trim().isNotEmpty) 'message': firstMessage.trim(),
        });
        return _conversation(json as Map<String, dynamic>);
      });

  @override
  Future<List<ChatMessage>> messages(String conversationId, {String? afterId}) => _call(() async {
    final List<dynamic> json;
    try {
      json = await _api.get(
        '/conversations/$conversationId/messages',
        query: {'afterId': afterId, 'limit': '100'},
      ) as List<dynamic>;
    } on ApiException catch (e) {
      // Pas de réseau : messages enregistrés dans SQLite (premier chargement seulement).
      if (e.statusCode != 0 || afterId != null) rethrow;
      final saved = await _local.readMessages(conversationId);
      if (saved.isEmpty) rethrow;
      return saved.map(_message).toList();
    }
    await _local.saveMessages(conversationId, json.whereType<Map<String, dynamic>>().toList());
    return json.map((e) => _message(e as Map<String, dynamic>)).toList();
  });

  @override
  Future<ChatMessage> send(String conversationId, String text, {bool confirmRisk = false}) => _call(() async {
    final json = await _api.post('/conversations/$conversationId/messages', {
      'content': text.trim(),
      if (confirmRisk) 'confirmRisk': true,
    });
    return _message(json as Map<String, dynamic>);
  });

  @override
  Future<ChatMessage> deleteMessage(String conversationId, String messageId) => _call(() async {
    final json = await _api.delete('/conversations/$conversationId/messages/$messageId');
    return _message(json as Map<String, dynamic>);
  });

  @override
  Future<ReplySuggestions> suggestReplies(String conversationId) => _call(() async {
    final json = await _api.get('/conversations/$conversationId/ai/replies') as Map<String, dynamic>;
    final replies = ((json['replies'] as List<dynamic>?) ?? const []).map((e) => '$e').toList();
    return ReplySuggestions(replies, (json['source'] as String?) ?? 'local');
  });

  @override
  Future<void> markRead(String conversationId) => _call(() => _api.post('/conversations/$conversationId/read'));

  @override
  Future<int> unreadCount() => _call(() async {
    final json = await _api.get('/conversations/unread-count') as Map<String, dynamic>;
    return (json['count'] as num?)?.toInt() ?? 0;
  });

  @override
  Future<List<Member>> searchMembers(String query) => _call(() async {
    final json = await _api.get('/users', query: {'q': query.trim().isEmpty ? null : query.trim(), 'size': '30'})
        as Map<String, dynamic>;
    final content = (json['content'] as List<dynamic>?) ?? const [];
    return content.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  });

  /// Le journal de garde n'a pas encore de backend : contenu de démonstration.
  @override
  Map<String, List<LogEntry>> journal() => {
    for (final e in Mock.journal.entries) e.key: [...e.value],
  };
}
