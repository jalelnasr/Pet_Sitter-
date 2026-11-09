/// Résumé des ventes pour l'espace admin.
library;

class TopProductSale {
  const TopProductSale({required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final int revenue;
}

class LowStockItem {
  const LowStockItem({required this.name, required this.option, required this.stock});
  final String name;
  final String option;
  final int stock;
}

class SalesSummary {
  const SalesSummary({
    required this.days,
    required this.orders,
    required this.revenue,
    required this.changePercent,
    required this.averageBasket,
    required this.cancelled,
    required this.itemsSold,
    required this.topProducts,
    required this.lowStock,
    required this.commentary,
    required this.points,
    required this.demo,
    required this.commentaryError,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> json) {
    final s = json['stats'] as Map<String, dynamic>;
    return SalesSummary(
      days: s['days'] as int,
      orders: s['orders'] as int,
      revenue: s['revenue'] as int,
      changePercent: s['revenueChangePercent'] as int?,
      averageBasket: s['averageBasket'] as int,
      cancelled: s['cancelled'] as int,
      itemsSold: s['itemsSold'] as int,
      topProducts: [
        for (final p in s['topProducts'] as List)
          TopProductSale(name: p['name'] as String, quantity: p['quantity'] as int, revenue: p['revenue'] as int),
      ],
      lowStock: [
        for (final l in s['lowStock'] as List)
          LowStockItem(name: l['name'] as String, option: l['option'] as String, stock: l['stock'] as int),
      ],
      commentary: json['commentary'] as String?,
      points: [for (final p in json['points'] as List) p as String],
      demo: json['demo'] as bool,
      commentaryError: json['commentaryError'] as String?,
    );
  }

  final int days;
  final int orders;
  final int revenue;

  /// Évolution du chiffre d'affaires en %, ou null sans ventes sur la période précédente.
  final int? changePercent;
  final int averageBasket;
  final int cancelled;
  final int itemsSold;
  final List<TopProductSale> topProducts;
  final List<LowStockItem> lowStock;

  /// Texte rédigé par l'IA (ou de démonstration) ; null si l'analyse est indisponible.
  final String? commentary;
  final List<String> points;
  final bool demo;
  final String? commentaryError;
}
