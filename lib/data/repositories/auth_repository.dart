/// Connexion et inscription.
///
/// L'interface décrit CE QUE l'application peut demander ; l'implémentation de démonstration
/// simule un serveur (délais, erreurs). Pour brancher un vrai serveur, il suffira d'écrire
/// une autre classe qui respecte la même interface, sans toucher aux écrans.
library;

import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/session.dart';

/// Erreur métier lisible, affichée telle quelle à l'utilisateur.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<void> signUp({required String name, required String email, required String password});
  Future<void> logIn({required String email, required String password});
  Future<void> signInWith(String provider); // 'apple' | 'google'
  Future<void> sendResetLink(String email);

  /// Profil choisi après l'inscription.
  Future<void> chooseRole(UserRole role);
  Future<void> logOut();
}

class MockAuthRepository implements AuthRepository {
  @override
  Future<void> signUp({required String name, required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (email.trim().toLowerCase() == 'deja@petsitter.tn') {
      throw const AuthException(
        'Un compte existe déjà avec cette adresse. Connectez-vous ou réinitialisez votre mot de passe.',
      );
    }
  }

  @override
  Future<void> logIn({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (password.length < 8) {
      throw const AuthException('E-mail ou mot de passe incorrect. Il vous reste 4 tentatives.');
    }
  }

  @override
  Future<void> signInWith(String provider) => Future.delayed(const Duration(milliseconds: 1100));

  @override
  Future<void> sendResetLink(String email) => Future.delayed(const Duration(milliseconds: 1200));

  @override
  Future<void> chooseRole(UserRole role) async {}

  @override
  Future<void> logOut() async {}
}

/// Comptes gérés par le backend (`/api/auth`).
/// Provisoire, pour tester la boutique : à remplacer par le module « User » de l'équipe.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._session);

  final ApiClient _api;
  final Session _session;

  Future<void> _open(String path, Map<String, dynamic> body, {bool put = false}) async {
    try {
      final json = (put ? await _api.put(path, body) : await _api.post(path, body)) as Map<String, dynamic>;
      await _session.open(json['token'] as String, SessionUser.fromJson(json['user'] as Map<String, dynamic>));
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  /// Compte créé comme propriétaire ; l'écran suivant permet de choisir un autre profil.
  @override
  Future<void> signUp({required String name, required String email, required String password}) => _open(
    '/auth/register',
    {'name': name.trim(), 'email': email.trim(), 'password': password, 'role': UserRole.owner.api},
  );

  @override
  Future<void> logIn({required String email, required String password}) =>
      _open('/auth/login', {'email': email.trim(), 'password': password});

  @override
  Future<void> signInWith(String provider) async {
    throw const AuthException('La connexion avec Apple ou Google n\'est pas encore disponible.');
  }

  @override
  Future<void> sendResetLink(String email) async {
    throw const AuthException('La réinitialisation du mot de passe n\'est pas encore disponible.');
  }

  @override
  Future<void> chooseRole(UserRole role) => _open('/auth/me/role', {'role': role.api}, put: true);

  @override
  Future<void> logOut() => _session.close();
}
