/// Analyse du résumé des ventes, rédigée par une IA externe appelée depuis l'application.
library;

import 'package:pet_sitter/data/sources/gemini_client.dart';
import 'package:pet_sitter/models/models.dart';

class SalesAnalysis {
  const SalesAnalysis({required this.summary, required this.points});
  final String summary;
  final List<String> points;
}

abstract class SalesAnalysisRepository {
  /// Faux sans clé : l'écran affiche alors le commentaire préparé par le serveur.
  bool get enabled;

  /// Nom affiché sous l'analyse (« Gemini »).
  String get providerName;

  /// Lance [GeminiException] en cas d'échec.
  Future<SalesAnalysis> analyze(SalesSummary summary);
}

class DisabledSalesAnalysis implements SalesAnalysisRepository {
  const DisabledSalesAnalysis();

  @override
  bool get enabled => false;

  @override
  String get providerName => '';

  @override
  Future<SalesAnalysis> analyze(SalesSummary summary) => throw const GeminiException('Analyse IA non configurée.');
}

class GeminiSalesAnalysis implements SalesAnalysisRepository {
  GeminiSalesAnalysis(this._gemini);
  final GeminiClient _gemini;

  static const _instructions = '''
Tu aides l'administrateur d'une petite boutique en ligne d'accessoires et de nourriture pour animaux, en Tunisie.
À partir des chiffres fournis, écris en français :
- summary : deux ou trois phrases qui résument la période ;
- points : de 2 à 4 actions concrètes et courtes.
N'utilise que les chiffres fournis : n'en invente aucun. Si les données sont trop faibles pour conclure, dis-le.
Les montants sont en dinars (DT). Reste factuel.''';

  static const _schema = {
    'type': 'OBJECT',
    'properties': {
      'summary': {'type': 'STRING'},
      'points': {
        'type': 'ARRAY',
        'items': {'type': 'STRING'},
      },
    },
    'required': ['summary', 'points'],
  };

  @override
  bool get enabled => _gemini.enabled;

  @override
  String get providerName => 'Gemini';

  @override
  Future<SalesAnalysis> analyze(SalesSummary summary) async {
    final json = await _gemini.generateJson(instructions: _instructions, prompt: describe(summary), schema: _schema);
    final text = json['summary'];
    final points = json['points'];
    if (text is! String || text.trim().isEmpty || points is! List) {
      throw const GeminiException('Gemini a envoyé une réponse illisible. Réessayez.');
    }
    return SalesAnalysis(
      summary: text.trim(),
      points: [
        for (final p in points.take(4))
          if (p is String && p.trim().isNotEmpty) p.trim(),
      ],
    );
  }

  /// Seuls des chiffres agrégés partent vers Gemini : aucun nom, aucune adresse de client.
  static String describe(SalesSummary s) {
    final top = s.topProducts.map((p) => '${p.name} : ${p.quantity} vendus, ${p.revenue} DT').join(' ; ');
    final low = s.lowStock.map((l) => '${l.name} (${l.option}) : ${l.stock} restants').join(' ; ');
    final change = s.changePercent == null ? 'non calculable (aucune vente avant)' : '${s.changePercent} %';
    return '''
Période : ${s.days} derniers jours
Commandes (hors annulées) : ${s.orders}
Chiffre d'affaires : ${s.revenue} DT
Évolution par rapport à la période précédente : $change
Panier moyen : ${s.averageBasket} DT
Commandes annulées : ${s.cancelled}
Articles vendus : ${s.itemsSold}
Produits les plus vendus : ${top.isEmpty ? 'aucun' : top}
Stocks bas (5 ou moins) : ${low.isEmpty ? 'aucun' : low}''';
  }
}
