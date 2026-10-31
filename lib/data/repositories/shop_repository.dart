/// Catalogue de la boutique.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/models/models.dart';

/// Erreur lisible, affichée telle quelle à l'utilisateur.
class ShopException implements Exception {
  const ShopException(this.message);
  final String message;
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

  @override
  Future<void> load() async {
    try {
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
        all.addAll([for (final p in body['items'] as List) Product.fromJson(p as Map<String, dynamic>)]);
        totalPages = body['totalPages'] as int;
        page++;
      }
      _products = all;
    } on ShopException {
      rethrow;
    } on TimeoutException {
      throw const ShopException('Le serveur met trop de temps à répondre. Réessayez.');
    } on http.ClientException {
      throw const ShopException('Impossible de joindre la boutique. Vérifiez votre connexion.');
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
