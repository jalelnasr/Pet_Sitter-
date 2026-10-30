/// Catalogue de la boutique.
library;

import 'package:pet_sitter/data/sources/mock_shop_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class ShopRepository {
  List<Product> products();

  /// Produits suggérés pour les espèces de l'utilisateur.
  List<Product> recommendedFor(Iterable<Species> species);
}

class MockShopRepository implements ShopRepository {
  @override
  List<Product> products() => Shop.products;

  @override
  List<Product> recommendedFor(Iterable<Species> species) => Shop.recommendedFor(species);
}
