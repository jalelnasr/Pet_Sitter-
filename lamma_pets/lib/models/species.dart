/// Espèces gardées et types de service (accueil ou visites).
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

enum Species { chat, chien, oiseau, lapin, poisson, autre }

extension SpeciesX on Species {
  String get label => switch (this) {
    Species.chat => 'Chat',
    Species.chien => 'Chien',
    Species.oiseau => 'Oiseau',
    Species.lapin => 'Lapin',
    Species.poisson => 'Poisson',
    Species.autre => 'Autre',
  };

  String get plural => switch (this) {
    Species.chat => 'Chats',
    Species.chien => 'Chiens',
    Species.oiseau => 'Oiseaux',
    Species.lapin => 'Lapins',
    Species.poisson => 'Poissons',
    Species.autre => 'Petits animaux',
  };

  String get hint => switch (this) {
    Species.autre => 'Hamster, cochon d\'Inde, tortue…',
    _ => plural,
  };

  IconData get icon => switch (this) {
    Species.chat => PhosphorIconsRegular.cat,
    Species.chien => PhosphorIconsRegular.dog,
    Species.oiseau => PhosphorIconsRegular.bird,
    Species.lapin => PhosphorIconsRegular.rabbit,
    Species.poisson => PhosphorIconsRegular.fish,
    Species.autre => PhosphorIconsRegular.pawPrint,
  };

  IconData get iconFill => switch (this) {
    Species.chat => PhosphorIconsFill.cat,
    Species.chien => PhosphorIconsFill.dog,
    Species.oiseau => PhosphorIconsFill.bird,
    Species.lapin => PhosphorIconsFill.rabbit,
    Species.poisson => PhosphorIconsFill.fish,
    Species.autre => PhosphorIconsFill.pawPrint,
  };
}

enum ServiceType { accueil, visite }

extension ServiceTypeX on ServiceType {
  String get label => switch (this) {
    ServiceType.accueil => 'Accueil chez le sitter',
    ServiceType.visite => 'Visites à domicile',
  };
  String get short => switch (this) {
    ServiceType.accueil => 'Accueil',
    ServiceType.visite => 'Visites',
  };
  String get unit => switch (this) {
    ServiceType.accueil => 'nuit',
    ServiceType.visite => 'visite',
  };
  IconData get icon => switch (this) {
    ServiceType.accueil => PhosphorIconsRegular.houseLine,
    ServiceType.visite => PhosphorIconsRegular.key,
  };
}
