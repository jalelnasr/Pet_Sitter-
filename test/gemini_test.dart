// Analyse des ventes par Gemini, avec un faux client HTTP.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/repositories/sales_analysis_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/gemini_client.dart';
import 'package:pet_sitter/data/sources/session.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/admin_view_model.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

http.Response _gemini(Map<String, dynamic> answer) => _json({
  'candidates': [
    {
      'finishReason': 'STOP',
      'content': {
        'parts': [
          {'text': jsonEncode(answer)},
        ],
      },
    },
  ],
});

const _summary = SalesSummary(
  days: 7,
  orders: 3,
  revenue: 183,
  changePercent: 22,
  averageBasket: 61,
  cancelled: 1,
  itemsSold: 4,
  topProducts: [TopProductSale(name: 'Croquettes été', quantity: 3, revenue: 147)],
  lowStock: [LowStockItem(name: 'Croquettes été', option: '2 kg', stock: 3)],
  commentary: 'Texte du serveur',
  points: [],
  demo: true,
  commentaryError: null,
);

Map<String, dynamic> _serverSummary() => {
  'stats': {
    'days': 7,
    'orders': 3,
    'revenue': 183,
    'previousRevenue': 150,
    'revenueChangePercent': 22,
    'averageBasket': 61,
    'cancelled': 1,
    'itemsSold': 4,
    'topProducts': [],
    'lowStock': [],
  },
  'commentary': 'Texte du serveur',
  'points': [],
  'demo': true,
  'commentaryError': null,
};

GeminiSalesAnalysis _analysis(MockClient client, {String key = 'cle-test'}) =>
    GeminiSalesAnalysis(GeminiClient(apiKey: key, model: 'gemini-test', client: client));

void main() {
  test('appelle Gemini avec la clé et un format JSON imposé, sans données de client', () async {
    late http.Request sent;
    final analysis = _analysis(
      MockClient((r) async {
        sent = r;
        return _gemini({
          'summary': 'Bonne semaine : 183 DT.',
          'points': ['Réapprovisionner les croquettes.', '', 'Surveiller l\'annulation.'],
        });
      }),
    );
    final result = await analysis.analyze(_summary);
    expect(sent.url.toString(), contains('/models/gemini-test:generateContent'));
    expect(sent.headers['x-goog-api-key'], 'cle-test');
    final body = jsonDecode(sent.body) as Map<String, dynamic>;
    expect(body['generationConfig']['responseMimeType'], 'application/json');
    final prompt = body['contents'][0]['parts'][0]['text'] as String;
    expect(prompt, contains('Chiffre d\'affaires : 183 DT'));
    expect(prompt, contains('22 %'));
    expect(prompt, isNot(contains('@')));
    expect(result.summary, 'Bonne semaine : 183 DT.');
    expect(result.points, ['Réapprovisionner les croquettes.', 'Surveiller l\'annulation.']);
  });

  test('clé refusée, quota, refus et réponse illisible : messages clairs', () async {
    final cases = {
      _json({
        'error': {'status': 'INVALID_ARGUMENT', 'message': 'API key not valid.'},
      }, 400): 'Clé Gemini refusée',
      _json({}, 429): 'Quota',
      _json({'candidates': []}): 'refusé',
      _gemini({'autre': 1}): 'illisible',
    };
    for (final entry in cases.entries) {
      final analysis = _analysis(MockClient((_) async => entry.key));
      await expectLater(
        analysis.analyze(_summary),
        throwsA(isA<GeminiException>().having((e) => e.message, 'message', contains(entry.value))),
      );
    }
  });

  test('sans clé, l\'analyse Gemini est désactivée', () {
    expect(_analysis(MockClient((_) async => _json({})), key: '').enabled, isFalse);
  });

  test('l\'écran Ventes demande l\'analyse à Gemini et la garde tant que les chiffres ne changent pas', () async {
    var geminiCalls = 0;
    final vm = AdminSalesViewModel(
      ApiAdminRepository(
        ApiClient(baseUrl: 'http://api', session: Session(), client: MockClient((_) async => _json(_serverSummary()))),
      ),
      analysis: _analysis(
        MockClient((_) async {
          geminiCalls++;
          return _gemini({
            'summary': 'Analyse Gemini.',
            'points': ['Action.'],
          });
        }),
      ),
    );
    await vm.load();
    expect(vm.usesAi, isTrue);
    expect(vm.analysis!.summary, 'Analyse Gemini.');
    await vm.load();
    expect(geminiCalls, 1);
  });

  test('si Gemini échoue, les chiffres restent affichés', () async {
    final vm = AdminSalesViewModel(
      ApiAdminRepository(
        ApiClient(baseUrl: 'http://api', session: Session(), client: MockClient((_) async => _json(_serverSummary()))),
      ),
      analysis: _analysis(MockClient((_) async => _json({}, 500))),
    );
    await vm.load();
    expect(vm.summary!.revenue, 183);
    expect(vm.analysis, isNull);
    expect(vm.analysisError, contains('indisponible'));
  });
}
