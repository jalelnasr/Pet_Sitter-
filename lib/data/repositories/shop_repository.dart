/// Catalogue de la boutique.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_sitter/data/local/shop_local_store.dart';
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/models/models.dart';

/// Erreur lisible, affichée telle quelle à l'utilisateur.
class ShopException implements Exception {
  const ShopException(this.message, {this.offline = false});
  final String message;

  /// Serveur injoignable (et non réponse en erreur).
  final bool offline;
  @override
  String toString() => message;
}

abstract class ShopRepository {
  /// Charge ou actualise le catalogue. Lance [ShopException] en cas d'échec.
  Future<void> load();

  /// Dernier catalogue chargé.
  List<Product> products();

  /// Produits suggérés pour les espèces de l'utilisateur.
  List<Product> recommendedFor(Iterable<Species> species);
}

class MockShopRepository implements ShopRepository {
  @override
  Future<void> load() async {}

  @override
  List<Product> products() => Shop.products;

  @override
  List<Product> recommendedFor(Iterable<Species> species) => Shop.recommendedFor(species);
}

/// Catalogue servi par le backend Spring Boot (`GET /api/products`).
class ApiShopRepository implements ShopRepository {
  ApiShopRepository({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  static const _pageSize = 100;
  static const _timeout = Duration(seconds: 10);

  final String baseUrl;
  final http.Client _client;

  List<Product> _products = const [];

  final _local = const ShopLocalStore();

  @override
  Future<void> load() async {
    try {
      await _loadFromServer();
    } on ShopException catch (e) {
      // Pas de réseau : catalogue enregistré dans SQLite (s'il a déjà été chargé une fois).
      if (!e.offline) rethrow;
      final saved = await _local.readProducts();
      if (saved.isEmpty) rethrow;
      _products = [for (final p in saved) Product.fromJson(p)];
    }
  }

  Future<void> _loadFromServer() async {
    try {
      final raw = <Map<String, dynamic>>[];
      final all = <Product>[];
      var page = 0;
      var totalPages = 1;
      while (page < totalPages) {
        final url = Uri.parse('$baseUrl/products?page=$page&size=$_pageSize');
        final response = await _client.get(url).timeout(_timeout);
        if (response.statusCode != 200) {
          throw const ShopException('La boutique est indisponible pour le moment. Réessayez.');
        }
        final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        for (final p in body['items'] as List) {
          raw.add(p as Map<String, dynamic>);
          all.add(Product.fromJson(p));
        }
        totalPages = body['totalPages'] as int;
        page++;
      }
      _products = all;
      await _local.saveProducts(raw);
    } on ShopException {
      rethrow;
    } on TimeoutException {
      throw const ShopException('Le serveur met trop de temps à répondre. Réessayez.', offline: true);
    } on http.ClientException {
      throw const ShopException('Impossible de joindre la boutique. Vérifiez votre connexion.', offline: true);
    } on FormatException {
      throw const ShopException('La boutique a envoyé une réponse illisible.');
    } on TypeError {
      throw const ShopException('La boutique a envoyé une réponse illisible.');
    } on ArgumentError {
      throw const ShopException('La boutique a envoyé une réponse illisible.');
    }
  }

  @override
  List<Product> products() => _products;

  @override
  List<Product> recommendedFor(Iterable<Species> species) =>
      _products.where((p) => p.species.any(species.contains)).take(6).toList();
}
