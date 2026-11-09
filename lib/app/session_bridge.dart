/// Relie la session du module Utilisateur aux sessions des autres modules.
///
/// Adoption, Événements et Garde ont chacun leur sélecteur d'utilisateur de test.
/// Quand un vrai compte est connecté, ils l'utilisent automatiquement ; à la déconnexion,
/// ils reviennent à leur compte de démonstration. Ce fichier est le seul endroit
/// qui connaît à la fois le module Utilisateur et les autres modules.
library;

import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/models/user.dart';
import 'package:pet_sitter/petsitter/petsitter_session.dart';

bool _bound = false;

void bindModuleSessions([AuthSession? session]) {
  if (_bound) return;
  _bound = true;
  final auth = session ?? AuthSession.instance;

  void sync() {
    final user = auth.user;
    if (user == null) {
      DemoSessionProvider.instance.signOutAccount();
      PetSitterSession.instance.signOutAccount();
      return;
    }
    DemoSessionProvider.instance.useAccount(
      DemoUser(
        id: user.id,
        firstName: user.firstName,
        email: user.email,
        role: switch (user.role) {
          AppRole.owner => UserRole.owner,
          AppRole.petsitter => UserRole.petsitter,
          AppRole.admin => UserRole.admin,
        },
      ),
    );
    PetSitterSession.instance.useAccount(
      PetSitterUser(
        id: user.id,
        name: user.firstName,
        email: user.email,
        role: switch (user.role) {
          AppRole.owner => PetSitterRole.owner,
          AppRole.petsitter => PetSitterRole.sitter,
          AppRole.admin => PetSitterRole.admin,
        },
      ),
    );
  }

  auth.addListener(sync);
  if (auth.isAuthenticated) sync();
}
