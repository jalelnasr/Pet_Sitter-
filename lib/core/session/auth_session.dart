/// Session de l'utilisateur connecté, partagée par toute l'application.
///
/// - Les dépôts l'ouvrent après une connexion réussie ([open]) et la ferment à la déconnexion ([close]).
/// - Les clients HTTP y lisent le jeton ([authHeaders]) ; un 401 du serveur la ferme ([expire]).
/// - Les ViewModels l'écoutent (c'est un [ChangeNotifier]) pour afficher le nom, le rôle…
///
/// La persistance passe par un [SessionStore] : mémoire dans les tests, stockage local dans l'app.
library;

import 'package:flutter/foundation.dart';
import 'package:pet_sitter/models/user.dart';

/// Ce qui est conservé entre deux lancements.
class StoredSession {
  const StoredSession({required this.token, required this.expiresAt, required this.user});

  final String token;
  final DateTime? expiresAt;
  final AppUser user;
}

abstract class SessionStore {
  Future<StoredSession?> read();
  Future<void> write(StoredSession session);
  Future<void> clear();
}

/// Stockage en mémoire (tests, aperçus) : la session disparaît à la fermeture.
class MemorySessionStore implements SessionStore {
  StoredSession? _value;

  @override
  Future<StoredSession?> read() async => _value;

  @override
  Future<void> write(StoredSession session) async => _value = session;

  @override
  Future<void> clear() async => _value = null;
}

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  /// Session indépendante pour les tests.
  @visibleForTesting
  factory AuthSession.isolated() => AuthSession._();

  SessionStore _store = MemorySessionStore();
  String? _token;
  DateTime? _expiresAt;
  AppUser? _user;

  /// Vrai quand la dernière fermeture vient d'un jeton refusé par le serveur.
  bool _expired = false;

  String? get token => _token;
  AppUser? get user => _user;
  DateTime? get expiresAt => _expiresAt;
  bool get isAuthenticated => _token != null && _user != null;
  bool get wasExpired => _expired;

  /// En-tête à joindre aux requêtes protégées.
  Map<String, String> get authHeaders => _token == null ? const {} : {'Authorization': 'Bearer $_token'};

  /// Choisit le stockage (appelé une fois au lancement).
  void useStore(SessionStore store) => _store = store;

  /// Recharge la session enregistrée, si elle n'a pas expiré.
  Future<bool> restore() async {
    final saved = await _store.read();
    if (saved == null) return false;
    if (saved.expiresAt != null && !saved.expiresAt!.isAfter(DateTime.now())) {
      await _store.clear();
      return false;
    }
    _token = saved.token;
    _expiresAt = saved.expiresAt;
    _user = saved.user;
    _expired = false;
    notifyListeners();
    return true;
  }

  Future<void> open({required String token, required AppUser user, DateTime? expiresAt}) async {
    _token = token;
    _user = user;
    _expiresAt = expiresAt;
    _expired = false;
    await _store.write(StoredSession(token: token, expiresAt: expiresAt, user: user));
    notifyListeners();
  }

  /// Met à jour le profil affiché sans changer de jeton.
  Future<void> updateUser(AppUser user) async {
    if (_token == null) return;
    _user = user;
    await _store.write(StoredSession(token: _token!, expiresAt: _expiresAt, user: user));
    notifyListeners();
  }

  Future<void> close() async {
    final had = isAuthenticated;
    _token = null;
    _user = null;
    _expiresAt = null;
    await _store.clear();
    if (had) notifyListeners();
  }

  /// Le serveur a refusé le jeton (expiré, mot de passe changé ailleurs, compte suspendu).
  Future<void> expire() async {
    if (!isAuthenticated) return;
    _expired = true;
    await close();
  }
}
