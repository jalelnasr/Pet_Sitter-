import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/order_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

/// Catalogue de la boutique : recherche et filtres.
class ShopViewModel extends ViewModel {
  ShopViewModel({required ShopRepository shop, required PetRepository pets, required CartRepository cart})
    : _shop = shop,
      _cart = cart,
      _pets = pets {
    _pets.addListener(notify);
    load();
  }

  final ShopRepository _shop;
  final CartRepository _cart;
  final PetRepository _pets;

  /// Animaux du compte connecté (la section « Pour … » n'apparaît que s'il en a).
  List<Pet> get myPets => _pets.myPets();

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  /// Le catalogue peut être affiché : ni chargement, ni erreur.
  bool get ready => !_loading && _error == null;

  /// Charge le catalogue. Si une version est déjà affichée, un échec de l'actualisation la conserve.
  Future<void> load() async {
    _loading = _shop.products().isEmpty;
    _error = null;
    notify();
    try {
      await _shop.load();
    } on ShopException catch (e) {
      if (_shop.products().isEmpty) _error = e.message;
    }
    _loading = false;
    notify();
  }

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

  void addToCart(Product p) {
    final option = p.firstAvailable;
    if (option != null) _cart.add(p, option);
  }

  void clearFilters() {
    _species = null;
    _category = null;
    notify();
  }

  @override
  void dispose() {
    _pets.removeListener(notify);
    super.dispose();
  }
}

/// Fiche produit : format, quantité, favori, ajout au panier.
class ProductViewModel extends ViewModel {
  ProductViewModel(this.product, this._cart) : _option = product.firstAvailable ?? product.options.first;

  final Product product;
  final CartRepository _cart;

  ProductOption _option;
  ProductOption get option => _option;

  int _qty = 1;
  int get qty => _qty;

  bool _favorite = false;
  bool get favorite => _favorite;

  int get total => _option.price * _qty;

  bool get canAdd => _option.inStock;

  /// Quantité maximale : limitée par le stock quand il est connu.
  int get maxQty {
    final stock = _option.stock;
    return stock == null || stock > 20 ? 20 : (stock < 1 ? 1 : stock);
  }

  bool get showOldPrice => product.oldPrice != null && _option == product.options.first;

  String get optionTitle => switch (product.category) {
    ShopCategory.nourriture || ShopCategory.hygiene => 'Format',
    _ => product.options.first.label.length <= 2 ? 'Taille' : 'Modèle',
  };

  void setOption(ProductOption o) {
    _option = o;
    if (_qty > maxQty) _qty = maxQty;
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
  CartViewModel(this._cart, {OrderRepository? orders, AuthSession? session})
    : _orders = orders ?? MockOrderRepository(),
      _session = session {
    _cart.addListener(notify);
  }

  final CartRepository _cart;
  final OrderRepository _orders;
  final AuthSession? _session;

  bool get cardAvailable => _orders.cardAvailable;

  /// Il faut se connecter avant de commander.
  bool get needsLogin => _orders.requiresLogin && !(_session?.isAuthenticated ?? false);

  String? get userName => _session?.user?.fullName;

  DeliveryAddress? get address => _cart.deliveryAddress;

  void setAddress(DeliveryAddress a) {
    _cart.deliveryAddress = a;
    notify();
  }

  String? _orderError;
  String? get orderError => _orderError;

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
  void add(Product p) {
    final option = p.firstAvailable;
    if (option != null) _cart.add(p, option);
  }

  /// Passe la commande : le serveur recalcule les prix et vérifie le stock.
  /// Renvoie la commande, ou null en cas d'échec ([orderError] dit pourquoi).
  Future<Order?> order() async {
    final delivery = address;
    if (delivery == null) return null;
    _ordering = true;
    _orderError = null;
    notify();
    try {
      final placed = await _orders.place(lines: lines, payment: _payment, delivery: delivery);
      _cart.clear();
      return placed;
    } on ApiException catch (e) {
      _orderError = e.message;
      return null;
    } finally {
      _ordering = false;
      notify();
    }
  }

  @override
  void dispose() {
    _cart.removeListener(notify);
    super.dispose();
  }
}
