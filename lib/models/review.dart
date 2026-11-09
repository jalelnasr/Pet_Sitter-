/// Avis des clients sur les produits de la boutique.
library;

class ProductReview {
  const ProductReview({
    required this.id,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
    id: json['id'] as int,
    author: json['authorName'] as String,
    rating: json['rating'] as int,
    comment: json['comment'] as String?,
    date: DateTime.parse(json['createdAt'] as String).toLocal(),
  );

  final int id;
  final String author;
  final int rating;
  final String? comment;
  final DateTime date;
}

class ReviewSummary {
  const ReviewSummary({required this.average, required this.count, required this.items});
  final double average;
  final int count;
  final List<ProductReview> items;
}

/// Ce que le compte connecté peut faire sur un produit.
class MyReviewStatus {
  const MyReviewStatus({required this.canReview, this.review});
  final bool canReview;
  final ProductReview? review;
}
