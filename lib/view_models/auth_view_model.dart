import 'dart:async';

import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/models/user.dart';

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

  /// Compte ouvert après un envoi réussi (sert à choisir l'écran suivant).
  AppUser? _user;
  AppUser? get user => _user;

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
        final (first, last) = splitName(name);
        _user = await _auth.signUp(firstName: first, lastName: last, email: email, password: password);
      } else {
        _user = await _auth.logIn(email: email, password: password);
      }
      return true;
    } on AuthException catch (e) {
      _banner = _readable(e);
      return false;
    } finally {
      _loading = false;
      notify();
    }
  }

  Future<bool> signInWith(String provider) async {
    _banner = null;
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

  /// Message du serveur, complété par la première erreur de champ s'il y en a une.
  static String _readable(AuthException e) {
    final field = e.fieldErrors?.values.firstOrNull;
    return field == null || e.message.contains(field) ? e.message : '${e.message} $field';
  }

  /// « Leïla Ben Salah » → (« Leïla », « Ben Salah »).
  static (String, String?) splitName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first;
    final last = parts.length > 1 ? parts.sublist(1).join(' ') : null;
    return (first, last);
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

  /// Règle du serveur : 8 caractères minimum, dont un chiffre.
  static String? validateNewPassword(String? v) {
    if (v == null || v.isEmpty) return 'Choisissez un mot de passe.';
    if (v.length < 8) return 'Au moins 8 caractères, dont un chiffre.';
    if (!RegExp(r'\d').hasMatch(v)) return 'Ajoutez au moins un chiffre.';
    if (v.length > 72) return '72 caractères au maximum.';
    return null;
  }

  String? validatePassword(String? v) {
    if (!isSignup) return (v == null || v.isEmpty) ? 'Saisissez votre mot de passe.' : null;
    return validateNewPassword(v);
  }
}

/// Étapes de la récupération : adresse → code + nouveau mot de passe → terminé.
enum ResetStep { email, code, done }

/// Récupération du mot de passe par code à 6 chiffres envoyé par e-mail.
class ForgotPasswordViewModel extends ViewModel {
  /// [sentTo] : démarre directement sur l'étape du code (aperçu).
  ForgotPasswordViewModel(this._auth, {String? sentTo})
    : _email = sentTo?.trim() ?? '',
      _step = sentTo == null ? ResetStep.email : ResetStep.code;

  final AuthRepository _auth;

  ResetStep _step;
  ResetStep get step => _step;

  String _email;
  String get email => _email;

  /// Compatibilité avec les aperçus : adresse à laquelle le code a été envoyé.
  String? get sentTo => _step == ResetStep.email ? null : _email;
  bool get sent => _step != ResetStep.email;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  String? _info;
  String? get info => _info;

  int _resendIn = 0;
  int get resendIn => _resendIn;
  bool get canResend => _resendIn == 0 && !_loading;

  Timer? _timer;

  void _startCountdown(int seconds) {
    _timer?.cancel();
    _resendIn = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _resendIn = (_resendIn - 1).clamp(0, 9999);
      if (_resendIn == 0) t.cancel();
      notify();
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    _error = null;
    notify();
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notify();
    }
  }

  /// Étape 1 : demande le code.
  Future<bool> send(String email) => _run(() async {
    _email = email.trim();
    final retry = await _auth.requestPasswordReset(_email);
    _step = ResetStep.code;
    _info = null;
    _startCountdown(retry);
  });

  Future<bool> resend() async {
    if (!canResend) return false;
    return _run(() async {
      final retry = await _auth.requestPasswordReset(_email);
      _info = 'Un nouveau code a été envoyé.';
      _startCountdown(retry);
    });
  }

  /// Étape 2 : code + nouveau mot de passe. La session est ouverte en cas de succès.
  Future<bool> reset({required String code, required String newPassword}) => _run(() async {
    await _auth.resetPassword(email: _email, code: code, newPassword: newPassword);
    _timer?.cancel();
    _step = ResetStep.done;
  });

  /// Revenir à l'adresse (faute de frappe).
  void changeEmail() {
    _timer?.cancel();
    _resendIn = 0;
    _error = null;
    _info = null;
    _step = ResetStep.email;
    notify();
  }

  static String? validateCode(String? v) {
    final code = v?.trim() ?? '';
    if (code.isEmpty) return 'Saisissez le code reçu par e-mail.';
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return 'Le code contient 6 chiffres.';
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Choix du profil après l'inscription : 0 = je cherche une garde, 1 = je deviens pet sitter.
class RoleChoiceViewModel extends ViewModel {
  RoleChoiceViewModel([this._auth, this.firstName]);

  final AuthRepository? _auth;

  /// Prénom affiché dans « Bienvenue, … ».
  final String? firstName;

  int? _choice;
  int? get choice => _choice;
  bool get canContinue => _choice != null && !_loading;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  void choose(int c) {
    _choice = c < 0 ? null : c;
    _error = null;
    notify();
  }

  /// Enregistre le rôle choisi sur le compte. Renvoie `true` si l'écran peut continuer.
  Future<bool> confirm() async {
    final auth = _auth;
    if (_choice == null) return false;
    if (auth == null) return true; // aperçu sans compte
    _loading = true;
    _error = null;
    notify();
    try {
      await auth.changeRole(_choice == 1 ? AppRole.petsitter : AppRole.owner);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notify();
    }
  }
}
