/// Base SQLite locale de l'application (package sqflite), partagée par tous les modules.
///
/// Un seul fichier `lamma_pets.db` sur le téléphone. Chaque module déclare sa table
/// dans son propre fichier (ex. `AdoptionLocalStore.createTable`) et l'ajoute à [_tables].
///
/// | Module            | Table(s)                         | Usage                                   |
/// |-------------------|----------------------------------|-----------------------------------------|
/// | Utilisateur       | `session`                        | rester connecté après fermeture de l'app |
/// | Boutique          | `products_cache`, `cart_items`   | catalogue hors ligne, panier enregistré |
/// | Adoption          | `adoption_cache`                 | annonces consultables hors ligne        |
/// | Événements        | `events_cache`                   | événements consultables hors ligne      |
/// | Garde (sitters)   | `sitters_cache`                  | pet sitters consultables hors ligne     |
/// | Messagerie        | `conversations_cache`, `messages_cache` | discussions lisibles hors ligne  |
///
/// SQLite n'existe pas dans un navigateur : sur le web (et dans les tests de widgets),
/// [database] renvoie `null` et chaque module continue sans stockage local.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pet_sitter/adoption/adoption_local_store.dart';
import 'package:pet_sitter/data/local/message_local_store.dart';
import 'package:pet_sitter/data/local/session_sqlite_store.dart';
import 'package:pet_sitter/data/local/shop_local_store.dart';
import 'package:pet_sitter/events/event_local_store.dart';
import 'package:pet_sitter/petsitter/petsitter_local_store.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static const fileName = 'lamma_pets.db';
  static const version = 1;

  /// Instructions `CREATE TABLE` de tous les modules.
  static const _tables = [
    SessionSqliteStore.createTable,
    ShopLocalStore.createProductsTable,
    ShopLocalStore.createCartTable,
    AdoptionLocalStore.createTable,
    EventLocalStore.createTable,
    SitterLocalStore.createTable,
    MessageLocalStore.createConversationsTable,
    MessageLocalStore.createMessagesTable,
  ];

  static Future<Database?>? _opening;
  static DatabaseFactory? _factory;
  static String? _path;

  /// Base ouverte une seule fois (connexion partagée), ou `null` si SQLite est indisponible.
  static Future<Database?> get database => _opening ??= _open();

  static bool get _supported => _factory != null || (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST'));

  static Future<Database?> _open() async {
    if (!_supported) return null;
    try {
      final factory = _factory ?? databaseFactory;
      final path = _path ?? p.join(await factory.getDatabasesPath(), fileName);
      return await factory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onCreate: (db, _) async {
            final batch = db.batch();
            for (final sql in _tables) {
              batch.execute(sql);
            }
            await batch.commit(noResult: true);
          },
        ),
      );
    } catch (e) {
      debugPrint('SQLite indisponible : $e');
      return null;
    }
  }

  /// Exécute [action] sur la base ; ne fait jamais échouer l'écran appelant.
  static Future<T?> run<T>(Future<T> Function(Database db) action) async {
    try {
      final db = await database;
      return db == null ? null : await action(db);
    } catch (e) {
      debugPrint('Erreur SQLite : $e');
      return null;
    }
  }

  /// Tests unitaires : base SQLite en mémoire (sqflite_common_ffi).
  @visibleForTesting
  static Future<void> useForTests(DatabaseFactory factory, {String path = inMemoryDatabasePath}) async {
    await close();
    _factory = factory;
    _path = path;
  }

  static Future<void> close() async {
    final db = await _opening;
    _opening = null;
    await db?.close();
  }
}
