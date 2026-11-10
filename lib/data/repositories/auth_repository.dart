/// Compte : inscription, connexion, mot de passe oublié, profil et déconnexion.
///
/// L'interface décrit CE QUE l'application peut demander. Deux implémentations :
/// - [MockAuthRepository] simule un serveur (délais, erreurs) pour le sommaire et les tests ;
/// - [ApiAuthRepository] parle au backend Spring Boot (`/api/auth`).
/// Les écrans ne voient que l'interface : on passe de l'une à l'autre dans `Deps`.
///
/// Après une connexion réussie, le dépôt ouvre la [AuthSession] partagée.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:pet_sitter/adoption/api/api_client.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/models/user.dart';

/// Erreur métier lisible, affichée telle quelle à l'utilisateur.
class AuthException implements Exception {
  const AuthException(this.message, {this.code, this.fieldErrors});
  final String message;
  final String? code;

  /// Erreurs par champ renvoyées par la validation du serveur (`email`, `password`…).
  final Map<String, String>? fieldErrors;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<AppUser> signUp({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  });

  Future<AppUser> logIn({required String email, required String password});

  Future<void> signInWith(String provider); // 'apple' | 'google'

  /// Envoie un code à 6 chiffres. Renvoie le délai (secondes) avant de pouvoir en redemander un.
  Future<int> requestPasswordReset(String email);

  Future<void> verifyResetCode({required String email, required String code});

  /// Choisit le nouveau mot de passe et ouvre la session.
  Future<AppUser> resetPassword({required String email, required String code, required String newPassword});

  /// Recharge le profil depuis le serveur (après restauration de la session).
  Future<AppUser> refreshProfile();

  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? phone,
    String? city,
    String? bio,
  });

  Future<void> changePassword({required String currentPassword, required String newPassword});

  Future<AppUser> changeRole(AppRole role);

  /// Photo de profil choisie dans la galerie (JPEG, PNG ou WebP).
  Future<AppUser> changePhoto(Uint8List bytes, String filename);

  /// Retire la photo de profil : les initiales s'affichent de nouveau.
  Future<AppUser> removePhoto();

  Future<void> logOut();
}

// ————————————————————————————————————————————— Démonstration

/// Simule le serveur en mémoire. Code de réinitialisation de démonstration : 123456.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({AuthSession? session, this.latency = const Duration(milliseconds: 1200)})
    : _session = session ?? AuthSession.instance;

  static const demoResetCode = '123456';

  final AuthSession _session;
  final Duration latency;
  final Map<String, ({AppUser user, String password})> _accounts = {};

  Future<void> _wait() => Future.delayed(latency);

  AppUser get _me {
    final user = _session.user;
    if (user == null) throw const AuthException('Connectez-vous pour continuer.', code: 'AUTH_REQUIRED');
    return user;
  }

  Future<AppUser> _open(AppUser user) async {
    await _session.open(token: 'demo-${user.id}', user: user, expiresAt: DateTime.now().add(const Duration(days: 3)));
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  }) async {
    await _wait();
    final key = email.trim().toLowerCase();
    if (key == 'deja@petsitter.tn' || _accounts.containsKey(key)) {
      throw const AuthException(
        'Un compte existe déjà avec cette adresse. Connectez-vous ou réinitialisez votre mot de passe.',
        code: 'EMAIL_ALREADY_USED',
      );
    }
    final user = AppUser(
      id: 'demo-${_accounts.length + 1}',
      firstName: firstName,
      lastName: lastName,
      email: key,
      role: AppRole.owner,
      createdAt: DateTime.now(),
    );
    _accounts[key] = (user: user, password: password);
    return _open(user);
  }

  @override
  Future<AppUser> logIn({required String email, required String password}) async {
    await _wait();
    final key = email.trim().toLowerCase();
    final account = _accounts[key];
    if (account != null) {
      if (account.password != password) {
        throw const AuthException('E-mail ou mot de passe incorrect. Il vous reste 4 tentatives.');
      }
      return _open(account.user);
    }
    // Démonstration : toute adresse est acceptée avec un mot de passe d'au moins 8 caractères.
    if (password.length < 8) {
      throw const AuthException('E-mail ou mot de passe incorrect. Il vous reste 4 tentatives.');
    }
    return _open(AppUser(id: 'demo-leila', firstName: 'Leïla', lastName: 'Ben Salah', email: key, role: AppRole.owner));
  }

  @override
  Future<void> signInWith(String provider) => _wait();

  @override
  Future<int> requestPasswordReset(String email) async {
    await _wait();
    return 60;
  }

  @override
  Future<void> verifyResetCode({required String email, required String code}) async {
    await _wait();
    if (code.trim() != demoResetCode) {
      throw const AuthException('Code incorrect. Il vous reste 4 essais.', code: 'RESET_CODE_INVALID');
    }
  }

  @override
  Future<AppUser> resetPassword({required String email, required String code, required String newPassword}) async {
    await verifyResetCode(email: email, code: code);
    final key = email.trim().toLowerCase();
    final existing = _accounts[key]?.user ??
        AppUser(id: 'demo-reset', firstName: 'Leïla', email: key, role: AppRole.owner);
    _accounts[key] = (user: existing, password: newPassword);
    return _open(existing);
  }

  @override
  Future<AppUser> refreshProfile() async => _me;

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? phone,
    String? city,
    String? bio,
  }) async {
    await _wait();
    final user = _me.copyWith(firstName: firstName, lastName: lastName, phone: phone, city: city, bio: bio);
    await _session.updateUser(user);
    return user;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    await _wait();
    final account = _accounts[_me.email];
    if (account != null && account.password != currentPassword) {
      throw const AuthException('Le mot de passe actuel est incorrect.', code: 'WRONG_PASSWORD');
    }
    if (account != null) _accounts[_me.email] = (user: account.user, password: newPassword);
  }

  @override
  Future<AppUser> changeRole(AppRole role) async {
    final user = _me.copyWith(role: role);
    await _session.updateUser(user);
    return user;
  }

  @override
  Future<AppUser> changePhoto(Uint8List bytes, String filename) async {
    await _wait();
    final user = _me.copyWith(photoUrl: 'data:image/jpeg;base64,${base64Encode(bytes)}');
    await _session.updateUser(user);
    return user;
  }

  @override
  Future<AppUser> removePhoto() async {
    await _wait();
    final me = _me;
    final user = AppUser(
      id: me.id,
      firstName: me.firstName,
      lastName: me.lastName,
      email: me.email,
      role: me.role,
      phone: me.phone,
      city: me.city,
      bio: me.bio,
      createdAt: me.createdAt,
    );
    await _session.updateUser(user);
    return user;
  }

  @override
  Future<void> logOut() => _session.close();
}

// ————————————————————————————————————————————— Backend

/// Implémentation réelle : backend Spring Boot, routes `/api/auth/**`.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({ApiClient? client, AuthSession? session})
    : _api = client ?? ApiClient(),
      _session = session ?? AuthSession.instance;

  final ApiClient _api;
  final AuthSession _session;

  /// Exécute un appel et traduit les erreurs réseau / serveur en [AuthException].
  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on ApiException catch (e) {
      throw AuthException(e.message, code: e.code, fieldErrors: e.fieldErrors);
    }
  }

  Future<AppUser> _openFrom(dynamic json) async {
    final map = json as Map<String, dynamic>;
    final user = AppUser.fromJson(map['user'] as Map<String, dynamic>);
    await _session.open(
      token: map['token'] as String,
      user: user,
      expiresAt: DateTime.tryParse((map['expiresAt'] as String?) ?? ''),
    );
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String firstName,
    String? lastName,
    required String email,
    required String password,
  }) => _call(() async {
    final json = await _api.post('/auth/register', {
      'firstName': firstName,
      'lastName': ?lastName,
      'email': email.trim(),
      'password': password,
    });
    return _openFrom(json);
  });

  @override
  Future<AppUser> logIn({required String email, required String password}) => _call(() async {
    // Un éventuel ancien jeton ne doit pas accompagner la connexion.
    await _session.close();
    final json = await _api.post('/auth/login', {'email': email.trim(), 'password': password});
    return _openFrom(json);
  });

  @override
  Future<void> signInWith(String provider) async {
    final name = provider == 'apple' ? 'Apple' : 'Google';
    throw AuthException(
      'La connexion avec $name n\'est pas encore disponible. Utilisez votre adresse e-mail.',
      code: 'PROVIDER_UNAVAILABLE',
    );
  }

  @override
  Future<int> requestPasswordReset(String email) => _call(() async {
    final json = await _api.post('/auth/forgot-password', {'email': email.trim()});
    return ((json as Map<String, dynamic>)['retryAfterSeconds'] as num?)?.toInt() ?? 60;
  });

  @override
  Future<void> verifyResetCode({required String email, required String code}) =>
      _call(() => _api.post('/auth/verify-reset-code', {'email': email.trim(), 'code': code.trim()}));

  @override
  Future<AppUser> resetPassword({required String email, required String code, required String newPassword}) =>
      _call(() async {
        final json = await _api.post('/auth/reset-password', {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        });
        return _openFrom(json);
      });

  @override
  Future<AppUser> refreshProfile() => _call(() async {
    final user = AppUser.fromJson(await _api.get('/auth/me') as Map<String, dynamic>);
    await _session.updateUser(user);
    return user;
  });

  @override
  Future<AppUser> updateProfile({
    required String firstName,
    String? lastName,
    String? phone,
    String? city,
    String? bio,
  }) => _call(() async {
    final json = await _api.put('/auth/me', {
      'firstName': firstName.trim(),
      'lastName': lastName?.trim(),
      'phone': phone?.trim(),
      'city': city?.trim(),
      'photoUrl': _session.user?.photoUrl,
      'bio': bio?.trim(),
    });
    final user = AppUser.fromJson(json as Map<String, dynamic>);
    await _session.updateUser(user);
    return user;
  });

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) => _call(() async {
    final json = await _api.put('/auth/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    // L'ancien jeton est invalidé par le serveur : on garde le nouveau.
    await _openFrom(json);
  });

  @override
  Future<AppUser> changeRole(AppRole role) => _call(() async {
    final json = await _api.put('/auth/me/role', {'role': role.apiValue});
    return _openFrom(json);
  });

  @override
  Future<AppUser> changePhoto(Uint8List bytes, String filename) => _call(() async {
    final json = await _api.upload('/auth/me/photo', bytes, filename);
    final user = AppUser.fromJson(json as Map<String, dynamic>);
    await _session.updateUser(user);
    return user;
  });

  @override
  Future<AppUser> removePhoto() => _call(() async {
    final json = await _api.delete('/auth/me/photo');
    final user = AppUser.fromJson(json as Map<String, dynamic>);
    await _session.updateUser(user);
    return user;
  });

  @override
  Future<void> logOut() => _session.close();
}
