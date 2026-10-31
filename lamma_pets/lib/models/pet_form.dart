/// Formulaire de l'animal : les questions changent selon l'espèce
/// (pas de promenade pour un poisson, l'aquarium à la place).
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'species.dart';

// ————————————————————————————————————————————— Champs adaptés à l'espèce

sealed class PetField {
  const PetField(this.label);
  final String label;
}

class TextQ extends PetField {
  const TextQ(super.label, this.hint);
  final String hint;
}

class ChoiceQ extends PetField {
  const ChoiceQ(super.label, this.options, {this.multi = false, this.initial = const {}});
  final List<String> options;
  final bool multi;
  final Set<String> initial;
}

class ToggleQ extends PetField {
  const ToggleQ(super.label, {this.sub, this.initial = false});
  final String? sub;
  final bool initial;
}

class CounterQ extends PetField {
  const CounterQ(super.label, this.initial, {this.max = 10});
  final int initial;
  final int max;
}

typedef PetSection = (String title, IconData icon, List<PetField> fields);

List<PetSection> sectionsFor(Species s) => switch (s) {
  Species.chien => const [
    (
      'Gabarit',
      PhosphorIconsRegular.dog,
      [
        TextQ('Race', 'Ex. : croisé, berger allemand, caniche…'),
        ChoiceQ('Taille', ['Petit · < 10 kg', 'Moyen · 10–25 kg', 'Grand · > 25 kg']),
        ToggleQ('Stérilisé'),
      ],
    ),
    (
      'Alimentation',
      PhosphorIconsRegular.bowlFood,
      [
        TextQ('Nourriture et quantité', 'Ex. : croquettes adulte, 250 g par jour'),
        CounterQ('Repas par jour', 2, max: 4),
        ToggleQ('Friandises autorisées', initial: true),
      ],
    ),
    (
      'Sorties et habitudes',
      PhosphorIconsRegular.footprints,
      [
        CounterQ('Promenades par jour', 3, max: 6),
        ChoiceQ('Durée d\'une promenade', ['15 min', '30 min', '1 h ou plus']),
        ToggleQ('Tire en laisse'),
        ChoiceQ('Peut rester seul', ['Moins de 2 h', '2 à 4 h', 'Plus de 4 h']),
      ],
    ),
    (
      'Comportement',
      PhosphorIconsRegular.smiley,
      [
        ChoiceQ('S\'entend avec', ['Chiens', 'Chats', 'Enfants', 'Inconnus'], multi: true),
        ChoiceQ('Caractère', ['Calme', 'Joueur', 'Craintif', 'Protecteur', 'Aboie souvent'], multi: true),
      ],
    ),
  ],
  Species.chat => const [
    (
      'Identité',
      PhosphorIconsRegular.cat,
      [TextQ('Race', 'Ex. : européen, siamois, angora…'), ToggleQ('Stérilisé', initial: true)],
    ),
    (
      'Alimentation',
      PhosphorIconsRegular.bowlFood,
      [
        TextQ('Nourriture et quantité', 'Ex. : croquettes stérilisé, 40 g matin et soir'),
        CounterQ('Repas par jour', 2, max: 5),
      ],
    ),
    (
      'Habitudes',
      PhosphorIconsRegular.houseLine,
      [
        ChoiceQ('Mode de vie', ['Intérieur', 'Balcon', 'Accès à l\'extérieur']),
        ChoiceQ('Litière', ['Agglomérante', 'Végétale', 'Silice']),
        TextQ('Cachettes et coins préférés', 'Ex. : sous le lit, sur le canapé au soleil'),
      ],
    ),
    (
      'Comportement',
      PhosphorIconsRegular.smiley,
      [
        ChoiceQ('S\'entend avec', ['Chats', 'Chiens', 'Enfants'], multi: true),
        ChoiceQ('Caractère', ['Câlin', 'Indépendant', 'Joueur', 'Craintif'], multi: true),
      ],
    ),
  ],
  Species.oiseau => const [
    (
      'Espèce',
      PhosphorIconsRegular.bird,
      [
        ChoiceQ('Type d\'oiseau', ['Perruche', 'Inséparable', 'Canari', 'Calopsitte', 'Gris du Gabon', 'Autre']),
      ],
    ),
    (
      'Alimentation',
      PhosphorIconsRegular.grains,
      [
        TextQ('Graines ou granulés', 'Ex. : mélange pour inséparables'),
        TextQ('Fruits et légumes frais', 'Ex. : pomme, carotte — 3 fois par semaine'),
      ],
    ),
    (
      'Cage et habitudes',
      PhosphorIconsRegular.sun,
      [
        TextQ('Dimensions de la cage', 'Ex. : 60 × 40 cm'),
        ChoiceQ('Sorties hors de la cage', ['Jamais', 'Sous surveillance', 'Chaque jour']),
        ToggleQ('Couvrir la cage la nuit'),
        ToggleQ('Sensible aux courants d\'air', sub: 'Le sitter évitera les fenêtres ouvertes'),
      ],
    ),
    (
      'Comportement',
      PhosphorIconsRegular.smiley,
      [
        ChoiceQ('Il ou elle…', ['Chante ou parle', 'Se laisse prendre', 'Pince', 'Est craintif'], multi: true),
      ],
    ),
  ],
  Species.lapin => const [
    ('Identité', PhosphorIconsRegular.rabbit, [TextQ('Race', 'Ex. : bélier nain, angora…'), ToggleQ('Stérilisé')]),
    (
      'Alimentation',
      PhosphorIconsRegular.carrot,
      [
        ToggleQ('Foin à volonté', initial: true),
        TextQ('Légumes frais', 'Ex. : endives, fanes de carotte, persil'),
        TextQ('Granulés', 'Ex. : 1 cuillère à soupe le matin'),
      ],
    ),
    (
      'Habitat',
      PhosphorIconsRegular.houseLine,
      [
        ChoiceQ('Il vit…', ['En enclos', 'En cage avec sorties', 'En liberté dans la maison']),
        TextQ('Heures de sortie', 'Ex. : 2 h le soir'),
      ],
    ),
    (
      'Manipulation',
      PhosphorIconsRegular.handHeart,
      [
        ChoiceQ('Il ou elle…', [
          'Aime être porté',
          'Préfère rester au sol',
          'Ronge les câbles',
          'Est craintif',
        ], multi: true),
      ],
    ),
  ],
  Species.poisson => const [
    (
      'Aquarium',
      PhosphorIconsRegular.waves,
      [
        ChoiceQ('Type', ['Eau douce', 'Eau de mer', 'Bassin extérieur'], initial: {'Eau douce'}),
        TextQ('Volume', 'Ex. : 60 L'),
        CounterQ('Nombre de poissons', 4, max: 50),
        TextQ('Espèces', 'Ex. : poissons rouges, guppys, néons'),
      ],
    ),
    (
      'Nourriture',
      PhosphorIconsRegular.fish,
      [
        TextQ('Type de nourriture', 'Ex. : flocons, granulés, une pincée'),
        ChoiceQ('Fréquence', ['1 fois par jour', '2 fois par jour', 'Tous les 2 jours']),
      ],
    ),
    (
      'Entretien pendant la garde',
      PhosphorIconsRegular.thermometer,
      [
        TextQ('Température de l\'eau', 'Ex. : 24 °C'),
        ToggleQ('Éclairage programmé', initial: true),
        ChoiceQ('Changement d\'eau', ['Pas pendant la garde', 'Partiel chaque semaine']),
        TextQ('Matériel à surveiller', 'Ex. : filtre, pompe à air, chauffage'),
      ],
    ),
  ],
  Species.autre => const [
    (
      'Espèce',
      PhosphorIconsRegular.pawPrint,
      [
        ChoiceQ('Type d\'animal', ['Hamster', 'Cochon d\'Inde', 'Tortue', 'Gerbille', 'Furet', 'Autre']),
        TextQ('Précisez si besoin', 'Ex. : tortue de terre, 12 ans'),
      ],
    ),
    (
      'Alimentation',
      PhosphorIconsRegular.bowlFood,
      [
        TextQ('Nourriture', 'Ex. : mélange de graines, légumes frais'),
        ChoiceQ('Fréquence', ['1 fois par jour', '2 fois par jour']),
      ],
    ),
    (
      'Habitat',
      PhosphorIconsRegular.houseSimple,
      [
        TextQ('Type d\'habitat', 'Ex. : cage, terrarium, enclos'),
        TextQ('Besoins particuliers', 'Ex. : lampe chauffante, roue, hibernation'),
      ],
    ),
    (
      'Manipulation',
      PhosphorIconsRegular.handHeart,
      [
        ChoiceQ('Il ou elle…', ['Se laisse manipuler', 'Avec précaution', 'Ne pas manipuler']),
      ],
    ),
  ],
};

String adaptNoteFor(Species s) => switch (s) {
  Species.poisson =>
    'Pour un aquarium, nous demandons l\'eau, la nourriture et le matériel — pas de promenade ni de comportement.',
  Species.oiseau => 'Pour un oiseau : la cage, les sorties et les fruits frais comptent plus que tout.',
  Species.chien => 'Pour un chien : promenades, temps seul et entente avec les autres animaux.',
  Species.chat => 'Pour un chat : mode de vie, litière et caractère.',
  Species.lapin => 'Pour un lapin : foin, légumes, habitat et manipulation.',
  Species.autre => 'Pour les petits animaux : habitat et besoins particuliers.',
};
