/// Module Adoption — annonces enregistrées dans SQLite pour être consultées hors ligne.
///
/// À chaque chargement réussi de la liste, les annonces reçues du serveur remplacent
/// celles de la table. Sans réseau, la liste est relue depuis la table.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';

class AdoptionLocalStore {
  const AdoptionLocalStore();

  static const table = 'adoption_cache';

  static const createTable = '''
    CREATE TABLE adoption_cache (
      id TEXT PRIMARY KEY,
      position INTEGER NOT NULL,
      species TEXT,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )''';

  /// Remplace les annonces enregistrées (DELETE puis INSERT dans une transaction).
  Future<void> saveAll(List<Map<String, dynamic>> listings) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        await txn.delete(table);
        for (var i = 0; i < listings.length; i++) {
          final json = listings[i];
          await txn.insert(table, {
            'id': '${json['id']}',
            'position': i,
            'species': json['species']?.toString(),
            'json': jsonEncode(json),
            'cached_at': now,
          });
        }
      }),
    );
  }

  /// Annonces enregistrées, dans l'ordre reçu ; [species] = valeur API (ex. `DOG`).
  Future<List<Map<String, dynamic>>> readAll({String? species}) async {
    final rows = await AppDatabase.run(
      (db) => species == null
          ? db.rawQuery('SELECT json FROM adoption_cache ORDER BY position')
          : db.rawQuery('SELECT json FROM adoption_cache WHERE species = ? ORDER BY position', [species]),
    );
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }

  /// Élément [id] de la liste enregistrée (résumé), ou `null`.
  Future<Map<String, dynamic>?> readOne(String id) async {
    final rows = await AppDatabase.run((db) => db.rawQuery('SELECT json FROM adoption_cache WHERE id = ?', [id]));
    if (rows == null || rows.isEmpty) return null;
    return jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
  }
}
