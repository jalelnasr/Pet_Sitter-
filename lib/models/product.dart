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
  const ProductOption(this.label, this.price, {this.id, this.stock});

  factory ProductOption.fromJson(Map<String, dynamic> json) =>
      ProductOption(json['label'] as String, json['price'] as int, id: json['id'] as int, stock: json['stock'] as int);

  final String label;
  final int price;

  /// Identifiant et stock côté serveur (absents des données de démonstration).
  final int? id;
  final int? stock;

  bool get inStock => stock == null || stock! > 0;
}

/// Icônes que le serveur peut désigner par leur nom.
const _productIcons = {
  'bathtub': PhosphorIconsFill.bathtub,
  'bed': PhosphorIconsFill.bed,
  'bird': PhosphorIconsFill.bird,
  'cat': PhosphorIconsFill.cat,
  'dog': PhosphorIconsFill.dog,
  'drop': PhosphorIconsFill.drop,
  'fish': PhosphorIconsFill.fish,
  'footprints': PhosphorIconsFill.footprints,
  'houseLine': PhosphorIconsFill.houseLine,
  'leaf': PhosphorIconsFill.leaf,
  'rabbit': PhosphorIconsFill.rabbit,
  'tennisBall': PhosphorIconsFill.tennisBall,
  'waves': PhosphorIconsFill.waves,
};

String colorToHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

Color _colorFromHex(String hex) => Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));

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
    this.iconName,
    this.imageUrl,
    this.active = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    name: json['name'] as String,
    brand: json['brand'] as String,
    category: ShopCategory.values.byName(json['category'] as String),
    species: [for (final s in json['species'] as List) Species.values.byName(s as String)],
    options: [for (final o in json['options'] as List) ProductOption.fromJson(o as Map<String, dynamic>)],
    rating: (json['rating'] as num).toDouble(),
    reviews: json['reviews'] as int,
    kind: PackKind.values.byName(json['packKind'] as String),
    color: _colorFromHex(json['color'] as String),
    tint: _colorFromHex(json['tint'] as String),
    icon: _productIcons[json['icon']] ?? PhosphorIconsFill.pawPrint,
    description: json['description'] as String,
    details: {for (final d in json['details'] as List) d['label'] as String: d['value'] as String},
    oldPrice: json['oldPrice'] as int?,
    badge: json['badge'] as String?,
    iconName: json['icon'] as String?,
    imageUrl: json['imageUrl'] as String?,
    active: json['active'] as bool? ?? true,
  );

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
  final String? iconName;
  final String? imageUrl;
  final bool active;

  int get price => options.first.price;

  /// Premier format encore en stock, ou null si tout est épuisé.
  ProductOption? get firstAvailable {
    for (final o in options) {
      if (o.inStock) return o;
    }
    return null;
  }

  bool get soldOut => firstAvailable == null;
}

class CartLine {
  CartLine(this.product, this.option, this.qty);
  final Product product;
  final ProductOption option;
  int qty;
  int get total => option.price * qty;
}
