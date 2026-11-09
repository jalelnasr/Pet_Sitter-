/// Panier : partagé par plusieurs écrans (boutique, fiche produit, panier).
///
/// C'est un ChangeNotifier : quand son contenu change, il prévient les ViewModels
/// qui l'écoutent, et ceux-ci préviennent leurs écrans.
library;

import 'package:flutter/foundation.dart';
import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/models/models.dart';

class CartRepository extends ChangeNotifier {
  /// [demo] : panier de démonstration déjà rempli (deux produits).
  CartRepository({bool demo = true}) {
    if (!demo) return;
    add(Shop.products[0], Shop.products[0].options.first);
    add(Shop.products[3], Shop.products[3].options.first, qty: 2);
    deliveryAddress = const DeliveryAddress(
      recipient: 'Leïla Ben Salah',
      phone: '20 000 000',
      address: 'Rue du Lac Biwa',
      city: 'La Marsa',
    );
  }

  static const freeShippingFrom = 80;
  static const shippingFee = 7;

  /// Dernière adresse saisie, reprise à la commande suivante.
  DeliveryAddress? deliveryAddress;

  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);

  int get count => _lines.fold(0, (n, l) => n + l.qty);
  int get subtotal => _lines.fold(0, (n, l) => n + l.total);
  int get shipping => subtotal == 0 || subtotal >= freeShippingFrom ? 0 : shippingFee;
  int get total => subtotal + shipping;

  void add(Product p, ProductOption o, {int qty = 1}) {
    final existing = _lines.where((l) => l.product.id == p.id && l.option.label == o.label);
    if (existing.isNotEmpty) {
      existing.first.qty += qty;
    } else {
      _lines.add(CartLine(p, o, qty));
    }
    notifyListeners();
  }

  void setQty(CartLine line, int qty) {
    if (qty <= 0) {
      _lines.remove(line);
    } else {
      line.qty = qty;
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
