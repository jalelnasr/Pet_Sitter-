/// Commandes de la boutique, telles que renvoyées par le serveur.
library;

enum OrderStatus { confirmed, preparing, shipped, delivered, cancelled }

extension OrderStatusX on OrderStatus {
  /// Nom utilisé par l'API (`CONFIRMED`…).
  String get api => name.toUpperCase();

  String get label => switch (this) {
    OrderStatus.confirmed => 'Confirmée',
    OrderStatus.preparing => 'En préparation',
    OrderStatus.shipped => 'En route',
    OrderStatus.delivered => 'Livrée',
    OrderStatus.cancelled => 'Annulée',
  };

  /// Texte du bouton qui fait passer une commande à ce statut (espace admin).
  String get action => switch (this) {
    OrderStatus.confirmed => 'Confirmer',
    OrderStatus.preparing => 'Préparer',
    OrderStatus.shipped => 'Expédier',
    OrderStatus.delivered => 'Marquer livrée',
    OrderStatus.cancelled => 'Annuler',
  };

  /// Statuts accessibles ensuite : mêmes règles que le serveur.
  List<OrderStatus> get next => switch (this) {
    OrderStatus.confirmed => const [OrderStatus.preparing, OrderStatus.cancelled],
    OrderStatus.preparing => const [OrderStatus.shipped, OrderStatus.cancelled],
    OrderStatus.shipped => const [OrderStatus.delivered],
    OrderStatus.delivered || OrderStatus.cancelled => const [],
  };

  static OrderStatus fromApi(String s) => OrderStatus.values.byName(s.toLowerCase());
}

class DeliveryAddress {
  const DeliveryAddress({required this.recipient, required this.phone, required this.address, required this.city});
  final String recipient;
  final String phone;
  final String address;
  final String city;
}

class OrderLine {
  const OrderLine({
    required this.productName,
    required this.optionLabel,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
    productName: json['productName'] as String,
    optionLabel: json['optionLabel'] as String,
    unitPrice: json['unitPrice'] as int,
    quantity: json['quantity'] as int,
    lineTotal: json['lineTotal'] as int,
  );

  final String productName;
  final String optionLabel;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
}

class OrderEvent {
  const OrderEvent(this.status, this.at);
  final OrderStatus status;
  final DateTime at;
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.paid,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.itemCount,
    required this.delivery,
    required this.createdAt,
    required this.lines,
    required this.history,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    number: json['number'] as String,
    status: OrderStatusX.fromApi(json['status'] as String),
    paid: json['paymentStatus'] == 'PAID',
    subtotal: json['subtotal'] as int,
    shipping: json['shipping'] as int,
    total: json['total'] as int,
    itemCount: json['itemCount'] as int,
    delivery: DeliveryAddress(
      recipient: json['recipient'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    lines: [for (final l in json['items'] as List) OrderLine.fromJson(l as Map<String, dynamic>)],
    history: [
      for (final e in json['history'] as List)
        OrderEvent(OrderStatusX.fromApi(e['status'] as String), DateTime.parse(e['changedAt'] as String).toLocal()),
    ],
  );

  final int id;
  final String number;
  final OrderStatus status;
  final bool paid;
  final int subtotal;
  final int shipping;
  final int total;
  final int itemCount;
  final DeliveryAddress delivery;
  final DateTime createdAt;
  final List<OrderLine> lines;
  final List<OrderEvent> history;

  /// Le client peut annuler tant que la préparation n'a pas commencé.
  bool get cancellable => status == OrderStatus.confirmed;
}
