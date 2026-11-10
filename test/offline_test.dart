// Mode hors ligne : migration de la base locale, panier par compte, fiches et filtres
// relus sans réseau, bandeau « Hors ligne ». Base SQLite réelle (en mémoire ou fichier
// temporaire) et faux serveur HTTP (d'abord joignable, puis coupé).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_sitter/adoption/adoption_api_service.dart';
import 'package:pet_sitter/adoption/api/api_client.dart';
import 'package:pet_sitter/core/network/network_status.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/core/widgets/offline_banner.dart';
import 'package:pet_sitter/data/local/app_database.dart';
import 'package:pet_sitter/data/local/details_cache_store.dart';
import 'package:pet_sitter/data/local/shop_local_store.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/events/event_api_service.dart';
import 'package:pet_sitter/events/event_models.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _product(String id) => {
  'id': id,
  'name': 'Croquettes $id',
  'brand': 'Lamma',
  'category': 'nourriture',
  'species': ['chien'],
  'options': [
    {'id': 1, 'label': '2 kg', 'price': 30, 'stock': 5},
  ],
  'rating': 4.5,
  'reviews': 3,
  'packKind': 'bag',
  'color': '#335533',
  'tint': '#EEFFEE',
  'icon': 'dog',
  'description': 'Pour chiens adultes',
  'details': <Map<String, String>>[],
};

Map<String, dynamic> _event(String id, String title, DateTime start, EventStatus status) => {
  'id': id,
  'title': title,
  'category': EventCategory.values.first.apiValue,
  'startDate': start.toIso8601String(),
  'endDate': start.add(const Duration(hours: 2)).toIso8601String(),
  'status': status.apiValue,
  'location': 'La Marsa',
  'description': 'Description complète de $title',
  'maxParticipants': 20,
  'currentParticipants': 3,
};

Map<String, dynamic> _listing(String id, String name, String location) => {
  'id': id,
  'petName': name,
  'species': 'DOG',
  'location': location,
  'age': 2,
};

/// Faux serveur : répond avec [routes] tant que [online] est vrai, sinon connexion impossible.
class _FakeServer {
  _FakeServer(this.routes);
  final Map<String, Object> routes;
  bool online = true;

  ApiClient client() => ApiClient(
    baseUrl: 'http://serveur.test/api',
    client: MockClient((request) async {
      if (!online) throw const SocketException('Connexion impossible');
      final body = routes[request.url.path.replaceFirst('/api', '')];
      if (body == null) return http.Response('{"code":"NOT_FOUND","message":"introuvable"}', 404);
      return http.Response.bytes(utf8.encode(jsonEncode(body)), 200, headers: {'content-type': 'application/json'});
    }),
  );
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    await AppDatabase.useForTests(databaseFactoryFfi);
    NetworkStatus.instance.reset();
  });
  tearDown(AppDatabase.close);

  test('migration : une base de la version 1 passe en version 2 sans perdre le panier', () async {
    final dir = await Directory.systemTemp.createTemp('lamma_db_');
    final path = '${dir.path}${Platform.pathSeparator}v1.db';
    // Base telle que la créait la version 1 de l'application.
    final old = await databaseFactoryFfi.openDatabase(path, options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute(ShopLocalStore.createProductsTable);
        await db.execute('''CREATE TABLE cart_items (
          product_id TEXT NOT NULL, option_label TEXT NOT NULL, qty INTEGER NOT NULL CHECK (qty > 0),
          added_at INTEGER NOT NULL, PRIMARY KEY (product_id, option_label))''');
        await db.insert('cart_items', {'product_id': 'croq', 'option_label': '2 kg', 'qty': 2, 'added_at': 1});
      },
    ));
    await old.close();

    await AppDatabase.useForTests(databaseFactoryFfi, path: path);
    final db = await AppDatabase.database;
    expect(await db!.getVersion(), AppDatabase.version);
    final tables = (await db.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'")).map((r) => r['name']);
    expect(tables, contains('details_cache'));
    expect(tables, isNot(contains('cart_items_v1')));
    final rows = await db.rawQuery('SELECT user_id, product_id, qty FROM cart_items');
    expect(rows.single, {'user_id': '', 'product_id': 'croq', 'qty': 2});
    await AppDatabase.close();
    await dir.delete(recursive: true);
  });

  test('panier : chaque compte a le sien, enregistré dans SQLite', () async {
    const shop = ShopLocalStore();
    await shop.saveProducts([_product('a'), _product('b')]);
    await shop.addToCart('a', '2 kg', 1, userId: 'leila');
    await shop.addToCart('b', '2 kg', 3, userId: 'sami');
    expect((await shop.readCart(userId: 'leila')).map((l) => l.product['id']), ['a']);
    expect((await shop.readCart(userId: 'sami')).single.qty, 3);
    await shop.clearCart(userId: 'sami');
    expect(await shop.readCart(userId: 'sami'), isEmpty);
    expect(await shop.readCart(userId: 'leila'), hasLength(1));
  });

  test('panier : changer de compte affiche le panier du nouveau compte', () async {
    const shop = ShopLocalStore();
    await shop.saveProducts([_product('a'), _product('b')]);
    final session = AuthSession.isolated();
    const leila = AppUser(id: 'leila', firstName: 'Leïla', email: 'l@exemple.tn', role: AppRole.owner);
    const sami = AppUser(id: 'sami', firstName: 'Sami', email: 's@exemple.tn', role: AppRole.owner);
    await session.open(token: 't1', user: leila);
    final cart = CartRepository(demo: false, store: shop, session: session);
    final product = Product.fromJson(_product('a'));
    cart.add(product, product.options.first, qty: 2);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await session.close(); // déconnexion
    expect(cart.count, 0);
    await session.open(token: 't2', user: sami);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cart.count, 0); // Sami ne voit pas le panier de Leïla

    await session.open(token: 't3', user: leila);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(cart.count, 2); // Leïla retrouve le sien
    cart.dispose();
  });

  test('événements : fiche et filtres (« à venir », statut) disponibles hors ligne', () async {
    final now = DateTime.now();
    final pending = EventStatus.values.first;
    final other = EventStatus.values.last;
    final past = _event('e1', 'Balade passée', now.subtract(const Duration(days: 3)), pending);
    final future = _event('e2', 'Atelier à venir', now.add(const Duration(days: 3)), other);
    final server = _FakeServer({'/events': [past, future], '/events/e2': future});
    final api = EventApiService(client: server.client());

    await api.fetchEvents(); // en ligne : liste enregistrée
    await api.fetchEvent('e2'); // en ligne : fiche enregistrée
    expect(NetworkStatus.instance.offline, isFalse);

    server.online = false;
    expect((await api.fetchEvents(upcomingOnly: true)).map((e) => e.id), ['e2']);
    expect((await api.fetchEvents(status: pending)).map((e) => e.id), ['e1']);
    expect((await api.fetchEvent('e2')).description, contains('Atelier'));
    // Jamais ouverte en ligne : rouverte depuis son résumé dans la liste.
    expect((await api.fetchEvent('e1')).title, 'Balade passée');
    expect(NetworkStatus.instance.offline, isTrue);

    server.online = true;
    await api.fetchEvents();
    expect(NetworkStatus.instance.offline, isFalse);
  });

  test('adoption : fiche rouverte et filtre par lieu hors ligne', () async {
    final server = _FakeServer({
      '/adoption-listings': {
        'content': [_listing('a1', 'Rex', 'La Marsa'), _listing('a2', 'Mimi', 'Sfax')],
      },
    });
    final api = AdoptionApiService(client: server.client());
    await api.fetchListings();

    server.online = false;
    expect((await api.fetchListings(location: 'sfax')).map((p) => p.id), ['a2']);
    expect((await api.fetchListing('a1')).id, 'a1');
    await expectLater(api.fetchListing('inconnue'), throwsA(isA<ApiException>()));
  });

  test('fiches de détail : enregistrées puis relues par module', () async {
    const details = DetailsCacheStore();
    await details.save(DetailsCacheStore.sitters, 's1', {'id': 's1', 'fullName': 'Samira'});
    expect((await details.read(DetailsCacheStore.sitters, 's1'))?['fullName'], 'Samira');
    expect(await details.read(DetailsCacheStore.events, 's1'), isNull);
  });

  test('retour en ligne automatique : le serveur est revérifié tant qu\'il ne répond pas', () async {
    final status = NetworkStatus.instance;
    var serverUp = false;
    var probes = 0;
    status.useProbe(() async {
      probes++;
      if (!serverUp) throw const SocketException('Connexion impossible');
      return true;
    }, every: const Duration(milliseconds: 30));

    status.reportUnreachable(); // câble débranché
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(status.offline, isTrue);
    expect(probes, greaterThan(0));

    serverUp = true; // câble rebranché
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(status.offline, isFalse);
    final after = probes;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(probes, after); // plus de vérification une fois en ligne
  });

  testWidgets('bandeau : « Réessayer » repasse en ligne si le serveur répond', (tester) async {
    final status = NetworkStatus.instance;
    var serverUp = false;
    status.useProbe(() async => serverUp, every: const Duration(hours: 1));
    await tester.pumpWidget(MaterialApp(home: OfflineBanner(status: status, child: const _Counter())));
    status.reportUnreachable();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors ligne'), findsOneWidget); // serveur toujours absent

    serverUp = true;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors ligne'), findsNothing);
    status.reset();
  });

  testWidgets('bandeau « Hors ligne » : apparaît, disparaît, sans perdre l\'état de l\'écran', (tester) async {
    final status = NetworkStatus.instance;
    await tester.pumpWidget(MaterialApp(home: OfflineBanner(status: status, child: const _Counter())));
    expect(find.textContaining('Hors ligne'), findsNothing);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    status.reportUnreachable();
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors ligne'), findsOneWidget);
    expect(find.text('1'), findsOneWidget); // l'écran garde son état

    status.reportReachable();
    await tester.pumpAndSettle();
    expect(find.textContaining('Hors ligne'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _n = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('$_n'),
        ElevatedButton(onPressed: () => setState(() => _n++), child: const Text('+')),
      ],
    ),
  );
}
