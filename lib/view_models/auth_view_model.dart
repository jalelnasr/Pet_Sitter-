import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/sources/session.dart';

enum AuthMode { signup, login }

/// État et logique de l'écran d'accès (inscription / connexion).
/// L'écran se contente d'afficher cet état et d'appeler ces méthodes.
class AuthViewModel extends ViewModel {
  AuthViewModel(this._auth, {AuthMode initialMode = AuthMode.signup, String? initialError})
    : _mode = initialMode,
      _banner = initialError;

  final AuthRepository _auth;

  AuthMode _mode;
  AuthMode get mode => _mode;
  bool get isSignup => _mode == AuthMode.signup;

  bool _loading = false;
  bool get loading => _loading;

  String? _socialLoading; // 'apple' | 'google'
  String? get socialLoading => _socialLoading;

  String? _banner; // erreur générale (identifiants refusés, compte existant…)
  String? get banner => _banner;

  bool _termsAccepted = false;
  bool get termsAccepted => _termsAccepted;

  bool _termsError = false;
  bool get termsError => _termsError;

  void switchMode(AuthMode m) {
    if (m == _mode) return;
    _mode = m;
    _banner = null;
    _termsError = false;
    notify();
  }

  void setTerms(bool accepted) {
    _termsAccepted = accepted;
    _termsError = false;
    notify();
  }

  /// Valide puis envoie le formulaire. Renvoie `true` si l'écran peut passer à la suite.
  Future<bool> submit({
    required bool fieldsValid,
    required String name,
    required String email,
    required String password,
  }) async {
    _banner = null;
    _termsError = isSignup && !_termsAccepted;
    notify();
    if (!fieldsValid || _termsError) return false;

    _loading = true;
    notify();
    try {
      if (isSignup) {
        await _auth.signUp(name: name, email: email, password: password);
      } else {
        await _auth.logIn(email: email, password: password);
      }
      return true;
    } on AuthException catch (e) {
      _banner = e.message;
      return false;
    } finally {
      _loading = false;
      notify();
    }
  }

  Future<bool> signInWith(String provider) async {
    _socialLoading = provider;
    notify();
    try {
      await _auth.signInWith(provider);
      return true;
    } on AuthException catch (e) {
      _banner = e.message;
      return false;
    } finally {
      _socialLoading = null;
      notify();
    }
  }

  // ———— Règles de validation (utilisées par les champs du formulaire)

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$', caseSensitive: false);

  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Indiquez votre adresse e-mail.';
    if (!_emailRe.hasMatch(v.trim())) return 'Cette adresse e-mail semble incomplète (ex. : nom@exemple.tn).';
    return null;
  }

  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Indiquez votre nom.';
    if (v.trim().split(RegExp(r'\s+')).length < 2) return 'Ajoutez votre prénom et votre nom.';
    return null;
  }

  String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return isSignup ? 'Choisissez un mot de passe.' : 'Saisissez votre mot de passe.';
    if (!isSignup) return null;
    if (v.length < 8) return 'Au moins 8 caractères, dont un chiffre.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Ajoutez au moins un chiffre.';
    return null;
  }
}

/// Récupération du mot de passe.
class ForgotPasswordViewModel extends ViewModel {
  /// [sentTo] : démarre directement sur la confirmation (aperçu).
  ForgotPasswordViewModel(this._auth, {String? sentTo}) : _sentTo = sentTo;
  final AuthRepository _auth;

  bool _loading = false;
  bool get loading => _loading;

  String? _sentTo;
  String? get sentTo => _sentTo;
  bool get sent => _sentTo != null;

  String? _error;
  String? get error => _error;

  Future<void> send(String email) async {
    _loading = true;
    _error = null;
    notify();
    try {
      await _auth.sendResetLink(email);
      _sentTo = email.trim();
    } on AuthException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
  }
}

/// Choix du profil après l'inscription : 0 = je cherche une garde, 1 = je deviens pet sitter.
class RoleChoiceViewModel extends ViewModel {
  RoleChoiceViewModel([this._auth]);

  final AuthRepository? _auth;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  /// Enregistre le profil choisi. Renvoie `true` si l'écran peut passer à la suite.
  Future<bool> confirm() async {
    _saving = true;
    _error = null;
    notify();
    try {
      await _auth?.chooseRole(_choice == 1 ? UserRole.petsitter : UserRole.owner);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notify();
    }
  }

  int? _choice;
  int? get choice => _choice;
  bool get canContinue => _choice != null;

  void choose(int c) {
    _choice = c < 0 ? null : c;
    notify();
  }
}
