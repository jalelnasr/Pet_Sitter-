// Tests du module Utilisateur et de la messagerie : ViewModels et dépôts de démonstration,
// sans écran ni serveur. Lancer : flutter test
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/core/utils/format.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/view_models/home_view_model.dart';
import 'package:pet_sitter/view_models/sitter_space_view_model.dart';
import 'package:pet_sitter/data/repositories/message_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/account_view_model.dart';
import 'package:pet_sitter/view_models/auth_view_model.dart';
import 'package:pet_sitter/view_models/messages_view_model.dart';
import 'package:pet_sitter/view_models/profile_view_model.dart';

/// Laisse s'exécuter les appels asynchrones des dépôts (délais nuls).
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  late AuthSession session;
  late MockAuthRepository auth;

  setUp(() {
    session = AuthSession.isolated();
    auth = MockAuthRepository(session: session, latency: Duration.zero);
  });

  group('Session', () {
    test('une session enregistrée est restaurée, une session expirée est ignorée', () async {
      final store = MemorySessionStore();
      const user = AppUser(id: 'u1', firstName: 'Leïla', email: 'l@exemple.tn', role: AppRole.owner);
      await store.write(StoredSession(token: 't', expiresAt: DateTime.now().add(const Duration(hours: 1)), user: user));
      final restored = AuthSession.isolated()..useStore(store);
      expect(await restored.restore(), isTrue);
      expect(restored.authHeaders['Authorization'], 'Bearer t');

      await store.write(StoredSession(token: 't', expiresAt: DateTime.now().subtract(const Duration(minutes: 1)), user: user));
      final expired = AuthSession.isolated()..useStore(store);
      expect(await expired.restore(), isFalse);
      expect(await store.read(), isNull);
    });

    test('un jeton refusé ferme la session et le signale', () async {
      await auth.logIn(email: 'leila@exemple.tn', password: 'motdepasse1');
      expect(session.isAuthenticated, isTrue);
      await session.expire();
      expect(session.isAuthenticated, isFalse);
      expect(session.wasExpired, isTrue);
    });
  });

  group('Inscription et connexion', () {
    test('l\'inscription découpe le nom et ouvre la session', () async {
      final vm = AuthViewModel(auth)..setTerms(true);
      final ok = await vm.submit(fieldsValid: true, name: 'Leïla Ben Salah', email: 'leila@exemple.tn', password: 'chat2026');
      expect(ok, isTrue);
      expect(session.user?.firstName, 'Leïla');
      expect(session.user?.lastName, 'Ben Salah');
    });

    test('une adresse déjà utilisée affiche le message du serveur', () async {
      final vm = AuthViewModel(auth)..setTerms(true);
      final ok = await vm.submit(fieldsValid: true, name: 'Leïla B', email: 'deja@petsitter.tn', password: 'chat2026');
      expect(ok, isFalse);
      expect(vm.banner, contains('existe déjà'));
      expect(session.isAuthenticated, isFalse);
    });

    test('règles du mot de passe : 8 caractères et un chiffre', () {
      expect(AuthViewModel.validateNewPassword('court1'), isNotNull);
      expect(AuthViewModel.validateNewPassword('sanschiffre'), isNotNull);
      expect(AuthViewModel.validateNewPassword('avecchiffre1'), isNull);
    });

    test('le choix « pet sitter » est enregistré sur le compte', () async {
      await auth.logIn(email: 'leila@exemple.tn', password: 'motdepasse1');
      final vm = RoleChoiceViewModel(auth, session.user?.firstName)..choose(1);
      expect(await vm.confirm(), isTrue);
      expect(session.user?.role, AppRole.petsitter);
    });
  });

  group('Mot de passe oublié', () {
    test('adresse → code → nouveau mot de passe, avec compte à rebours de renvoi', () async {
      final vm = ForgotPasswordViewModel(auth);
      expect(vm.step, ResetStep.email);
      expect(await vm.send('leila@exemple.tn'), isTrue);
      expect(vm.step, ResetStep.code);
      expect(vm.resendIn, 60);
      expect(vm.canResend, isFalse);

      expect(await vm.reset(code: '000000', newPassword: 'nouveau2026'), isFalse);
      expect(vm.error, contains('incorrect'));
      expect(vm.step, ResetStep.code);

      expect(await vm.reset(code: MockAuthRepository.demoResetCode, newPassword: 'nouveau2026'), isTrue);
      expect(vm.step, ResetStep.done);
      expect(session.isAuthenticated, isTrue);
      vm.dispose();
    });

    test('le code doit contenir 6 chiffres', () {
      expect(ForgotPasswordViewModel.validateCode('12345'), isNotNull);
      expect(ForgotPasswordViewModel.validateCode('12a456'), isNotNull);
      expect(ForgotPasswordViewModel.validateCode('123456'), isNull);
    });
  });

  group('Profil', () {
    test('modifier le profil met à jour la session et l\'onglet Profil', () async {
      await auth.signUp(firstName: 'Leïla', lastName: 'B', email: 'leila@exemple.tn', password: 'chat2026');
      final account = AccountViewModel(MockPetRepository(), MockSitterRepository(), auth: auth, session: session);
      final vm = EditProfileViewModel(auth, session);
      expect(await vm.save(firstName: 'Inès', lastName: 'Ben Ali', phone: '', city: 'La Marsa', bio: ''), isTrue);
      expect(account.fullName, 'Inès Ben Ali');
      expect(account.subtitle, startsWith('La Marsa'));

      await account.logOut();
      expect(session.isAuthenticated, isFalse);
      account.dispose();
    });

    test('changer de mot de passe exige le mot de passe actuel', () async {
      await auth.signUp(firstName: 'Leïla', email: 'leila@exemple.tn', password: 'chat2026');
      final vm = ChangePasswordViewModel(auth);
      expect(await vm.submit(current: 'faux12345', next: 'nouveau2026'), isFalse);
      expect(vm.error, contains('incorrect'));
      expect(await vm.submit(current: 'chat2026', next: 'nouveau2026'), isTrue);
    });
  });

  group('Identité affichée', () {
    test('l\'espace pet sitter affiche le compte connecté, pas le sitter fictif', () async {
      final demo = SitterDashboardViewModel(MockSitterSpaceRepository(), session: session);
      expect(demo.firstName, 'Amira'); // aperçu sans compte
      expect(demo.isSignedIn, isFalse);

      await auth.signUp(firstName: 'Rayen', lastName: 'Borgi', email: 'rayen@exemple.tn', password: 'rayen2026');
      await auth.changeRole(AppRole.petsitter);
      final vm = SitterDashboardViewModel(MockSitterSpaceRepository(), session: session);
      expect(vm.firstName, 'Rayen');
      expect(vm.fullName, 'Rayen Borgi');
      expect(vm.photo, isEmpty); // pas de photo : initiales, jamais celle d'Amira
    });

    test('l\'accueil propriétaire salue le compte connecté', () async {
      await auth.signUp(firstName: 'Rayen', lastName: 'Borgi', email: 'rayen@exemple.tn', password: 'rayen2026');
      final vm = HomeViewModel(
        sitters: MockSitterRepository(),
        pets: MockPetRepository(),
        shop: MockShopRepository(),
        cart: CartRepository(),
        session: session,
      );
      expect(vm.ownerFirstName, 'Rayen');
      expect(vm.ownerPhoto, isEmpty);
    });

    test('passer en mode propriétaire est enregistré sur le compte', () async {
      await auth.signUp(firstName: 'Rayen', email: 'rayen@exemple.tn', password: 'rayen2026');
      await auth.changeRole(AppRole.petsitter);
      final account = AccountViewModel(MockPetRepository(), MockSitterRepository(), auth: auth, session: session);
      expect(account.isPetsitter, isTrue);
      expect(await account.switchRole(AppRole.owner), isTrue);
      expect(session.user?.role, AppRole.owner);
      account.dispose();
    });
  });

  group('Messagerie', () {
    MockMessageRepository repo() => MockMessageRepository(latency: Duration.zero);

    test('la liste charge les conversations du point de vue choisi', () async {
      final owner = MessagesViewModel(repo(), refreshEvery: null);
      await settle();
      expect(owner.loading, isFalse);
      expect(owner.conversations.map((c) => c.name), ['Amira', 'Salma', 'Inès']);
      expect(owner.unreadTotal, 2);

      final sitter = MessagesViewModel(repo(), asSitter: true, refreshEvery: null);
      await settle();
      expect(sitter.conversations.first.name, 'Leïla B.');
      owner.dispose();
      sitter.dispose();
    });

    test('ouvrir une conversation marque ses messages comme lus', () async {
      final messages = repo();
      final first = (await messages.conversations()).first;
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        conversation: first,
        pollEvery: null,
      );
      await settle();
      expect(chat.messages, isNotEmpty);
      expect(chat.hasJournal, isTrue); // garde en cours
      expect((await messages.conversations()).first.unread, 0);
      chat.dispose();
    });

    test('envoyer un message : affiché tout de suite, puis confirmé par le serveur', () async {
      final messages = repo();
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        pollEvery: null,
      );
      await settle();
      final before = chat.messages.length;
      final sending = chat.send('  Bonne nuit Simba !  ');
      expect(chat.messages.last.status, MsgStatus.sending);
      await sending;
      expect(chat.messages.length, before + 1);
      expect(chat.messages.last.status, MsgStatus.sent);
      expect(chat.messages.last.text, 'Bonne nuit Simba !');
      expect(chat.messages.last.id, isNot(startsWith('tmp-')));

      await chat.send('   ');
      expect(chat.messages.length, before + 1); // message vide ignoré
      chat.dispose();
    });

    test('les messages reçus pendant que la conversation est ouverte sont ajoutés sans doublon', () async {
      final messages = repo();
      final conversation = await messages.openConversation(userId: 'mehdi');
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        conversation: conversation,
        pollEvery: null,
      );
      await settle();
      expect(chat.messages, isEmpty);
      expect(chat.hasJournal, isFalse);
      await messages.send(conversation.id, 'Bonjour Mehdi');
      await chat.refresh();
      await chat.refresh();
      expect(chat.messages.length, 1);
      chat.dispose();
    });

    test('nouveau message : recherche d\'un membre puis ouverture de la conversation', () async {
      final vm = NewMessageViewModel(repo(), debounce: Duration.zero);
      await settle();
      expect(vm.results, isNotEmpty);
      await vm.search('sal');
      expect(vm.results.single.firstName, 'Salma');
      final conversation = await vm.open(vm.results.single);
      expect(conversation?.name, 'Salma'); // conversation existante retrouvée
      vm.dispose();
    });

    test('assistant IA : message d\'arnaque retenu, modifiable ou confirmé', () async {
      final messages = repo();
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        pollEvery: null,
      );
      await settle();
      final before = chat.messages.length;

      await chat.send('Envoie l\'argent par Western Union avant samedi');
      expect(chat.messages.length, before); // rien n'est parti
      expect(chat.riskWarning?.reason, contains('paiement'));

      // Modifier : le texte revient pour être corrigé.
      expect(chat.cancelRiskySend(), contains('Western Union'));
      expect(chat.riskWarning, isNull);

      // Confirmer : envoyé, marqué comme à risque.
      await chat.send('Envoie l\'argent par Western Union avant samedi');
      await chat.confirmRiskySend();
      expect(chat.messages.length, before + 1);
      expect(chat.messages.last.risk, MsgRisk.high);
      expect(chat.messages.last.status, MsgStatus.sent);
      chat.dispose();
    });

    test('gros mot confirmé : enregistré avec des étoiles', () async {
      final chat = ChatViewModel(
        messages: repo(),
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        pollEvery: null,
      );
      await settle();
      await chat.send('Si zebi');
      expect(chat.riskWarning, isNotNull);
      await chat.confirmRiskySend();
      expect(chat.messages.last.text, 'Si z**i');
      expect(chat.messages.last.risk, MsgRisk.high);
      chat.dispose();
    });

    test('suppression : mon message devient « supprimé », pas celui de l\'autre', () async {
      final messages = repo();
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        pollEvery: null,
      );
      await settle();
      await chat.send('Message à supprimer');
      final mine = chat.messages.last;
      final theirs = chat.messages.firstWhere((m) => !m.mine && m.kind == MsgKind.text);
      expect(chat.canDelete(mine), isTrue);
      expect(chat.canDelete(theirs), isFalse);

      await chat.deleteMessage(mine);
      expect(chat.messages.last.deleted, isTrue);
      expect(chat.canDelete(chat.messages.last), isFalse);
      expect((await messages.conversations()).first.lastMessage, 'Message supprimé');

      await chat.deleteMessage(theirs); // refusé : rien ne change
      expect(chat.messages.firstWhere((m) => m.id == theirs.id).deleted, isFalse);
      chat.dispose();
    });

    test('suppression faite sur un autre appareil : visible au rafraîchissement', () async {
      final messages = repo();
      final first = (await messages.conversations()).first;
      final chat = ChatViewModel(
        messages: messages,
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        conversation: first,
        pollEvery: null,
      );
      await settle();
      final sent = await messages.send(first.id, 'Envoyé depuis le téléphone');
      await chat.refresh();
      expect(chat.messages.last.text, 'Envoyé depuis le téléphone');
      await messages.deleteMessage(first.id, sent.id!);
      await chat.refresh();
      expect(chat.messages.last.deleted, isTrue);
      chat.dispose();
    });

    test('assistant IA : 3 suggestions, effacées à l\'envoi', () async {
      final chat = ChatViewModel(
        messages: repo(),
        pets: MockPetRepository(),
        sitterSpace: MockSitterSpaceRepository(),
        pollEvery: null,
      );
      await settle();
      await chat.loadSuggestions();
      expect(chat.suggestions, hasLength(3));
      await chat.send(chat.suggestions.first);
      expect(chat.suggestions, isEmpty);
      chat.dispose();
    });

    test('séparateurs de jour et heures de la liste', () {
      final now = DateTime(2026, 11, 8, 15);
      expect(chatDayLabel(DateTime(2026, 11, 8, 9), now: now), 'Aujourd\'hui');
      expect(chatDayLabel(DateTime(2026, 11, 7, 9), now: now), 'Hier');
      expect(chatDayLabel(DateTime(2026, 10, 22, 9), now: now), 'Jeudi 22 octobre');
      expect(chatListTime(DateTime(2026, 11, 8, 8, 5), now: now), '08:05');
      expect(chatListTime(DateTime(2026, 11, 7, 8), now: now), 'Hier');
    });
  });
}
