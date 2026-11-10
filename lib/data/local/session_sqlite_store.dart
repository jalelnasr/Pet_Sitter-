/// Module Utilisateur — la session (jeton + compte connecté) enregistrée dans SQLite.
///
/// Remplace le stockage clé/valeur sur Android et iOS : l'utilisateur reste connecté
/// quand il ferme puis rouvre l'application. Une seule ligne (id = 1).
library;

import 'dart:convert';

import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/local/app_database.dart';
import 'package:pet_sitter/models/user.dart';
import 'package:sqflite/sqflite.dart';

class SessionSqliteStore implements SessionStore {
  static const table = 'session';

  static const createTable = '''
    CREATE TABLE session (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      token TEXT NOT NULL,
      expires_at TEXT,
      user_id TEXT NOT NULL,
      email TEXT NOT NULL,
      role TEXT NOT NULL,
      user_json TEXT NOT NULL,
      saved_at INTEGER NOT NULL
    )''';

  @override
  Future<StoredSession?> read() async {
    final rows = await AppDatabase.run(
      (db) => db.rawQuery('SELECT token, expires_at, user_json FROM session WHERE id = 1'),
    );
    if (rows == null || rows.isEmpty) return null;
    try {
      final row = rows.first;
      return StoredSession(
        token: row['token'] as String,
        expiresAt: DateTime.tryParse((row['expires_at'] as String?) ?? ''),
        user: AppUser.fromJson(jsonDecode(row['user_json'] as String) as Map<String, dynamic>),
      );
    } catch (_) {
      // Ligne illisible (ancienne version) : on repart d'une session vide.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    final user = session.user.toJson();
    await AppDatabase.run(
      (db) => db.insert(table, {
        'id': 1,
        'token': session.token,
        'expires_at': session.expiresAt?.toIso8601String(),
        'user_id': '${user['id']}',
        'email': '${user['email']}',
        'role': '${user['role']}',
        'user_json': jsonEncode(user),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace),
    );
  }

  /// Déconnexion : efface la session et les messages privés enregistrés sur le téléphone.
  @override
  Future<void> clear() async {
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        await txn.delete(table);
        await txn.delete('conversations_cache');
        await txn.delete('messages_cache');
      }),
    );
  }
}
