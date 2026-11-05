import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Liste des conversations.
class MessagesViewModel extends ViewModel {
  MessagesViewModel(this._messages, {this.asSitter = false});
  final MessageRepository _messages;
  final bool asSitter;

  List<Conversation> get conversations => _messages.conversations(asSitter: asSitter);
}

/// Conversation et journal de garde.
class ChatViewModel extends ViewModel {
  ChatViewModel({
    required MessageRepository messages,
    required PetRepository pets,
    required SitterSpaceRepository sitterSpace,
    this.asSitter = false,
  }) : _messages = messages.messages(),
       _journal = messages.journal(),
       _owner = pets,
       _sitter = sitterSpace.me,
       caredPets = pets.myPets().take(2).toList();

  final List<ChatMessage> _messages;
  final Map<String, List<LogEntry>> _journal;
  final PetRepository _owner;
  final Sitter _sitter;

  /// Vrai quand c'est le sitter qui consulte (il peut alors écrire dans le journal).
  final bool asSitter;

  /// Animaux gardés (ici Simba et Kiwi).
  final List<Pet> caredPets;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Map<String, List<LogEntry>> get journal => _journal;
  List<LogEntry> get today => _journal.values.first;

  String get otherName => asSitter ? '${_owner.ownerFirstName} B.' : '${_sitter.firstName} ${_sitter.lastInitial}';
  String get otherPhoto => asSitter ? _owner.ownerPhoto : _sitter.photo;

  /// Un message est « à moi » selon le point de vue (propriétaire ou sitter).
  bool isMine(ChatMessage m) => asSitter ? !m.mine : m.mine;

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

  void send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _messages.add(ChatMessage(!asSitter, MsgKind.text, t, 'À l\'instant'));
    notify();
  }

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
}
