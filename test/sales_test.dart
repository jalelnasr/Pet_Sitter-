// Résumé des ventes, avec un faux client HTTP.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/view_models/admin_view_model.dart';

Map<String, dynamic> _summary({Object? commentary = 'Bonne semaine.', int? change = 20}) => {
  'stats': {
    'days': 7,
    'from': '2026-11-02T10:00:00Z',
    'to': '2026-11-09T10:00:00Z',
    'orders': 3,
    'revenue': 210,
    'previousRevenue': 175,
    'revenueChangePercent': change,
    'averageBasket': 70,
    'cancelled': 1,
    'itemsSold': 5,
    'topProducts': [
      {'productId': 'croq', 'name': 'Croquettes été', 'quantity': 3, 'revenue': 147},
    ],
    'lowStock': [
      {'productId': 'fontaine', 'name': 'Fontaine', 'option': '2 L', 'stock': 0},
    ],
  },
  'commentary': commentary,
  'points': commentary == null ? [] : ['Réapprovisionner la fontaine.'],
  'demo': false,
  'commentaryError': commentary == null ? 'L\'analyse par IA est indisponible pour le moment.' : null,
};

AdminSalesViewModel _vm(MockClient client) => AdminSalesViewModel(
  ApiAdminRepository(ApiClient(baseUrl: 'http://api', session: AuthSession.isolated(), client: client)),
);

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  test('lit les chiffres et le commentaire, puis change de période', () async {
    final asked = <String>[];
    final vm = _vm(
      MockClient((r) async {
        asked.add(r.url.queryParameters['days']!);
        return _json(_summary());
      }),
    );
    await vm.load();
    final s = vm.summary!;
    expect(s.revenue, 210);
    expect(s.changePercent, 20);
    expect(s.topProducts.single.name, 'Croquettes été');
    expect(s.lowStock.single.stock, 0);
    expect(s.commentary, 'Bonne semaine.');
    vm.setDays(30);
    await vm.load();
    expect(asked, containsAll(['7', '30']));
  });

  test('sans analyse IA, les chiffres restent disponibles', () async {
    final vm = _vm(MockClient((_) async => _json(_summary(commentary: null, change: null))));
    await vm.load();
    expect(vm.error, isNull);
    expect(vm.summary!.commentary, isNull);
    expect(vm.summary!.commentaryError, contains('indisponible'));
    expect(vm.summary!.changePercent, isNull);
  });

  test('erreur du serveur : message clair', () async {
    final vm = _vm(MockClient((_) async => _json({'detail': 'Vous n\'avez pas accès.'}, 403)));
    await vm.load();
    expect(vm.error, isNotNull);
    expect(vm.summary, isNull);
  });
}
