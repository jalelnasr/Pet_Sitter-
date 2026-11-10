/// Module Boutique — catalogue hors ligne et panier enregistré dans SQLite.
///
/// - `products_cache` : produits reçus du serveur, relus sans réseau.
/// - `cart_items` : lignes du panier (compte, produit, format, quantité). Chaque compte
///   retrouve son propre panier quand il rouvre l'application ; `user_id` vide = sans compte.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';

/// Ligne de panier relue depuis SQLite (avec le produit grâce à une jointure).
class StoredCartLine {
  const StoredCartLine({required this.product, required this.optionLabel, required this.qty});
  final Map<String, dynamic> product;
  final String optionLabel;
  final int qty;
}

class ShopLocalStore {
  const ShopLocalStore();

  static const createProductsTable = '''
    CREATE TABLE products_cache (
      id TEXT PRIMARY KEY,
      position INTEGER NOT NULL,
      name TEXT NOT NULL,
      category TEXT NOT NULL,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )''';

  static const createCartTable = '''
    CREATE TABLE cart_items (
      user_id TEXT NOT NULL DEFAULT '',
      product_id TEXT NOT NULL,
      option_label TEXT NOT NULL,
      qty INTEGER NOT NULL CHECK (qty > 0),
      added_at INTEGER NOT NULL,
      PRIMARY KEY (user_id, product_id, option_label)
    )''';

  /// Version 1 → 2 : ajout du compte dans la clé (les lignes existantes restent « sans compte »).
  static const migrateCartToV2 = [
    'ALTER TABLE cart_items RENAME TO cart_items_v1',
    createCartTable,
    "INSERT INTO cart_items (user_id, product_id, option_label, qty, added_at) "
        "SELECT '', product_id, option_label, qty, added_at FROM cart_items_v1",
    'DROP TABLE cart_items_v1',
  ];

  // ——— Catalogue

  /// Remplace le catalogue enregistré (DELETE puis INSERT dans une transaction).
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        await txn.delete('products_cache');
        for (var i = 0; i < products.length; i++) {
          final json = products[i];
          await txn.insert('products_cache', {
            'id': json['id'] as String,
            'position': i,
            'name': json['name'] as String,
            'category': json['category'] as String,
            'json': jsonEncode(json),
            'cached_at': now,
          });
        }
      }),
    );
  }

  Future<List<Map<String, dynamic>>> readProducts() async {
    final rows = await AppDatabase.run((db) => db.rawQuery('SELECT json FROM products_cache ORDER BY position'));
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }

  // ——— Panier (CRUD)

  /// Ajoute une ligne au panier de [userId], ou augmente sa quantité si le même format y est déjà.
  Future<void> addToCart(String productId, String optionLabel, int qty, {String userId = ''}) async {
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        final updated = await txn.rawUpdate(
          'UPDATE cart_items SET qty = qty + ? WHERE user_id = ? AND product_id = ? AND option_label = ?',
          [qty, userId, productId, optionLabel],
        );
        if (updated == 0) {
          await txn.rawInsert(
            'INSERT INTO cart_items (user_id, product_id, option_label, qty, added_at) VALUES (?, ?, ?, ?, ?)',
            [userId, productId, optionLabel, qty, DateTime.now().millisecondsSinceEpoch],
          );
        }
      }),
    );
  }

  /// Change la quantité d'une ligne du panier de [userId] ; 0 ou moins la supprime.
  Future<void> updateQty(String productId, String optionLabel, int qty, {String userId = ''}) async {
    const where = 'user_id = ? AND product_id = ? AND option_label = ?';
    final args = [userId, productId, optionLabel];
    await AppDatabase.run(
      (db) => qty <= 0
          ? db.delete('cart_items', where: where, whereArgs: args)
          : db.update('cart_items', {'qty': qty}, where: where, whereArgs: args),
    );
  }

  /// Vide le panier de [userId] (les paniers des autres comptes restent).
  Future<void> clearCart({String userId = ''}) async {
    await AppDatabase.run((db) => db.delete('cart_items', where: 'user_id = ?', whereArgs: [userId]));
  }

  /// Lignes du panier de [userId] avec leur produit (jointure avec le catalogue enregistré).
  Future<List<StoredCartLine>> readCart({String userId = ''}) async {
    final rows = await AppDatabase.run(
      (db) => db.rawQuery(
        'SELECT c.option_label, c.qty, p.json FROM cart_items c '
        'JOIN products_cache p ON p.id = c.product_id WHERE c.user_id = ? ORDER BY c.added_at',
        [userId],
      ),
    );
    return [
      for (final row in rows ?? const <Map<String, Object?>>[])
        StoredCartLine(
          product: jsonDecode(row['json'] as String) as Map<String, dynamic>,
          optionLabel: row['option_label'] as String,
          qty: row['qty'] as int,
        ),
    ];
  }
}
