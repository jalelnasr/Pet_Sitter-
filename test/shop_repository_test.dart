// Tests du catalogue servi par l'API, avec un faux client HTTP.

import 'dart:convert';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/data/repositories/shop_repository.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/shop_view_model.dart';

Map<String, dynamic> _product(String id, {String icon = 'cat'}) => {
  'id': id,
  'name': 'Croquettes stérilisé',
  'brand': 'Félin+',
  'category': 'nourriture',
  'species': ['chat'],
  'options': [
    {'id': 7, 'label': '2 kg', 'price': 49, 'stock': 48},
  ],
  'rating': 4.8,
  'reviews': 214,
  'packKind': 'bag',
  'color': '#0F5534',
  'tint': '#E3F1E7',
  'icon': icon,
  'imageUrl': null,
  'description': 'Recette au poulet',
  'details': [
    {'label': 'Âge', 'value': 'Adulte'},
  ],
  'oldPrice': null,
  'badge': 'Local',
  'active': true,
};

http.Response _page(List<Map<String, dynamic>> items, int totalPages) => http.Response.bytes(
  utf8.encode(
    jsonEncode({'items': items, 'page': 0, 'size': 100, 'totalItems': items.length, 'totalPages': totalPages}),
  ),
  200,
);

ShopViewModel _vm(ShopRepository shop) =>
    ShopViewModel(shop: shop, pets: MockPetRepository(), cart: CartRepository(demo: false));

void main() {
  group('ApiShopRepository', () {
    test('convertit le JSON du serveur, accents et couleurs compris', () async {
      final repo = ApiShopRepository(baseUrl: 'http://api', client: MockClient((_) async => _page([_product('a')], 1)));
      await repo.load();
      final p = repo.products().single;
      expect(p.name, 'Croquettes stérilisé');
      expect(p.brand, 'Félin+');
      expect(p.category, ShopCategory.nourriture);
      expect(p.species, [Species.chat]);
      expect(p.options.single.id, 7);
      expect(p.options.single.stock, 48);
      expect(p.price, 49);
      expect(p.kind, PackKind.bag);
      expect(p.color, const Color(0xFF0F5534));
      expect(p.details['Âge'], 'Adulte');
      expect(p.oldPrice, isNull);
      expect(repo.recommendedFor([Species.chat]).length, 1);
      expect(repo.recommendedFor([Species.poisson]), isEmpty);
    });

    test('récupère toutes les pages', () async {
      final pages = <String>[];
      final repo = ApiShopRepository(
        baseUrl: 'http://api',
        client: MockClient((r) async {
          final page = r.url.queryParameters['page']!;
          pages.add(page);
          return _page([_product('p$page')], 2);
        }),
      );
      await repo.load();
      expect(pages, ['0', '1']);
      expect(repo.products().map((p) => p.id), ['p0', 'p1']);
    });

    test('une icône inconnue ne casse pas le catalogue', () async {
      final repo = ApiShopRepository(
        baseUrl: 'http://api',
        client: MockClient((_) async => _page([_product('a', icon: 'inconnue')], 1)),
      );
      await repo.load();
      expect(repo.products().length, 1);
    });

    test('erreur serveur, réseau ou réponse illisible : message lisible', () async {
      for (final client in [
        MockClient((_) async => http.Response('boom', 500)),
        MockClient((_) async => throw http.ClientException('refusé')),
        MockClient((_) async => http.Response('pas du json', 200)),
        MockClient((_) async => http.Response('{"items":[{"id":1}],"totalPages":1}', 200)),
      ]) {
        final repo = ApiShopRepository(baseUrl: 'http://api', client: client);
        await expectLater(repo.load(), throwsA(isA<ShopException>()));
        expect(repo.products(), isEmpty);
      }
    });
  });

  group('ShopViewModel avec API', () {
    test('passe du chargement au catalogue', () async {
      final vm = _vm(
        ApiShopRepository(baseUrl: 'http://api', client: MockClient((_) async => _page([_product('a')], 1))),
      );
      expect(vm.loading, isTrue);
      expect(vm.ready, isFalse);
      await vm.load();
      expect(vm.ready, isTrue);
      expect(vm.products.length, 1);
    });

    test('affiche une erreur puis réussit après « Réessayer »', () async {
      var fail = true;
      final vm = _vm(
        ApiShopRepository(
          baseUrl: 'http://api',
          client: MockClient((_) async => fail ? http.Response('boom', 500) : _page([_product('a')], 1)),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await vm.load();
      expect(vm.error, isNotNull);
      expect(vm.ready, isFalse);
      fail = false;
      await vm.load();
      expect(vm.error, isNull);
      expect(vm.products.length, 1);
    });

    test('garde le catalogue affiché si une actualisation échoue', () async {
      var fail = false;
      final vm = _vm(
        ApiShopRepository(
          baseUrl: 'http://api',
          client: MockClient((_) async => fail ? http.Response('boom', 500) : _page([_product('a')], 1)),
        ),
      );
      await vm.load();
      fail = true;
      await vm.load();
      expect(vm.error, isNull);
      expect(vm.products.length, 1);
    });
  });
}
