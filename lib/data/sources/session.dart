/// Compte connecté et jeton d'accès au backend.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole { owner, petsitter, admin }

extension UserRoleX on UserRole {
  String get api => name.toUpperCase();
  static UserRole fromApi(String s) => UserRole.values.byName(s.toLowerCase());
}

class SessionUser {
  const SessionUser({required this.id, required this.name, required this.email, required this.role});

  factory SessionUser.fromJson(Map<String, dynamic> json) => SessionUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRoleX.fromApi(json['role'] as String),
  );

  final String id;
  final String name;
  final String email;
  final UserRole role;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email, 'role': role.api};
}

class Session extends ChangeNotifier {
  /// [persist] : garde la connexion d'un lancement à l'autre (désactivé en démonstration et en test).
  Session({this.persist = false});

  static const _key = 'session';

  final bool persist;

  String? _token;
  String? get token => _token;

  SessionUser? _user;
  SessionUser? get user => _user;

  bool get isLoggedIn => _token != null;

  Future<void> restore() async {
    if (!persist) return;
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    if (saved == null) return;
    final json = jsonDecode(saved) as Map<String, dynamic>;
    _token = json['token'] as String;
    _user = SessionUser.fromJson(json['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> open(String token, SessionUser user) async {
    _token = token;
    _user = user;
    notifyListeners();
    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({'token': token, 'user': user.toJson()}));
    }
  }

  Future<void> close() async {
    _token = null;
    _user = null;
    notifyListeners();
    if (persist) await (await SharedPreferences.getInstance()).remove(_key);
  }
}
