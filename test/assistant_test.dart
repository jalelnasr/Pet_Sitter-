// Assistant d'achat, avec un faux client HTTP.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/assistant_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/data/sources/session.dart';
import 'package:pet_sitter/view_models/assistant_view_model.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

Map<String, dynamic> _product({int stock = 5}) => {
  'id': 'croq',
  'name': 'Croquettes stérilisé',
  'brand': 'Félin+',
  'category': 'nourriture',
  'species': ['chat'],
  'options': [
    {'id': 7, 'label': '2 kg', 'price': 49, 'stock': stock},
  ],
  'rating': 0,
  'reviews': 0,
  'packKind': 'bag',
  'color': '#0F5534',
  'tint': '#E3F1E7',
  'icon': 'cat',
  'imageUrl': null,
  'description': 'D',
  'details': [],
  'oldPrice': null,
  'badge': null,
  'active': true,
};

AssistantViewModel _vm(MockClient client, {CartRepository? cart, Session? session}) {
  final s = session ?? Session();
  return AssistantViewModel(
    ApiAssistantRepository(ApiClient(baseUrl: 'http://api', session: s, client: client)),
    cart ?? CartRepository(demo: false),
    s,
  );
}

void main() {
  test('pose la question et ajoute le produit proposé au panier', () async {
    final cart = CartRepository(demo: false);
    late Map<String, dynamic> sent;
    final vm = _vm(
      MockClient((r) async {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return _json({
          'message': 'Voici ce qu\'il lui faut.',
          'demo': false,
          'recommendations': [
            {'product': _product(), 'reason': 'Adaptées aux chats stérilisés.'},
          ],
        });
      }),
      cart: cart,
    );
    await vm.ask('  Mon chat stérilisé  ');
    expect(sent, {'question': 'Mon chat stérilisé'});
    expect(vm.reply!.message, 'Voici ce qu\'il lui faut.');
    expect(vm.reply!.picks.single.reason, 'Adaptées aux chats stérilisés.');
    expect(vm.reply!.demo, isFalse);
    vm.addToCart(vm.reply!.picks.single.product);
    expect(cart.lines.single.option.id, 7);
  });

  test('assistant indisponible : message clair, sans plantage', () async {
    final vm = _vm(MockClient((_) async => _json({'detail': 'L\'assistant est indisponible.'}, 503)));
    await vm.ask('Mon chat');
    expect(vm.error, 'L\'assistant est indisponible.');
    expect(vm.reply, isNull);
    expect(vm.asking, isFalse);
  });

  test('réponse illisible : message clair', () async {
    final vm = _vm(MockClient((_) async => _json({'message': 'x'})));
    await vm.ask('Mon chat');
    expect(vm.error, contains('illisible'));
  });

  test('une question vide n\'appelle pas le serveur', () async {
    var calls = 0;
    final vm = _vm(
      MockClient((_) async {
        calls++;
        return _json({});
      }),
    );
    await vm.ask('   ');
    expect(calls, 0);
  });

  test('un produit épuisé n\'est pas ajouté, et il faut un compte', () async {
    final cart = CartRepository(demo: false);
    final vm = _vm(
      MockClient(
        (_) async => _json({
          'message': 'm',
          'demo': false,
          'recommendations': [
            {'product': _product(stock: 0), 'reason': 'r'},
          ],
        }),
      ),
      cart: cart,
    );
    expect(vm.needsLogin, isTrue);
    await vm.ask('Mon chat');
    vm.addToCart(vm.reply!.picks.single.product);
    expect(cart.lines, isEmpty);
  });
}
