import 'package:flutter/material.dart' show RangeValues;
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Résultats de recherche : filtres, liste ou carte, favoris.
class SearchViewModel extends ViewModel {
  SearchViewModel(this._sitters, {SearchQuery? query, this.forceEmpty = false, bool startOnMap = false})
    : query =
          query ??
          (forceEmpty ? SearchQuery(species: Species.lapin, area: 'Route de l\'Aïn', city: 'Sfax') : SearchQuery()),
      _showMap = startOnMap;

  final SitterRepository _sitters;
  final SearchQuery query;
  final SearchFilters filters = SearchFilters();

  /// Aperçu de l'état « aucun résultat ».
  final bool forceEmpty;

  bool _showMap;
  bool get showMap => _showMap;

  String _selectedId = 'amira';
  final Set<String> _favorites = {'ines'};

  List<Sitter> get results => forceEmpty
      ? const []
      : _sitters.search(
          species: {query.species, ...filters.species},
          service: query.service,
          minPrice: filters.budget.start,
          maxPrice: filters.budget.end,
          maxDistanceKm: filters.distance,
        );

  /// Sitter mis en avant sur la carte.
  Sitter? get selected {
    final r = results;
    if (r.isEmpty) return null;
    return r.firstWhere((s) => s.id == _selectedId, orElse: () => r.first);
  }

  bool isFavorite(Sitter s) => _favorites.contains(s.id);

  void setShowMap(bool v) {
    _showMap = v;
    notify();
  }

  void select(String id) {
    _selectedId = id;
    notify();
  }

  void toggleFavorite(Sitter s) {
    _favorites.contains(s.id) ? _favorites.remove(s.id) : _favorites.add(s.id);
    notify();
  }

  // ———— Filtres

  void setBudget(RangeValues v) {
    filters.budget = v;
    notify();
  }

  void setDistance(double km) {
    filters.distance = km;
    notify();
  }

  void toggleExtraSpecies(Species s) {
    filters.species.contains(s) ? filters.species.remove(s) : filters.species.add(s);
    notify();
  }

  void setAllDates(bool v) {
    filters.allDates = v;
    notify();
  }

  void setLastMinute(bool v) {
    filters.lastMinute = v;
    notify();
  }

  void resetFilters() {
    filters
      ..budget = const RangeValues(10, 60)
      ..distance = 10
      ..lastMinute = false
      ..species.clear();
    notify();
  }
}
