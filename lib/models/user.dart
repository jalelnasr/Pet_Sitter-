/// Compte de l'utilisateur connecté et fiches publiques des autres membres.
library;

/// Profil choisi dans l'application (même valeurs que le backend).
enum AppRole { owner, petsitter, admin }

extension AppRoleX on AppRole {
  String get label => switch (this) {
    AppRole.owner => 'Propriétaire',
    AppRole.petsitter => 'Pet sitter',
    AppRole.admin => 'Administrateur',
  };

  String get apiValue => switch (this) {
    AppRole.owner => 'OWNER',
    AppRole.petsitter => 'PETSITTER',
    AppRole.admin => 'ADMIN',
  };

  static AppRole fromApi(String? value) => switch (value) {
    'PETSITTER' => AppRole.petsitter,
    'ADMIN' => AppRole.admin,
    _ => AppRole.owner,
  };
}

/// Utilisateur connecté (profil complet, jamais le mot de passe).
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.email,
    required this.role,
    this.lastName,
    this.phone,
    this.city,
    this.photoUrl,
    this.bio,
    this.createdAt,
  });

  final String id;
  final String firstName;
  final String? lastName;
  final String email;
  final AppRole role;
  final String? phone;
  final String? city;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;

  String get fullName => (lastName == null || lastName!.trim().isEmpty) ? firstName : '$firstName $lastName';

  String get initials {
    final first = firstName.trim().isEmpty ? '' : firstName.trim()[0];
    final last = (lastName ?? '').trim().isEmpty ? '' : lastName!.trim()[0];
    final value = '$first$last'.toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  bool get isPetsitter => role == AppRole.petsitter;
  bool get isAdmin => role == AppRole.admin;

  AppUser copyWith({
    String? firstName,
    String? lastName,
    AppRole? role,
    String? phone,
    String? city,
    String? photoUrl,
    String? bio,
  }) => AppUser(
    id: id,
    email: email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    createdAt: createdAt,
  );

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    firstName: (json['firstName'] as String?) ?? '',
    lastName: json['lastName'] as String?,
    email: (json['email'] as String?) ?? '',
    role: AppRoleX.fromApi(json['role'] as String?),
    phone: json['phone'] as String?,
    city: json['city'] as String?,
    photoUrl: json['photoUrl'] as String?,
    bio: json['bio'] as String?,
    createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'role': role.apiValue,
    'phone': phone,
    'city': city,
    'photoUrl': photoUrl,
    'bio': bio,
    'createdAt': createdAt?.toIso8601String(),
  };
}

/// Fiche publique d'un membre (annuaire, messagerie) : ni e-mail ni téléphone.
class Member {
  const Member({required this.id, required this.fullName, required this.firstName, required this.role, this.photoUrl, this.city});

  final String id;
  final String fullName;
  final String firstName;
  final AppRole role;
  final String? photoUrl;
  final String? city;

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    firstName: (json['firstName'] as String?) ?? '',
    fullName: (json['fullName'] as String?) ?? (json['firstName'] as String?) ?? '',
    role: AppRoleX.fromApi(json['role'] as String?),
    photoUrl: json['photoUrl'] as String?,
    city: json['city'] as String?,
  );
}
