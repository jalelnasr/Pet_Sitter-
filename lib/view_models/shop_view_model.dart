import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Catalogue de la boutique : recherche et filtres.
class ShopViewModel extends ViewModel {
  ShopViewModel({required ShopRepository shop, required PetRepository pets, required CartRepository cart})
    : _shop = shop,
      _cart = cart,
      myPets = pets.myPets();

  final ShopRepository _shop;
  final CartRepository _cart;
  final List<Pet> myPets;

  Species? _species;
  Species? get species => _species;

  ShopCategory? _category;
  ShopCategory? get category => _category;

  String _query = '';
  bool get hasFilters => _species != null || _category != null || _query.isNotEmpty;

  List<Product> get recommended => _shop.recommendedFor(myPets.map((p) => p.species));

  List<Product> get products => _shop.products().where((p) {
    if (_species != null && !p.species.contains(_species)) return false;
    if (_category != null && p.category != _category) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      if (!p.name.toLowerCase().contains(q) && !p.brand.toLowerCase().contains(q)) return false;
    }
    return true;
  }).toList();

  String get gridTitle =>
      _category?.label ?? (_species != null ? 'Pour ${_species!.plural.toLowerCase()}' : 'Tous les produits');

  void setSpecies(Species? s) {
    _species = s;
    notify();
  }

  void toggleCategory(ShopCategory? c) {
    _category = (c == null || _category == c) ? null : c;
    notify();
  }

  void setQuery(String q) {
    _query = q.trim();
    notify();
  }

  void addToCart(Product p) => _cart.add(p, p.options.first);

  void clearFilters() {
    _species = null;
    _category = null;
    notify();
  }
}

/// Fiche produit : format, quantité, favori, ajout au panier.
class ProductViewModel extends ViewModel {
  ProductViewModel(this.product, this._cart) : _option = product.options.first;

  final Product product;
  final CartRepository _cart;

  ProductOption _option;
  ProductOption get option => _option;

  int _qty = 1;
  int get qty => _qty;

  bool _favorite = false;
  bool get favorite => _favorite;

  int get total => _option.price * _qty;
  bool get showOldPrice => product.oldPrice != null && _option == product.options.first;

  String get optionTitle => switch (product.category) {
    ShopCategory.nourriture || ShopCategory.hygiene => 'Format',
    _ => product.options.first.label.length <= 2 ? 'Taille' : 'Modèle',
  };

  void setOption(ProductOption o) {
    _option = o;
    notify();
  }

  void setQty(int q) {
    _qty = q;
    notify();
  }

  void toggleFavorite() {
    _favorite = !_favorite;
    notify();
  }

  void addToCart() => _cart.add(product, _option, qty: _qty);
}

/// Panier et commande. Écoute le dépôt du panier, partagé avec les autres écrans.
class CartViewModel extends ViewModel {
  CartViewModel(this._cart) {
    _cart.addListener(notify);
  }

  final CartRepository _cart;

  List<CartLine> get lines => _cart.lines;
  int get count => _cart.count;
  int get subtotal => _cart.subtotal;
  int get shipping => _cart.shipping;
  int get total => _cart.total;
  bool get isEmpty => _cart.lines.isEmpty;

  /// Montant restant pour obtenir la livraison offerte, et progression (0 → 1).
  int get missingForFreeShipping => CartRepository.freeShippingFrom - subtotal;
  double get freeShippingProgress => (subtotal / CartRepository.freeShippingFrom).clamp(0.0, 1.0);

  String _payment = 'cash';
  String get payment => _payment;

  bool _ordering = false;
  bool get ordering => _ordering;

  void setPayment(String p) {
    _payment = p;
    notify();
  }

  void setQty(CartLine line, int qty) => _cart.setQty(line, qty);
  void remove(CartLine line) => _cart.setQty(line, 0);
  void add(Product p) => _cart.add(p, p.options.first);

  /// Passe la commande ; renvoie (total, nombre d'articles) pour l'écran de confirmation.
  Future<(int, int)> order() async {
    _ordering = true;
    notify();
    final result = await _cart.placeOrder(payment: _payment);
    _ordering = false;
    notify();
    return result;
  }

  @override
  void dispose() {
    _cart.removeListener(notify);
    super.dispose();
  }
}
