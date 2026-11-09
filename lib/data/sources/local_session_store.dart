/// Conserve la session sur l'appareil (stockage local de la plateforme).
library;

import 'dart:convert';

import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSessionStore implements SessionStore {
  static const _key = 'petsitter.session.v1';

  @override
  Future<StoredSession?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return StoredSession(
        token: json['token'] as String,
        expiresAt: DateTime.tryParse((json['expiresAt'] as String?) ?? ''),
        user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      );
    } catch (_) {
      // Donnée illisible (ancienne version) : on repart d'une session vide.
      return null;
    }
  }

  @override
  Future<void> write(StoredSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'token': session.token,
        'expiresAt': session.expiresAt?.toIso8601String(),
        'user': session.user.toJson(),
      }),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
