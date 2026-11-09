// Avis produits, avec un faux client HTTP.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/review_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/view_models/reviews_view_model.dart';

Map<String, dynamic> _review(int rating, {String? comment}) => {
  'id': 1,
  'authorName': 'Amira',
  'rating': rating,
  'comment': comment,
  'createdAt': '2026-10-31T14:00:00Z',
};

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  test('visiteur : lit les avis sans appeler la route du compte', () async {
    final paths = <String>[];
    final session = AuthSession.isolated();
    final vm = ProductReviewsViewModel(
      ApiReviewRepository(
        ApiClient(
          baseUrl: 'http://api',
          session: session,
          client: MockClient((r) async {
            paths.add(r.url.path);
            return _json({
              'average': 4.5,
              'count': 2,
              'items': [_review(5, comment: 'Très bien, été comme hiver')],
              'page': 0,
              'totalPages': 1,
            });
          }),
        ),
      ),
      session,
      'croq',
    );
    await vm.load();
    expect(vm.average, 4.5);
    expect(vm.count, 2);
    expect(vm.items.single.comment, 'Très bien, été comme hiver');
    expect(vm.canReview, isFalse);
    expect(paths.toSet(), {'/products/croq/reviews'});
  });

  test('client qui a reçu le produit : publie puis la liste se met à jour', () async {
    final session = AuthSession.isolated();
    await session.open(
      token: 'j',
      user: const AppUser(id: 'u', firstName: 'S', email: 'e', role: AppRole.owner),
    );
    Map<String, dynamic>? sent;
    final vm = ProductReviewsViewModel(
      ApiReviewRepository(
        ApiClient(
          baseUrl: 'http://api',
          session: session,
          client: MockClient((r) async {
            if (r.method == 'PUT') {
              sent = jsonDecode(r.body) as Map<String, dynamic>;
              return _json(_review(4));
            }
            if (r.url.path.endsWith('/me')) {
              return _json({'canReview': true, 'review': sent == null ? null : _review(4)});
            }
            return _json({
              'average': sent == null ? 0 : 4,
              'count': sent == null ? 0 : 1,
              'items': sent == null ? [] : [_review(4)],
              'page': 0,
              'totalPages': 1,
            });
          }),
        ),
      ),
      session,
      'croq',
    );
    await vm.load();
    expect(vm.canReview, isTrue);
    expect(vm.mine, isNull);

    expect(await vm.save(4, '   '), isNull);
    expect(sent, {'rating': 4, 'comment': null});
    expect(vm.mine!.rating, 4);
    expect(vm.count, 1);
  });

  test('refus du serveur : le message est renvoyé', () async {
    final session = AuthSession.isolated();
    await session.open(
      token: 'j',
      user: const AppUser(id: 'u', firstName: 'S', email: 'e', role: AppRole.owner),
    );
    final vm = ProductReviewsViewModel(
      ApiReviewRepository(
        ApiClient(
          baseUrl: 'http://api',
          session: session,
          client: MockClient((r) async {
            if (r.method == 'PUT') return _json({'detail': 'Après réception.'}, 409);
            if (r.url.path.endsWith('/me')) return _json({'canReview': true, 'review': null});
            return _json({'average': 0, 'count': 0, 'items': [], 'page': 0, 'totalPages': 0});
          }),
        ),
      ),
      session,
      'croq',
    );
    await vm.load();
    expect(await vm.save(5, ''), 'Après réception.');
  });

  test('en démonstration, la section est désactivée', () {
    final vm = ProductReviewsViewModel(MockReviewRepository(), AuthSession.isolated(), 'croq');
    expect(vm.enabled, isFalse);
  });
}
