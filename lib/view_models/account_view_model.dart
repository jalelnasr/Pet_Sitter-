import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/auth_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Onglet Profil : identité du compte connecté, raccourcis et déconnexion.
/// Sans compte connecté (aperçus du sommaire), le profil de démonstration est affiché.
class AccountViewModel extends ViewModel {
  AccountViewModel(this._pets, this._sitters, {AuthRepository? auth, AuthSession? session})
    : _auth = auth,
      _session = session {
    _session?.addListener(notify);
    _pets.addListener(notify);
  }

  final PetRepository _pets;
  final SitterRepository _sitters;
  final AuthRepository? _auth;
  final AuthSession? _session;

  AppUser? get user => _session?.user;
  bool get isSignedIn => user != null;

  int get favoritesCount => _sitters.favorites().length;

  String get fullName => user?.fullName ?? _pets.ownerFullName;

  /// Photo du compte ; à défaut, la photo de démonstration (seulement sans compte connecté).
  String get photo => user == null ? _pets.ownerPhoto : (user!.photoUrl ?? '');
  String get initials => user?.initials ?? '';

  String get subtitle {
    final u = user;
    if (u == null) return 'La Marsa, Tunis · membre depuis 2025';
    final since = u.createdAt == null ? null : 'membre depuis ${u.createdAt!.year}';
    return [u.city, since].whereType<String>().where((s) => s.isNotEmpty).join(' · ').ifEmpty(u.email);
  }

  bool get isPetsitter => user?.role == AppRole.petsitter;

  List<Pet> get pets => _pets.myPets();
  String get petsSummary => pets.isEmpty ? 'Aucun animal pour le moment' : pets.map((p) => p.name).join(', ');

  String? _error;
  String? get error => _error;

  bool _switching = false;
  bool get switching => _switching;

  /// Propriétaire ↔ pet sitter : enregistré sur le compte s'il y en a un.
  Future<bool> switchRole(AppRole role) async {
    final auth = _auth;
    if (auth == null || !isSignedIn || user!.role == role) return true;
    _switching = true;
    _error = null;
    notify();
    try {
      await auth.changeRole(role);
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _switching = false;
      notify();
    }
  }

  bool _signingOut = false;
  bool get signingOut => _signingOut;

  Future<void> logOut() async {
    _signingOut = true;
    notify();
    await (_auth?.logOut() ?? _session?.close() ?? Future.value());
    _signingOut = false;
    notify();
  }

  @override
  void dispose() {
    _session?.removeListener(notify);
    _pets.removeListener(notify);
    super.dispose();
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/// Préférences de notifications.
class NotificationsViewModel extends ViewModel {
  final Map<String, bool> prefs = {
    'Messages des sitters': true,
    'Réponses à mes demandes': true,
    'Journal de garde (photos, repas)': true,
    'Rappels avant une garde': true,
    'Conseils et nouveautés': false,
  };

  void setPref(String key, bool value) {
    prefs[key] = value;
    notify();
  }
}

/// Paramètres : langue, confidentialité.
class SettingsViewModel extends ViewModel {
  String _language = 'Français';
  String get language => _language;

  bool _sharePhone = false;
  bool get sharePhone => _sharePhone;

  void setLanguage(String l) {
    _language = l;
    notify();
  }

  void setSharePhone(bool v) {
    _sharePhone = v;
    notify();
  }
}

/// Sitters favoris.
class FavoritesViewModel extends ViewModel {
  FavoritesViewModel(SitterRepository sitters) : favorites = sitters.favorites();
  final List<Sitter> favorites;
}
