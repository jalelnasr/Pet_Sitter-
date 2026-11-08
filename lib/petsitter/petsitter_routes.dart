import 'package:flutter/material.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';
import 'package:pet_sitter/petsitter/petsitter_screens.dart';
import 'package:pet_sitter/petsitter/petsitter_ai.dart';

class PetsitterRoutes {
  PetsitterRoutes._();

  static const list = '/sitters';
  static const sitterDetails = '/sitter-details';
  static const sitterBook = '/sitter-book';
  static const myReservations = '/my-reservations';
  static const sitterDashboard = '/sitter-dashboard';
  static const sitterProfileEdit = '/sitter-profile-edit';
  static const adminSitters = '/admin-sitters';
  static const matchmaking = '/sitter-matchmaking';
}

Route<dynamic>? onGeneratePetsitterRoute(RouteSettings settings) {
  final a = settings.arguments;
  final Widget? page = switch (settings.name) {
    PetsitterRoutes.list => const SitterListScreen(),
    PetsitterRoutes.sitterDetails =>
      a is String ? SitterDetailsScreen(sitterId: a) : const SitterListScreen(),
    PetsitterRoutes.sitterBook => a is PetSitter
        ? ReservationFormScreen(sitter: a)
        : const SitterListScreen(),
    PetsitterRoutes.myReservations => const MyReservationsScreen(),
    PetsitterRoutes.sitterDashboard => const SitterSpaceScreen(),
    PetsitterRoutes.sitterProfileEdit =>
      SitterProfileFormScreen(profile: a is PetSitter ? a : null),
    PetsitterRoutes.adminSitters => const AdminSittersScreen(),
    PetsitterRoutes.matchmaking => const MatchmakingScreen(),
    _ => null,
  };

  if (page == null) return null;
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
