/// Module Événements — événements enregistrés dans SQLite pour être consultés hors ligne.
///
/// À chaque chargement réussi de la liste complète, les événements reçus remplacent
/// ceux de la table. Sans réseau, la liste est relue depuis la table.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';

class EventLocalStore {
  const EventLocalStore();

  static const table = 'events_cache';

  static const createTable = '''
    CREATE TABLE events_cache (
      id TEXT PRIMARY KEY,
      position INTEGER NOT NULL,
      category TEXT,
      title TEXT,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )''';

  /// Remplace les événements enregistrés (DELETE puis INSERT dans une transaction).
  Future<void> saveAll(List<Map<String, dynamic>> events) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        await txn.delete(table);
        for (var i = 0; i < events.length; i++) {
          final json = events[i];
          await txn.insert(table, {
            'id': '${json['id']}',
            'position': i,
            'category': json['category']?.toString(),
            'title': json['title']?.toString(),
            'json': jsonEncode(json),
            'cached_at': now,
          });
        }
      }),
    );
  }

  /// Événements enregistrés ; [category] = valeur API, [search] = mot du titre.
  Future<List<Map<String, dynamic>>> readAll({String? category, String? search}) async {
    final where = <String>[];
    final args = <Object>[];
    if (category != null) {
      where.add('category = ?');
      args.add(category);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('title LIKE ?');
      args.add('%${search.trim()}%');
    }
    final sql =
        'SELECT json FROM events_cache${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'} ORDER BY position';
    final rows = await AppDatabase.run((db) => db.rawQuery(sql, args));
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }
}
