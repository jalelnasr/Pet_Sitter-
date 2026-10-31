import 'package:flutter/material.dart' show DateTimeRange;
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/data/repositories/sitter_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Accueil propriétaire : moteur de recherche, sitters proches, animaux, produits suggérés.
class HomeViewModel extends ViewModel {
  HomeViewModel({
    required SitterRepository sitters,
    required PetRepository pets,
    required ShopRepository shop,
    required CartRepository cart,
  }) : _sitters = sitters,
       _pets = pets,
       _shop = shop,
       _cart = cart;

  final SitterRepository _sitters;
  final PetRepository _pets;
  final ShopRepository _shop;
  final CartRepository _cart;

  /// Critères saisis dans le moteur de recherche.
  final SearchQuery query = SearchQuery();

  Species? _filter = Species.chat;
  Species? get filter => _filter;

  String get ownerFirstName => _pets.ownerFirstName;
  String get ownerPhoto => _pets.ownerPhoto;
  List<Pet> get pets => _pets.myPets();
  List<(String, String)> get cities => _sitters.cities();

  List<Sitter> get nearbySitters =>
      _sitters.all().where((s) => _filter == null || s.species.contains(_filter)).toList();

  List<Product> get recommendedProducts => _shop.recommendedFor(pets.map((p) => p.species));

  void addToCart(Product p) => _cart.add(p, p.options.first);

  void setFilter(Species? s) {
    _filter = s;
    if (s != null) query.species = s;
    notify();
  }

  void setPlace(String area, String city) {
    query
      ..area = area
      ..city = city;
    notify();
  }

  void setDates(DateTimeRange r) {
    query.dates = r;
    notify();
  }

  void setService(ServiceType s) {
    query.service = s;
    notify();
  }
}
