/// Espace admin : catalogue complet et toutes les commandes.
library;

import 'dart:typed_data';

import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

abstract class AdminRepository {
  Future<List<Product>> products();

  /// Envoie une photo et renvoie son adresse, à enregistrer avec le produit.
  Future<String> uploadImage(Uint8List bytes, String filename);
  Future<void> createProduct(String id, Map<String, dynamic> product);
  Future<void> updateProduct(String id, Map<String, dynamic> product);

  /// Retire de la vente : le produit reste en base pour l'historique des commandes.
  Future<void> removeProduct(String id);

  Future<List<Order>> orders({OrderStatus? status});
  Future<Order> setStatus(int id, OrderStatus status);
}

/// L'espace admin n'a de sens qu'avec le backend.
class MockAdminRepository implements AdminRepository {
  static const _error = ApiException('L\'espace admin nécessite le backend (USE_API=true).');

  @override
  Future<List<Product>> products() => throw _error;
  @override
  Future<String> uploadImage(Uint8List bytes, String filename) => throw _error;
  @override
  Future<void> createProduct(String id, Map<String, dynamic> product) => throw _error;
  @override
  Future<void> updateProduct(String id, Map<String, dynamic> product) => throw _error;
  @override
  Future<void> removeProduct(String id) => throw _error;
  @override
  Future<List<Order>> orders({OrderStatus? status}) => throw _error;
  @override
  Future<Order> setStatus(int id, OrderStatus status) => throw _error;
}

class ApiAdminRepository implements AdminRepository {
  ApiAdminRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Product>> products() async => [
    for (final p in await _api.getAllPages('/admin/products')) Product.fromJson(p),
  ];

  @override
  Future<String> uploadImage(Uint8List bytes, String filename) async {
    final json = await _api.upload('/admin/product-images', bytes, filename) as Map<String, dynamic>;
    return json['url'] as String;
  }

  @override
  Future<void> createProduct(String id, Map<String, dynamic> product) =>
      _api.post('/admin/products', {'id': id, 'product': product});

  @override
  Future<void> updateProduct(String id, Map<String, dynamic> product) => _api.put('/admin/products/$id', product);

  @override
  Future<void> removeProduct(String id) => _api.delete('/admin/products/$id');

  @override
  Future<List<Order>> orders({OrderStatus? status}) async {
    final path = status == null ? '/admin/orders' : '/admin/orders?status=${status.api}';
    return [for (final o in await _api.getAllPages(path)) Order.fromJson(o)];
  }

  @override
  Future<Order> setStatus(int id, OrderStatus status) async =>
      Order.fromJson(await _api.patch('/admin/orders/$id/status', {'status': status.api}) as Map<String, dynamic>);
}
