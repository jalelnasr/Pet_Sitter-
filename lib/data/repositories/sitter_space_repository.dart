/// Espace pet sitter : demandes reçues, agenda, disponibilités, services.
library;

import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/models/models.dart';

abstract class SitterSpaceRepository {
  Sitter get me;
  List<SitterRequest> requests();
  List<UpcomingCare> upcoming();

  /// Jours indisponibles et jours réservés, par mois (0 = octobre, 1 = novembre).
  Map<int, Set<int>> unavailableDays();
  Map<int, Set<int>> bookedDays();
  List<EditableService> services();
  Future<void> saveServices(List<EditableService> services);
}

class MockSitterSpaceRepository implements SitterSpaceRepository {
  @override
  Sitter get me => Mock.amira;

  @override
  List<SitterRequest> requests() => [
    SitterRequest(
      owner: 'Sami R.',
      ownerPhoto: Photos.youssef,
      pets: 'Noisette · lapin bélier, 7 ans',
      petPhoto: Photos.rabbitLop,
      service: 'Accueil chez vous',
      dates: 'Dim. 1er → mer. 4 nov. · 3 nuits',
      earn: 105,
      message: 'Noisette est âgé : foin à volonté et un peu de persil le soir. Il est très calme.',
      received: 'Il y a 25 min',
    ),
    SitterRequest(
      owner: 'Hela M.',
      ownerPhoto: Photos.nour,
      pets: 'Pacha et Mimi · 2 chats',
      petPhoto: Photos.kitten,
      service: 'Visites à domicile · 2 par jour',
      dates: 'Ven. 30 oct. → dim. 1er nov. · 6 visites',
      earn: 168,
      message: 'Nous habitons à La Marsa Corniche, à 5 minutes de chez vous. Mimi est timide.',
      received: 'Il y a 2 h',
    ),
  ];

  @override
  List<UpcomingCare> upcoming() => [
    UpcomingCare(Photos.catOrange, 'Simba et Kiwi', 'Leïla B. · accueil', 'En cours', live: true),
    UpcomingCare(Photos.canary, 'Zaza et Lulu', 'Olfa K. · accueil', 'Ven. 13 → dim. 15 nov.'),
    UpcomingCare(Photos.catTuxedo, 'Mimi', 'Sarra T. · visites', 'Sam. 19 → mar. 22 déc.'),
  ];

  @override
  Map<int, Set<int>> unavailableDays() => {
    0: {18, 19, 30, 31},
    1: {8, 9, 10, 11, 12, 22, 23, 29, 30},
  };

  @override
  Map<int, Set<int>> bookedDays() => {
    0: {23, 24, 25, 26},
    1: {1, 2, 3, 4, 13, 14, 15},
  };

  @override
  List<EditableService> services() => [
    EditableService(
      PhosphorIconsRegular.houseLine,
      'Accueil chez moi',
      'Garde jour et nuit dans votre logement',
      35,
      'nuit',
      true,
    ),
    EditableService(
      PhosphorIconsRegular.key,
      'Visite à domicile',
      'Repas, eau, litière ou cage, photos',
      18,
      'visite',
      true,
    ),
    EditableService(PhosphorIconsRegular.sun, 'Garde de jour', 'De 8 h à 19 h, chez vous', 25, 'jour', false),
    EditableService(PhosphorIconsRegular.footprints, 'Promenade', 'Chiens uniquement · 45 min', 12, 'promenade', false),
  ];

  @override
  Future<void> saveServices(List<EditableService> services) => Future.delayed(const Duration(milliseconds: 900));
}
