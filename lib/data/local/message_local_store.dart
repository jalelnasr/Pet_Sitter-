/// Module Messagerie — conversations et messages enregistrés dans SQLite.
///
/// Les discussions déjà ouvertes restent lisibles sans réseau. L'envoi d'un message
/// demande toujours le serveur.
library;

import 'dart:convert';

import 'package:pet_sitter/data/local/app_database.dart';
import 'package:sqflite/sqflite.dart';

class MessageLocalStore {
  const MessageLocalStore();

  static const createConversationsTable = '''
    CREATE TABLE conversations_cache (
      id TEXT PRIMARY KEY,
      position INTEGER NOT NULL,
      json TEXT NOT NULL,
      cached_at INTEGER NOT NULL
    )''';

  static const createMessagesTable = '''
    CREATE TABLE messages_cache (
      id TEXT PRIMARY KEY,
      conversation_id TEXT NOT NULL,
      sent_at TEXT,
      json TEXT NOT NULL
    )''';

  /// Remplace la liste des conversations.
  Future<void> saveConversations(List<Map<String, dynamic>> conversations) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await AppDatabase.run(
      (db) => db.transaction((txn) async {
        await txn.delete('conversations_cache');
        for (var i = 0; i < conversations.length; i++) {
          await txn.insert('conversations_cache', {
            'id': '${conversations[i]['id']}',
            'position': i,
            'json': jsonEncode(conversations[i]),
            'cached_at': now,
          });
        }
      }),
    );
  }

  Future<List<Map<String, dynamic>>> readConversations() async {
    final rows = await AppDatabase.run((db) => db.rawQuery('SELECT json FROM conversations_cache ORDER BY position'));
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }

  /// Ajoute ou met à jour les messages d'une conversation.
  Future<void> saveMessages(String conversationId, List<Map<String, dynamic>> messages) async {
    await AppDatabase.run((db) async {
      final batch = db.batch();
      for (final json in messages) {
        batch.insert('messages_cache', {
          'id': '${json['id']}',
          'conversation_id': conversationId,
          'sent_at': json['sentAt']?.toString(),
          'json': jsonEncode(json),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Map<String, dynamic>>> readMessages(String conversationId) async {
    final rows = await AppDatabase.run(
      (db) =>
          db.rawQuery('SELECT json FROM messages_cache WHERE conversation_id = ? ORDER BY sent_at', [conversationId]),
    );
    return [for (final row in rows ?? const []) jsonDecode(row['json'] as String) as Map<String, dynamic>];
  }
}
