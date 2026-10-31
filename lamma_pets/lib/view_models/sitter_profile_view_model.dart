import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/models/models.dart';

/// Profil d'un pet sitter.
class SitterProfileViewModel extends ViewModel {
  SitterProfileViewModel(this.sitter);
  final Sitter sitter;

  bool _favorite = false;
  bool get favorite => _favorite;

  /// Les vérifications et les avis ne s'affichent que s'ils existent.
  bool get showVerifications => sitter.verifications.isNotEmpty;
  bool get showReviews => sitter.hasReviews;
  bool get hostsAtHome => sitter.services.any((s) => s.type == ServiceType.accueil);

  void toggleFavorite() {
    _favorite = !_favorite;
    notify();
  }
}
