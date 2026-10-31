/// Les pet sitters : liste, recherche par critères.
library;

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class SitterRepository {
  List<Sitter> all();

  /// Quartiers et villes proposés dans le choix du lieu.
  List<(String, String)> cities();

  /// Sitters mis en favoris par l'utilisateur.
  List<Sitter> favorites();

  /// Sitters qui gardent [species] et proposent [service], dans le budget et la distance donnés.
  List<Sitter> search({
    required Set<Species> species,
    required ServiceType service,
    required double minPrice,
    required double maxPrice,
    required double maxDistanceKm,
  });
}

class MockSitterRepository implements SitterRepository {
  @override
  List<Sitter> all() => Mock.sitters;

  @override
  List<(String, String)> cities() => Mock.cities;

  @override
  List<Sitter> favorites() => [Mock.amira, Mock.ines];

  @override
  List<Sitter> search({
    required Set<Species> species,
    required ServiceType service,
    required double minPrice,
    required double maxPrice,
    required double maxDistanceKm,
  }) {
    return Mock.sitters.where((s) {
      final offer = s.services.where((o) => o.type == service);
      if (offer.isEmpty) return false;
      final p = offer.first.price;
      return species.every(s.species.contains) && p >= minPrice && p <= maxPrice && s.distanceKm <= maxDistanceKm;
    }).toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }
}
