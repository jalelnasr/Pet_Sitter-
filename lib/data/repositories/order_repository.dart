/// Commandes du client connecté.
library;

import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

abstract class OrderRepository {
  /// Paiement par carte proposé à l'écran.
  bool get cardAvailable;

  /// Il faut un compte pour commander.
  bool get requiresLogin;

  /// Lance [ApiException] en cas d'échec (stock insuffisant…).
  Future<Order> place({required List<CartLine> lines, required String payment, required DeliveryAddress delivery});
  Future<List<Order>> mine();
  Future<Order> cancel(int id);
}

/// Version de démonstration : les commandes restent en mémoire.
class MockOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  var _nextId = 1;

  @override
  bool get cardAvailable => true;

  @override
  bool get requiresLogin => false;

  @override
  Future<Order> place({
    required List<CartLine> lines,
    required String payment,
    required DeliveryAddress delivery,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1300));
    final subtotal = lines.fold(0, (n, l) => n + l.total);
    final shipping = subtotal >= CartRepository.freeShippingFrom ? 0 : CartRepository.shippingFee;
    final now = DateTime.now();
    final order = Order(
      id: _nextId,
      number: 'PS-${10481 + _nextId++}',
      status: OrderStatus.confirmed,
      paid: false,
      subtotal: subtotal,
      shipping: shipping,
      total: subtotal + shipping,
      itemCount: lines.fold(0, (n, l) => n + l.qty),
      delivery: delivery,
      createdAt: now,
      lines: [
        for (final l in lines)
          OrderLine(
            productName: l.product.name,
            optionLabel: l.option.label,
            unitPrice: l.option.price,
            quantity: l.qty,
            lineTotal: l.total,
          ),
      ],
      history: [OrderEvent(OrderStatus.confirmed, now)],
    );
    _orders.insert(0, order);
    return order;
  }

  @override
  Future<List<Order>> mine() async => List.unmodifiable(_orders);

  @override
  Future<Order> cancel(int id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    final o = _orders[i];
    final cancelled = Order(
      id: o.id,
      number: o.number,
      status: OrderStatus.cancelled,
      paid: false,
      subtotal: o.subtotal,
      shipping: o.shipping,
      total: o.total,
      itemCount: o.itemCount,
      delivery: o.delivery,
      createdAt: o.createdAt,
      lines: o.lines,
      history: [...o.history, OrderEvent(OrderStatus.cancelled, DateTime.now())],
    );
    _orders[i] = cancelled;
    return cancelled;
  }
}

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._api);
  final ApiClient _api;

  @override
  bool get cardAvailable => false; // aucun prestataire de paiement branché côté serveur

  @override
  bool get requiresLogin => true;

  @override
  Future<Order> place({
    required List<CartLine> lines,
    required String payment,
    required DeliveryAddress delivery,
  }) async {
    if (lines.any((l) => l.option.id == null)) {
      throw const ApiException('Un article du panier n\'est plus en vente.');
    }
    final json = await _api.post('/orders', {
      'items': [
        for (final l in lines) {'optionId': l.option.id, 'quantity': l.qty},
      ],
      'payment': payment == 'card' ? 'CARD' : 'CASH',
      'recipient': delivery.recipient,
      'phone': delivery.phone,
      'address': delivery.address,
      'city': delivery.city,
    });
    return Order.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<List<Order>> mine() async => [for (final o in await _api.getAllPages('/orders/me')) Order.fromJson(o)];

  @override
  Future<Order> cancel(int id) async => Order.fromJson(await _api.post('/orders/$id/cancel') as Map<String, dynamic>);
}
