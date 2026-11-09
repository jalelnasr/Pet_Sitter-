// Connexion, commande et administration, avec un faux client HTTP.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart' show Color, IconData;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/data/repositories/admin_repository.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/data/repositories/order_repository.dart';
import 'package:pet_sitter/data/sources/api_client.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/admin_view_model.dart';
import 'package:pet_sitter/view_models/orders_view_model.dart';
import 'package:pet_sitter/view_models/shop_view_model.dart';

const _delivery = DeliveryAddress(recipient: 'Sami', phone: '20000000', address: 'Rue du Lac', city: 'La Marsa');

Map<String, dynamic> _order({String status = 'CONFIRMED', int id = 1}) => {
  'id': id,
  'number': 'PS-${10000 + id}',
  'userId': 'u1',
  'status': status,
  'paymentMethod': 'CASH',
  'paymentStatus': status == 'DELIVERED' ? 'PAID' : 'PENDING',
  'subtotal': 98,
  'shipping': 0,
  'total': 98,
  'itemCount': 2,
  'recipient': 'Sami',
  'phone': '20000000',
  'address': 'Rue du Lac',
  'city': 'La Marsa',
  'createdAt': '2026-10-31T14:00:00Z',
  'items': [
    {
      'productId': 'croq',
      'productName': 'Croquettes stérilisé',
      'optionId': 7,
      'optionLabel': '2 kg',
      'unitPrice': 49,
      'quantity': 2,
      'lineTotal': 98,
    },
  ],
  'history': [
    {'status': 'CONFIRMED', 'changedAt': '2026-10-31T14:00:00Z'},
  ],
};

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(utf8.encode(jsonEncode(body)), status);

const _product = Product(
  id: 'croq',
  name: 'Croquettes',
  brand: 'Félin+',
  category: ShopCategory.nourriture,
  species: [Species.chat],
  options: [ProductOption('2 kg', 49, id: 7, stock: 3), ProductOption('4 kg', 89, id: 8, stock: 0)],
  rating: 4,
  reviews: 1,
  kind: PackKind.bag,
  color: Color(0xFF0F5534),
  tint: Color(0xFFE3F1E7),
  icon: IconData(1),
  description: 'D',
  details: {},
);

void main() {
  test('un jeton expiré ferme la session', () async {
    final session = AuthSession.isolated();
    await session.open(
      token: 'vieux',
      user: const AppUser(id: 'u', firstName: 'S', email: 'e', role: AppRole.owner),
    );
    final api = ApiClient(baseUrl: 'http://api', session: session, client: MockClient((_) async => _json({}, 401)));
    await expectLater(api.get('/orders/me'), throwsA(isA<ApiException>()));
    expect(session.isAuthenticated, isFalse);
  });

  test('erreurs du backend commun : message et champs lisibles', () async {
    final api = ApiClient(
      baseUrl: 'http://api',
      session: AuthSession.isolated(),
      client: MockClient(
        (_) async => _json({
          'status': 400,
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid request payload.',
          'fieldErrors': {'phone': 'Numéro de téléphone invalide.'},
        }, 400),
      ),
    );
    await expectLater(
      api.post('/orders', {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Numéro de téléphone invalide.')),
    );
  });

  group('Commande', () {
    CartRepository cartWithItem() => CartRepository(demo: false)..add(_product, _product.options.first, qty: 2);

    test('envoie le format et la quantité, jamais le prix, puis vide le panier', () async {
      late Map<String, dynamic> sent;
      final session = AuthSession.isolated();
      await session.open(
        token: 'j',
        user: const AppUser(id: 'u', firstName: 'S', email: 'e', role: AppRole.owner),
      );
      final orders = ApiOrderRepository(
        ApiClient(
          baseUrl: 'http://api',
          session: session,
          client: MockClient((r) async {
            sent = jsonDecode(r.body) as Map<String, dynamic>;
            return _json(_order(), 201);
          }),
        ),
      );
      final cart = cartWithItem()..deliveryAddress = _delivery;
      final vm = CartViewModel(cart, orders: orders, session: session);
      final order = await vm.order();
      expect(sent['items'], [
        {'optionId': 7, 'quantity': 2},
      ]);
      expect(sent['payment'], 'CASH');
      expect(sent['city'], 'La Marsa');
      expect(jsonEncode(sent).contains('price'), isFalse);
      expect(order!.number, 'PS-10001');
      expect(order.lines.single.productName, 'Croquettes stérilisé');
      expect(vm.isEmpty, isTrue);
    });

    test('stock insuffisant : message affiché et panier conservé', () async {
      final session = AuthSession.isolated();
      final orders = ApiOrderRepository(
        ApiClient(
          baseUrl: 'http://api',
          session: session,
          client: MockClient((_) async => _json({'detail': 'Stock insuffisant.'}, 409)),
        ),
      );
      final cart = cartWithItem()..deliveryAddress = _delivery;
      final vm = CartViewModel(cart, orders: orders, session: session);
      expect(await vm.order(), isNull);
      expect(vm.orderError, 'Stock insuffisant.');
      expect(vm.isEmpty, isFalse);
    });

    test('il faut se connecter et donner une adresse, et la carte est masquée', () async {
      final session = AuthSession.isolated();
      final orders = ApiOrderRepository(ApiClient(baseUrl: 'http://api', session: session));
      final vm = CartViewModel(cartWithItem(), orders: orders, session: session);
      expect(vm.needsLogin, isTrue);
      expect(vm.cardAvailable, isFalse);
      expect(vm.address, isNull);
      expect(await vm.order(), isNull);
      await session.open(
        token: 'j',
        user: const AppUser(id: 'u', firstName: 'S', email: 'e', role: AppRole.owner),
      );
      expect(vm.needsLogin, isFalse);
    });

    test('un produit épuisé ne s\'ajoute pas, et la quantité suit le stock', () {
      final cart = CartRepository(demo: false);
      final vm = ProductViewModel(_product, cart);
      expect(vm.option.label, '2 kg');
      expect(vm.maxQty, 3);
      vm.setOption(_product.options.last);
      expect(vm.canAdd, isFalse);
      expect(_product.soldOut, isFalse);
    });
  });

  group('Mes commandes', () {
    test('liste puis annule', () async {
      var status = 'CONFIRMED';
      final vm = MyOrdersViewModel(
        ApiOrderRepository(
          ApiClient(
            baseUrl: 'http://api',
            session: AuthSession.isolated(),
            client: MockClient((r) async {
              if (r.url.path.endsWith('/cancel')) {
                status = 'CANCELLED';
                return _json(_order(status: status));
              }
              return _json({
                'items': [_order(status: status)],
                'totalPages': 1,
              });
            }),
          ),
        ),
      );
      await vm.load();
      expect(vm.items.single.cancellable, isTrue);
      expect(await vm.cancel(vm.items.single), isNull);
      expect(vm.items.single.status, OrderStatus.cancelled);
      expect(vm.items.single.cancellable, isFalse);
    });
  });

  group('Admin', () {
    test('les statuts suivants sont ceux du serveur', () {
      expect(OrderStatus.confirmed.next, [OrderStatus.preparing, OrderStatus.cancelled]);
      expect(OrderStatus.preparing.next, [OrderStatus.shipped, OrderStatus.cancelled]);
      expect(OrderStatus.shipped.next, [OrderStatus.delivered]);
      expect(OrderStatus.delivered.next, isEmpty);
    });

    test('change le statut et filtre', () async {
      final calls = <String>[];
      final vm = AdminOrdersViewModel(
        ApiAdminRepository(
          ApiClient(
            baseUrl: 'http://api',
            session: AuthSession.isolated(),
            client: MockClient((r) async {
              calls.add('${r.method} ${r.url.path}?${r.url.queryParameters['status'] ?? ''}${r.body}');
              return r.method == 'PATCH'
                  ? _json(_order(status: 'PREPARING'))
                  : _json({
                      'items': [_order()],
                      'totalPages': 1,
                    });
            }),
          ),
        ),
      );
      await vm.load();
      expect(await vm.setStatus(vm.items.single, OrderStatus.preparing), isNull);
      expect(calls, contains('PATCH /admin/orders/1/status?{"status":"PREPARING"}'));
      vm.setFilter(OrderStatus.shipped);
      await vm.load();
      expect(calls.last, startsWith('GET /admin/orders?SHIPPED'));
    });

    test('le formulaire crée un produit au format attendu par le serveur', () async {
      late Map<String, dynamic> sent;
      var uploads = 0;
      final vm = ProductFormViewModel(
        ApiAdminRepository(
          ApiClient(
            baseUrl: 'http://api',
            session: AuthSession.isolated(),
            client: MockClient((r) async {
              if (r.url.path.endsWith('/product-images')) {
                uploads++;
                expect(r.headers['content-type'], startsWith('multipart/form-data'));
                return _json({'url': '/api/images/a.png'}, 201);
              }
              sent = jsonDecode(r.body) as Map<String, dynamic>;
              return _json({}, 201);
            }),
          ),
        ),
        null,
      );
      expect(await vm.save(), 'Choisissez au moins une espèce.');
      vm
        ..name = 'Pâtée été chat'
        ..brand = 'Félin+'
        ..description = 'D'
        ..toggleSpecies(Species.chat);
      vm.options.first
        ..label = '85 g'
        ..price = '3'
        ..stock = '0';
      expect(await vm.save(), 'Ajoutez une photo du produit.');
      expect(uploads, 0);
      expect(vm.setImage(Uint8List(5 * 1024 * 1024 + 1), 'grosse.png'), 'La photo dépasse 5 Mo.');
      expect(vm.setImage(Uint8List.fromList([1, 2, 3]), 'a.png'), isNull);
      expect(await vm.save(), isNull);
      expect(uploads, 1);
      expect(sent['id'], 'patee-ete-chat');
      final p = sent['product'] as Map<String, dynamic>;
      expect(p['species'], ['chat']);
      expect(p['options'], [
        {'label': '85 g', 'price': 3, 'stock': 0},
      ]);
      expect(p['imageUrl'], '/api/images/a.png');
      expect(p['color'], '#0F5534');
      expect(p['icon'], 'pawPrint');
      expect(p['oldPrice'], isNull);
    });

    test('la version de démonstration explique qu\'il faut le backend', () async {
      final vm = AdminProductsViewModel(MockAdminRepository());
      await vm.load();
      expect(vm.error, contains('backend'));
    });
  });

  test('démonstration : commande en mémoire', () async {
    final orders = MockOrderRepository();
    final placed = await orders.place(
      lines: [CartLine(_product, _product.options.first, 2)],
      payment: 'cash',
      delivery: _delivery,
    );
    expect(placed.total, 98);
    expect((await orders.mine()).single.id, placed.id);
    expect((await orders.cancel(placed.id)).status, OrderStatus.cancelled);
  });
}
