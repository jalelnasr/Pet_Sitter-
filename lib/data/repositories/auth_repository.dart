/// Connexion et inscription.
///
/// L'interface décrit CE QUE l'application peut demander ; l'implémentation de démonstration
/// simule un serveur (délais, erreurs). Pour brancher un vrai serveur, il suffira d'écrire
/// une autre classe qui respecte la même interface, sans toucher aux écrans.
library;

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
}
