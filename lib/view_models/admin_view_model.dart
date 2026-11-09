import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/repositories/sales_analysis_repository.dart';
import 'package:pet_sitter/data/sources/gemini_client.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

/// Toutes les commandes, filtrables par statut.
class AdminOrdersViewModel extends ViewModel {
  AdminOrdersViewModel(this._admin) {
    load();
  }

  final AdminRepository _admin;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  OrderStatus? _filter;
  OrderStatus? get filter => _filter;

  List<Order> _items = const [];
  List<Order> get items => _items;

  /// Commande en cours de mise à jour (pour désactiver ses boutons).
  int? _updating;
  int? get updating => _updating;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _items = await _admin.orders(status: _filter);
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
  }

  void setFilter(OrderStatus? s) {
    _filter = s;
    load();
  }

  /// Renvoie un message d'erreur, ou null si le changement a réussi.
  Future<String?> setStatus(Order order, OrderStatus status) async {
    _updating = order.id;
    notify();
    String? failure;
    try {
      await _admin.setStatus(order.id, status);
    } on ApiException catch (e) {
      failure = e.message;
    }
    _updating = null;
    await load();
    return failure;
  }
}

/// Résumé des ventes sur une période.
class AdminSalesViewModel extends ViewModel {
  AdminSalesViewModel(this._admin, {SalesAnalysisRepository analysis = const DisabledSalesAnalysis()})
    : _analysis = analysis {
    load();
  }

  static const periods = [7, 30];

  final AdminRepository _admin;
  final SalesAnalysisRepository _analysis;

  /// L'analyse vient de l'IA externe (sinon : commentaire préparé par le serveur).
  bool get usesAi => _analysis.enabled;
  String get aiName => _analysis.providerName;

  bool _analyzing = false;
  bool get analyzing => _analyzing;

  SalesAnalysis? _analysisResult;
  SalesAnalysis? get analysis => _analysisResult;

  String? _analysisError;
  String? get analysisError => _analysisError;

  /// Mêmes chiffres, même texte : on ne rappelle pas l'API (et on ne consomme pas le quota) à chaque ouverture.
  final Map<String, SalesAnalysis> _cache = {};
  final Map<String, Future<SalesAnalysis>> _pending = {};

  Future<void> analyze() async {
    final s = _summary;
    if (s == null || !usesAi) return;
    final key = GeminiSalesAnalysis.describe(s);
    final cached = _cache[key];
    if (cached != null) {
      _analysisResult = cached;
      _analysisError = null;
      notify();
      return;
    }
    _analyzing = true;
    _analysisResult = null;
    _analysisError = null;
    notify();
    try {
      // Deux chargements rapprochés partagent la même demande au lieu d'appeler l'API deux fois.
      final result = await _pending.putIfAbsent(key, () => _analysis.analyze(s));
      _cache[key] = result;
      _analysisResult = result;
    } on GeminiException catch (e) {
      _analysisError = e.message;
    } finally {
      _pending.remove(key);
    }
    _analyzing = false;
    notify();
  }

  int _days = 7;
  int get days => _days;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  SalesSummary? _summary;
  SalesSummary? get summary => _summary;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _summary = await _admin.salesSummary(_days);
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
    await analyze();
  }

  void setDays(int d) {
    if (d == _days) return;
    _days = d;
    _summary = null;
    load();
  }
}

/// Catalogue complet, produits retirés compris.
class AdminProductsViewModel extends ViewModel {
  AdminProductsViewModel(this._admin) {
    load();
  }

  final AdminRepository _admin;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Product> _items = const [];
  List<Product> get items => _items;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _items = await _admin.products();
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
  }
}

/// Une ligne de format saisie dans le formulaire.
class OptionDraft {
  OptionDraft({this.label = '', this.price = '', this.stock = ''});
  String label;
  String price;
  String stock;
}

/// Une ligne de caractéristique saisie dans le formulaire.
class DetailDraft {
  DetailDraft({this.label = '', this.value = ''});
  String label;
  String value;
}

/// Formulaire de création ou de modification d'un produit.
class ProductFormViewModel extends ViewModel {
  ProductFormViewModel(this._admin, this.existing) {
    final p = existing;
    if (p == null) {
      options.add(OptionDraft());
      return;
    }
    name = p.name;
    brand = p.brand;
    description = p.description;
    oldPrice = p.oldPrice?.toString() ?? '';
    badge = p.badge ?? '';
    category = p.category;
    kind = p.kind;
    species = p.species.toSet();
    icon = p.iconName ?? icon;
    imageUrl = p.imageUrl;
    color = p.color;
    tint = p.tint;
    options.addAll([
      for (final o in p.options) OptionDraft(label: o.label, price: '${o.price}', stock: '${o.stock ?? 0}'),
    ]);
    if (options.isEmpty) options.add(OptionDraft());
    details.addAll([for (final e in p.details.entries) DetailDraft(label: e.key, value: e.value)]);
  }

  final AdminRepository _admin;
  final Product? existing;

  String name = '';
  String brand = '';
  String description = '';
  String oldPrice = '';
  String badge = '';
  ShopCategory category = ShopCategory.nourriture;
  Set<Species> species = {};

  // Visuel de secours si la photo ne charge pas : pas de choix dans le formulaire, un produit existant garde le sien.
  PackKind kind = PackKind.object;
  String icon = 'pawPrint';
  Color color = const Color(0xFF0F5534);
  Color tint = const Color(0xFFE3F1E7);

  /// Photo déjà enregistrée sur le serveur.
  String? imageUrl;

  /// Photo choisie à l'instant, envoyée au moment d'enregistrer.
  Uint8List? pickedImage;
  String? _pickedName;

  static const _maxImageBytes = 5 * 1024 * 1024;
  final List<OptionDraft> options = [];
  final List<DetailDraft> details = [];

  bool get isNew => existing == null;

  bool _saving = false;
  bool get saving => _saving;

  void setCategory(ShopCategory c) {
    category = c;
    notify();
  }

  /// Renvoie un message d'erreur, ou null si la photo est retenue.
  String? setImage(Uint8List bytes, String name) {
    if (bytes.length > _maxImageBytes) return 'La photo dépasse 5 Mo.';
    pickedImage = bytes;
    _pickedName = name;
    notify();
    return null;
  }

  void toggleSpecies(Species s) {
    species.contains(s) ? species.remove(s) : species.add(s);
    notify();
  }

  void addOption() {
    options.add(OptionDraft());
    notify();
  }

  void removeOption(OptionDraft o) {
    options.remove(o);
    notify();
  }

  void addDetail() {
    details.add(DetailDraft());
    notify();
  }

  void removeDetail(DetailDraft d) {
    details.remove(d);
    notify();
  }

  /// Identifiant du produit, déduit de son nom : « Pâtée chat » → `patee-chat`.
  static String slug(String name) {
    const accents = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'î': 'i', 'ï': 'i', //
      'ô': 'o', 'ö': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ç': 'c',
    };
    final plain = name.toLowerCase().split('').map((c) => accents[c] ?? c).join();
    final s = plain.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    return s.length > 60 ? s.substring(0, 60) : s;
  }

  /// Renvoie un message d'erreur, ou null si l'enregistrement a réussi.
  Future<String?> save() async {
    if (species.isEmpty) return 'Choisissez au moins une espèce.';
    if (options.isEmpty) return 'Ajoutez au moins un format.';
    final id = existing?.id ?? slug(name);
    if (id.length < 2) return 'Le nom du produit est trop court.';
    if (isNew && pickedImage == null) return 'Ajoutez une photo du produit.';

    final payload = <String, dynamic>{
      'name': name.trim(),
      'brand': brand.trim(),
      'category': category.name,
      'species': [for (final s in species) s.name],
      'description': description.trim(),
      'options': [
        for (final o in options)
          {'label': o.label.trim(), 'price': int.parse(o.price.trim()), 'stock': int.parse(o.stock.trim())},
      ],
      'details': [
        for (final d in details) {'label': d.label.trim(), 'value': d.value.trim()},
      ],
      'oldPrice': oldPrice.trim().isEmpty ? null : int.parse(oldPrice.trim()),
      'badge': badge.trim().isEmpty ? null : badge.trim(),
      'packKind': kind.name,
      'color': colorToHex(color),
      'tint': colorToHex(tint),
      'icon': icon,
      'imageUrl': imageUrl,
    };

    _saving = true;
    notify();
    String? failure;
    try {
      final picked = pickedImage;
      if (picked != null) {
        imageUrl = await _admin.uploadImage(picked, _pickedName ?? 'photo');
        pickedImage = null;
        payload['imageUrl'] = imageUrl;
      }
      if (isNew) {
        await _admin.createProduct(id, payload);
      } else {
        await _admin.updateProduct(id, payload);
      }
    } on ApiException catch (e) {
      failure = e.message;
    }
    _saving = false;
    notify();
    return failure;
  }

  /// Renvoie un message d'erreur, ou null si le retrait a réussi.
  Future<String?> remove() async {
    _saving = true;
    notify();
    String? failure;
    try {
      await _admin.removeProduct(existing!.id);
    } on ApiException catch (e) {
      failure = e.message;
    }
    _saving = false;
    notify();
    return failure;
  }
}
