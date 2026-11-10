/// Pages de détail (une annonce, un événement, un pet sitter) enregistrées dans SQLite.
///
/// Chaque fiche ouverte en ligne est gardée ; hors ligne, elle se rouvre telle quelle.
/// Une seule table pour tous les modules : la colonne `module` les distingue.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class DetailsCacheStore {
  const DetailsCacheStore();

  static const table = 'details_cache';

  /// Modules qui gardent leurs fiches (valeurs de la colonne `module`).
  static const adoption = 'adoption';
  static const events = 'events';
  static const sitters = 'sitters';

  static const createTable = '''
    CREATE TABLE IF NOT EXISTS details_cache (
      module TEXT NOT NULL,
      id TEXT NOT NULL,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL,
      PRIMARY KEY (module, id)
    )''';

  /// Ajoute ou remplace la fiche [id] du [module].
  Future<void> save(String module, String id, Map<String, dynamic> json) async {
    await AppDatabase.run(
      (db) => db.insert(table, {
        'module': module,
        'id': id,
        'json': jsonEncode(json),
        'cached_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace),
    );
  }

  /// Fiche enregistrée, ou `null` si elle n'a jamais été ouverte en ligne.
  Future<Map<String, dynamic>?> read(String module, String id) async {
    final rows = await AppDatabase.run(
      (db) => db.rawQuery('SELECT json FROM details_cache WHERE module = ? AND id = ?', [module, id]),
    );
    if (rows == null || rows.isEmpty) return null;
    return jsonDecode(rows.first['json'] as String) as Map<String, dynamic>;
  }
}
