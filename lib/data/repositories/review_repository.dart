/// Avis sur les produits de la boutique.
library;

import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';

abstract class ReviewRepository {
  /// Faux en démonstration : les écrans gardent alors les notes du catalogue fictif.
  bool get enabled;

  Future<ReviewSummary> list(String productId);
  Future<MyReviewStatus> mine(String productId);
  Future<void> save(String productId, {required int rating, String? comment});
  Future<void> deleteMine(String productId);

  /// Modération par l'admin.
  Future<void> delete(int reviewId);
}

class MockReviewRepository implements ReviewRepository {
  @override
  bool get enabled => false;

  @override
  Future<ReviewSummary> list(String productId) async => const ReviewSummary(average: 0, count: 0, items: []);

  @override
  Future<MyReviewStatus> mine(String productId) async => const MyReviewStatus(canReview: false);

  @override
  Future<void> save(String productId, {required int rating, String? comment}) async {}

  @override
  Future<void> deleteMine(String productId) async {}

  @override
  Future<void> delete(int reviewId) async {}
}

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._api);
  final ApiClient _api;

  @override
  bool get enabled => true;

  @override
  Future<ReviewSummary> list(String productId) async {
    final json = await _api.get('/products/$productId/reviews?size=50') as Map<String, dynamic>;
    return ReviewSummary(
      average: (json['average'] as num).toDouble(),
      count: json['count'] as int,
      items: [for (final r in json['items'] as List) ProductReview.fromJson(r as Map<String, dynamic>)],
    );
  }

  @override
  Future<MyReviewStatus> mine(String productId) async {
    final json = await _api.get('/products/$productId/reviews/me') as Map<String, dynamic>;
    final review = json['review'] as Map<String, dynamic>?;
    return MyReviewStatus(
      canReview: json['canReview'] as bool,
      review: review == null ? null : ProductReview.fromJson(review),
    );
  }

  @override
  Future<void> save(String productId, {required int rating, String? comment}) =>
      _api.put('/products/$productId/reviews/me', {'rating': rating, 'comment': comment});

  @override
  Future<void> deleteMine(String productId) => _api.delete('/products/$productId/reviews/me');

  @override
  Future<void> delete(int reviewId) => _api.delete('/admin/reviews/$reviewId');
}
