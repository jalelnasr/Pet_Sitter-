import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/models/user.dart';
import 'package:pet_sitter/view_models/auth_view_model.dart';

/// Modification du profil (prénom, nom, téléphone, ville, présentation).
class EditProfileViewModel extends ViewModel {
  EditProfileViewModel(this._auth, AuthSession session) : user = session.user;

  final AuthRepository _auth;

  /// Profil au moment de l'ouverture (nul si personne n'est connecté).
  final AppUser? user;

  bool get canEdit => user != null;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  Map<String, String> _fieldErrors = const {};
  String? fieldError(String field) => _fieldErrors[field];

  Future<bool> save({
    required String firstName,
    required String lastName,
    required String phone,
    required String city,
    required String bio,
  }) async {
    _saving = true;
    _error = null;
    _fieldErrors = const {};
    notify();
    try {
      await _auth.updateProfile(firstName: firstName, lastName: lastName, phone: phone, city: city, bio: bio);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _fieldErrors = e.fieldErrors ?? const {};
      return false;
    } finally {
      _saving = false;
      notify();
    }
  }

  static String? validateFirstName(String? v) => (v == null || v.trim().isEmpty) ? 'Indiquez votre prénom.' : null;

  static String? validatePhone(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return null;
    if (!RegExp(r'^\+?[0-9 ]{8,20}$').hasMatch(value)) return 'Numéro invalide (ex. : +216 22 333 444).';
    return null;
  }
}

/// Changement du mot de passe depuis les paramètres.
class ChangePasswordViewModel extends ViewModel {
  ChangePasswordViewModel(this._auth);

  final AuthRepository _auth;

  bool _saving = false;
  bool get saving => _saving;

  String? _error;
  String? get error => _error;

  bool _done = false;
  bool get done => _done;

  Future<bool> submit({required String current, required String next}) async {
    _saving = true;
    _error = null;
    notify();
    try {
      await _auth.changePassword(currentPassword: current, newPassword: next);
      _done = true;
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _saving = false;
      notify();
    }
  }

  static String? validateNew(String? v) => AuthViewModel.validateNewPassword(v);

  static String? Function(String?) validateConfirm(String Function() expected) =>
      (v) => v != expected() ? 'Les deux mots de passe ne correspondent pas.' : null;
}
