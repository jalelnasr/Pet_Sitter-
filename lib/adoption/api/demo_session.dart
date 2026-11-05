/// Session temporaire de démonstration.
///
/// Le vrai module Utilisateur et l'authentification ne sont pas encore
/// implémentés. En attendant, l'application utilise trois comptes synthétiques
/// et transmet leur identifiant dans l'en-tête `X-Demo-User-Id`.
library;

import 'package:flutter/foundation.dart';

enum UserRole { owner, petsitter, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.owner => 'Propriétaire',
    UserRole.petsitter => 'Pet-sitter',
    UserRole.admin => 'Administrateur',
  };

  String get apiValue => switch (this) {
    UserRole.owner => 'OWNER',
    UserRole.petsitter => 'PETSITTER',
    UserRole.admin => 'ADMIN',
  };
}

class DemoUser {
  const DemoUser({
    required this.id,
    required this.firstName,
    required this.email,
    required this.role,
  });

  final String id;
  final String firstName;
  final String email;
  final UserRole role;

  String get initials => firstName.trim().isEmpty
      ? '?'
      : firstName.trim().substring(0, 1).toUpperCase();

  String get shortLabel => '$firstName · ${role.apiValue}';
}

/// Comptes de test autorisés par le backend.
class DemoUsers {
  DemoUsers._();

  static const owner = DemoUser(
    id: 'OWNER_DEMO',
    firstName: 'Amira',
    email: 'amira@petsitter.test',
    role: UserRole.owner,
  );

  static const petsitter = DemoUser(
    id: 'PETSITTER_DEMO',
    firstName: 'Sami',
    email: 'sami@petsitter.test',
    role: UserRole.petsitter,
  );

  static const admin = DemoUser(
    id: 'ADMIN_DEMO',
    firstName: 'Admin',
    email: 'admin@petsitter.test',
    role: UserRole.admin,
  );

  static const all = [owner, petsitter, admin];
}

/// Sélecteur d'utilisateur de démonstration, partagé par tous les écrans.
///
/// Les écrans écoutent ce [ChangeNotifier] et rechargent leurs données quand
/// l'utilisateur change.
class DemoSessionProvider extends ChangeNotifier {
  DemoSessionProvider._();

  static final DemoSessionProvider instance = DemoSessionProvider._();

  DemoUser _current = DemoUsers.owner;

  DemoUser get currentUser => _current;
  String get currentUserId => _current.id;
  UserRole get role => _current.role;
  bool get isAdmin => _current.role == UserRole.admin;
  bool get isPetsitter => _current.role == UserRole.petsitter;
  bool get isOwner => _current.role == UserRole.owner;
  bool get canAdopt => _current.role != UserRole.admin;

  void select(DemoUser user) {
    if (user.id == _current.id) return;
    _current = user;
    notifyListeners();
  }

  void selectById(String id) {
    for (final user in DemoUsers.all) {
      if (user.id == id) {
        select(user);
        return;
      }
    }
  }
}
