import 'package:flutter/material.dart';
import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

enum PetSitterRole {
  owner,
  sitter,
  admin;

  String get label => switch (this) {
    owner => 'Propriétaire',
    sitter => 'Pet Sitter',
    admin => 'Administrateur',
  };

  String get apiRole => switch (this) {
    owner => 'OWNER',
    sitter => 'PETSITTER',
    admin => 'ADMIN',
  };
}

class PetSitterUser {
  const PetSitterUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  final String id;
  final String name;
  final String email;
  final PetSitterRole role;

  String get initials => name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
}

class PetSitterUsers {
  PetSitterUsers._();

  static const sami = PetSitterUser(
    id: 'sami',
    name: 'Sami',
    email: 'sami@petsitter.tn',
    role: PetSitterRole.owner,
  );

  static const samira = PetSitterUser(
    id: 'samira',
    name: 'Samira',
    email: 'samira@petsitter.tn',
    role: PetSitterRole.sitter,
  );

  static const admin = PetSitterUser(
    id: 'admin',
    name: 'Admin',
    email: 'admin@petsitter.tn',
    role: PetSitterRole.admin,
  );

  static const List<PetSitterUser> all = [sami, samira, admin];
}

class PetSitterSession extends ChangeNotifier {
  PetSitterSession._();

  static final PetSitterSession instance = PetSitterSession._();

  PetSitterUser _currentUser = PetSitterUsers.sami;

  PetSitterUser get currentUser => _currentUser;
  String get currentUserId => _currentUser.id;
  PetSitterRole get role => _currentUser.role;
  bool get isOwner => _currentUser.role == PetSitterRole.owner;
  bool get isSitter => _currentUser.role == PetSitterRole.sitter;
  bool get isAdmin => _currentUser.role == PetSitterRole.admin;

  void selectUser(PetSitterUser user) {
    if (_currentUser.id == user.id) return;
    _currentUser = user;

    // Sync with teammate's DemoSessionProvider if possible
    try {
      if (user.role == PetSitterRole.admin) {
        DemoSessionProvider.instance.select(DemoUsers.admin);
      } else if (user.role == PetSitterRole.sitter) {
        DemoSessionProvider.instance.select(DemoUsers.petsitter);
      } else {
        DemoSessionProvider.instance.select(DemoUsers.owner);
      }
    } catch (_) {}

    notifyListeners();
  }

  void selectById(String id) {
    for (final u in PetSitterUsers.all) {
      if (u.id.equalsIgnoreCase(id)) {
        selectUser(u);
        return;
      }
    }
  }
}

extension on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

class PetSitterUserSwitcher extends StatelessWidget {
  const PetSitterUserSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final session = PetSitterSession.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final current = session.currentUser;
        return PopupMenuButton<PetSitterUser>(
          tooltip: 'Changer d\'utilisateur test (Module 2)',
          onSelected: session.selectUser,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: LP.soft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: LP.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: LP.primary,
                  child: Text(
                    current.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${current.name} (${current.role.label})',
                  style: LPText.body(size: 12, w: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Icon(PhosphorIconsBold.caretDown, size: 14, color: LP.ink),
              ],
            ),
          ),
          itemBuilder: (context) => [
            for (final u in PetSitterUsers.all)
              PopupMenuItem(
                value: u,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: u.id == current.id ? LP.primary : LP.soft,
                      child: Text(
                        u.initials,
                        style: TextStyle(
                          color: u.id == current.id ? Colors.white : LP.ink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name,
                          style: TextStyle(
                            fontWeight: u.id == current.id ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${u.role.label} · ID: ${u.id}',
                          style: LPText.bodyS.copyWith(fontSize: 11, color: LP.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
