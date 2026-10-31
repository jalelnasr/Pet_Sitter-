import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/review_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/session.dart';
import 'package:pet_sitter/models/models.dart';

/// Avis d'un produit : lecture publique, avis du client qui a reçu le produit, modération par l'admin.
class ProductReviewsViewModel extends ViewModel {
  ProductReviewsViewModel(this._reviews, this._session, this.productId) {
    if (enabled) load();
  }

  final ReviewRepository _reviews;
  final Session _session;
  final String productId;

  bool get enabled => _reviews.enabled;
  bool get isAdmin => _session.user?.role == UserRole.admin;
  bool get isLoggedIn => _session.isLoggedIn;

  bool _loading = true;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  double _average = 0;
  double get average => _average;

  int _count = 0;
  int get count => _count;

  List<ProductReview> _items = const [];
  List<ProductReview> get items => _items;

  bool _canReview = false;
  bool get canReview => _canReview;

  ProductReview? _mine;
  ProductReview? get mine => _mine;

  bool _saving = false;
  bool get saving => _saving;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      final summary = await _reviews.list(productId);
      _average = summary.average;
      _count = summary.count;
      _items = summary.items;
      if (isLoggedIn) {
        final status = await _reviews.mine(productId);
        _canReview = status.canReview;
        _mine = status.review;
      } else {
        _canReview = false;
        _mine = null;
      }
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notify();
  }

  /// Renvoie un message d'erreur, ou null si l'action a réussi.
  Future<String?> save(int rating, String comment) => _run(() {
    final text = comment.trim();
    return _reviews.save(productId, rating: rating, comment: text.isEmpty ? null : text);
  });

  Future<String?> removeMine() => _run(() => _reviews.deleteMine(productId));

  Future<String?> moderate(ProductReview review) => _run(() => _reviews.delete(review.id));

  Future<String?> _run(Future<void> Function() action) async {
    _saving = true;
    notify();
    String? failure;
    try {
      await action();
    } on ApiException catch (e) {
      failure = e.message;
    }
    _saving = false;
    await load();
    return failure;
  }
}
