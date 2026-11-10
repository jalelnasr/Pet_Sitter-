// Base SQLite locale (sqflite) : requêtes de chaque module sur une vraie base en mémoire.
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_sitter/adoption/adoption_local_store.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/local/app_database.dart';
import 'package:pet_sitter/data/local/message_local_store.dart';
import 'package:pet_sitter/data/local/session_sqlite_store.dart';
import 'package:pet_sitter/data/local/shop_local_store.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/events/event_local_store.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/petsitter/petsitter_local_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Map<String, dynamic> _product(String id, {String name = 'Croquettes'}) => {
  'id': id,
  'name': name,
  'brand': 'Lamma',
  'category': 'nourriture',
  'species': ['chien'],
  'options': [
    {'id': 1, 'label': '2 kg', 'price': 30, 'stock': 5},
    {'id': 2, 'label': '5 kg', 'price': 60, 'stock': 5},
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

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => AppDatabase.useForTests(databaseFactoryFfi));
  tearDown(AppDatabase.close);

  test('toutes les tables des modules sont créées', () async {
    final db = await AppDatabase.database;
    final rows = await db!.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table'");
    final names = rows.map((r) => r['name']).toSet();
    expect(
      names,
      containsAll([
        'session',
        'products_cache',
        'cart_items',
        'adoption_cache',
        'events_cache',
        'sitters_cache',
        'conversations_cache',
        'messages_cache',
      ]),
    );
  });

  test('utilisateur : la session est écrite, relue puis effacée', () async {
    final store = SessionSqliteStore();
    expect(await store.read(), isNull);
    await store.write(
      StoredSession(
        token: 'jwt',
        expiresAt: DateTime(2030),
        user: const AppUser(id: 'u1', firstName: 'Amira', email: 'a@b.tn', role: AppRole.owner),
      ),
    );
    final back = await store.read();
    expect(back!.token, 'jwt');
    expect(back.user.email, 'a@b.tn');
    expect(back.user.role, AppRole.owner);
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('boutique : panier enregistré (ajout, quantité, suppression) et relu avec son produit', () async {
    const shop = ShopLocalStore();
    await shop.saveProducts([_product('croq'), _product('jouet', name: 'Balle')]);
    expect((await shop.readProducts()).map((p) => p['name']), ['Croquettes', 'Balle']);

    await shop.addToCart('croq', '2 kg', 1);
    await shop.addToCart('croq', '2 kg', 2); // même format : quantité augmentée
    await shop.addToCart('jouet', '5 kg', 1);
    var cart = await shop.readCart();
    expect(cart.map((l) => (l.product['id'], l.qty)), [('croq', 3), ('jouet', 1)]);

    await shop.updateQty('croq', '2 kg', 5);
    await shop.updateQty('jouet', '5 kg', 0); // 0 = supprimé
    cart = await shop.readCart();
    expect(cart.map((l) => (l.product['id'], l.qty)), [('croq', 5)]);

    // Le panier de l'app se recharge depuis SQLite au démarrage.
    final restored = CartRepository(demo: false, store: shop);
    await restored.restore();
    expect(restored.count, 5);
    expect(restored.lines.single.option.label, '2 kg');

    restored.clear();
    await Future<void>.delayed(Duration.zero);
    expect(await shop.readCart(), isEmpty);
  });

  test('adoption : annonces remplacées et filtrées par espèce', () async {
    const store = AdoptionLocalStore();
    await store.saveAll([
      {'id': 1, 'species': 'DOG', 'name': 'Rex'},
      {'id': 2, 'species': 'CAT', 'name': 'Mimi'},
    ]);
    expect((await store.readAll()).map((e) => e['name']), ['Rex', 'Mimi']);
    expect((await store.readAll(species: 'CAT')).single['name'], 'Mimi');
    await store.saveAll([
      {'id': 3, 'species': 'DOG', 'name': 'Max'},
    ]);
    expect((await store.readAll()).single['name'], 'Max');
  });

  test('événements : recherche dans le titre et par catégorie', () async {
    const store = EventLocalStore();
    await store.saveAll([
      {'id': 'e1', 'category': 'WALK', 'title': 'Balade au lac'},
      {'id': 'e2', 'category': 'TRAINING', 'title': 'Atelier dressage'},
    ]);
    expect((await store.readAll(search: 'lac')).single['id'], 'e1');
    expect((await store.readAll(category: 'TRAINING')).single['id'], 'e2');
  });

  test('garde : sitters mis à jour et triés par note', () async {
    const store = SitterLocalStore();
    await store.saveAll([
      {'id': 's1', 'fullName': 'Sami', 'governorate': 'Tunis', 'averageRating': 4.1},
      {'id': 's2', 'fullName': 'Amira', 'governorate': 'Ariana', 'averageRating': 4.9},
    ]);
    await store.saveAll([
      {'id': 's1', 'fullName': 'Sami', 'governorate': 'Tunis', 'averageRating': 5.0},
    ]);
    expect((await store.readAll()).map((s) => s['id']), ['s1', 's2']);
    expect((await store.readAll(governorate: 'Ariana')).single['fullName'], 'Amira');
  });

  test('messagerie : conversations et messages relus, effacés à la déconnexion', () async {
    const store = MessageLocalStore();
    await store.saveConversations([
      {'id': 7, 'subject': 'Garde de Simba'},
    ]);
    await store.saveMessages('7', [
      {'id': 2, 'sentAt': '2026-11-10T10:05:00', 'content': 'Merci'},
      {'id': 1, 'sentAt': '2026-11-10T10:00:00', 'content': 'Bonjour'},
    ]);
    expect((await store.readConversations()).single['subject'], 'Garde de Simba');
    expect((await store.readMessages('7')).map((m) => m['content']), ['Bonjour', 'Merci']);

    await SessionSqliteStore().clear();
    expect(await store.readConversations(), isEmpty);
    expect(await store.readMessages('7'), isEmpty);
  });
}
