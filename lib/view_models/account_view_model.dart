import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Onglet Profil : identité et raccourcis.
class AccountViewModel extends ViewModel {
  AccountViewModel(this._pets, this._sitters);
  final PetRepository _pets;
  final SitterRepository _sitters;

  int get favoritesCount => _sitters.favorites().length;

  String get fullName => _pets.ownerFullName;
  String get photo => _pets.ownerPhoto;
  List<Pet> get pets => _pets.myPets();
  String get petsSummary => pets.map((p) => p.name).join(', ');
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
