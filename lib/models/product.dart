/// Produits de la boutique (nourriture, accessoires…) et lignes de panier.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'species.dart';

enum ShopCategory { nourriture, accessoires, jouets, hygiene }

extension ShopCategoryX on ShopCategory {
  String get label => switch (this) {
    ShopCategory.nourriture => 'Nourriture',
    ShopCategory.accessoires => 'Accessoires',
    ShopCategory.jouets => 'Jouets',
    ShopCategory.hygiene => 'Hygiène',
  };

  IconData get icon => switch (this) {
    ShopCategory.nourriture => PhosphorIconsRegular.bowlFood,
    ShopCategory.accessoires => PhosphorIconsRegular.tag,
    ShopCategory.jouets => PhosphorIconsRegular.tennisBall,
    ShopCategory.hygiene => PhosphorIconsRegular.drop,
  };
}

/// Forme de l'emballage dessiné.
enum PackKind { bag, can, tub, object }

class ProductOption {
  const ProductOption(this.label, this.price);
  final String label;
  final int price;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.species,
    required this.options,
    required this.rating,
    required this.reviews,
    required this.kind,
    required this.color,
    required this.tint,
    required this.icon,
    required this.description,
    required this.details,
    this.oldPrice,
    this.badge,
  });

  final String id;
  final String name;
  final String brand;
  final ShopCategory category;
  final List<Species> species;
  final List<ProductOption> options;
  final double rating;
  final int reviews;
  final PackKind kind;
  final Color color;
  final Color tint;
  final IconData icon;
  final String description;
  final Map<String, String> details;
  final int? oldPrice;
  final String? badge;

  int get price => options.first.price;
}

class CartLine {
  CartLine(this.product, this.option, this.qty);
  final Product product;
  final ProductOption option;
  int qty;
  int get total => option.price * qty;
}
