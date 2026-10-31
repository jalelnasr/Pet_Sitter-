/// Critères d'une recherche de pet sitter (espèce, lieu, dates, service) et filtres.
library;

import 'package:flutter/material.dart' show DateTimeRange, RangeValues;
import 'package:pet_sitter/core/utils/format.dart';

import 'species.dart';

class SearchQuery {
  SearchQuery({
    this.species = Species.chat,
    this.area = 'La Marsa',
    this.city = 'Tunis',
    DateTimeRange? dates,
    this.service = ServiceType.accueil,
  }) : dates = dates ?? DateTimeRange(start: DateTime(2026, 10, 23), end: DateTime(2026, 10, 26));

  Species species;
  String area;
  String city;
  DateTimeRange dates;
  ServiceType service;

  int get nights => dates.end.difference(dates.start).inDays;
  String get datesLabel => '${frDate(dates.start, weekday: false)} – ${frDate(dates.end, weekday: false)}';
  String get summary => '${species.label} · $area · $datesLabel';
}

class SearchFilters {
  RangeValues budget = const RangeValues(10, 60);
  double distance = 10;
  Set<Species> species = {};
  bool allDates = true;
  bool lastMinute = false;

  int get activeCount =>
      (budget != const RangeValues(10, 60) ? 1 : 0) +
      (distance != 10 ? 1 : 0) +
      (species.isNotEmpty ? 1 : 0) +
      (lastMinute ? 1 : 0);
}
