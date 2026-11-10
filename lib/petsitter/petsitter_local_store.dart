/// Module Garde — pet sitters enregistrés dans SQLite pour être consultés hors ligne.
///
/// À chaque recherche réussie, les sitters reçus sont ajoutés ou mis à jour dans la table
/// (INSERT OR REPLACE). Sans réseau, la recherche se fait dans la table.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SitterLocalStore {
  const SitterLocalStore();

  static const table = 'sitters_cache';

  static const createTable = '''
    CREATE TABLE sitters_cache (
      id TEXT PRIMARY KEY,
      name TEXT,
      governorate TEXT,
      rating REAL,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )''';

  /// Ajoute ou met à jour les sitters reçus du serveur.
  Future<void> saveAll(List<Map<String, dynamic>> sitters) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppDatabase.run((db) async {
      final batch = db.batch();
      for (final json in sitters) {
        batch.insert(table, {
          'id': '${json['id']}',
          'name': json['fullName']?.toString(),
          'governorate': json['governorate']?.toString(),
          'rating': (json['averageRating'] as num?)?.toDouble(),
          'json': jsonEncode(json),
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  /// Remplace tout le cache (recherche sans filtre) : les sitters retirés du serveur disparaissent.
  Future<void> replaceAll(List<Map<String, dynamic>> sitters) async {
    await AppDatabase.run((db) => db.delete(table));
    await saveAll(sitters);
  }

  /// Sitters enregistrés, les mieux notés d'abord ; filtres facultatifs.
  Future<List<Map<String, dynamic>>> readAll({String? search, String? governorate}) async {
    final where = <String>[];
    final args = <Object>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (governorate != null && governorate.trim().isNotEmpty) {
      where.add('governorate = ?');
      args.add(governorate.trim());
    }
    final sql =
        'SELECT json FROM sitters_cache${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} '
        'ORDER BY rating DESC, name';
    final rows = await AppDatabase.run((db) => db.rawQuery(sql, args));
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }

  /// Élément [id] de la liste enregistrée (résumé), ou `null`.
  Future<Map<String, dynamic>?> readOne(String id) async {
    final rows = await AppDatabase.run((db) => db.rawQuery('SELECT json FROM sitters_cache WHERE id = ?', [id]));
    if (rows == null || rows.isEmpty) return null;
    return jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
  }
}
