/// Données de démonstration du module Adoption.
library;

import 'package:pet_sitter/data/sources/mock_data.dart' show Photos;
import 'package:pet_sitter/models/species.dart';

import 'adoption_models.dart';

class AdoptionMock {
  AdoptionMock._();

  static final pets = <AdoptionPet>[
    AdoptionPet(
      id: 'simba',
      name: 'Simba',
      species: Species.chat,
      breed: 'Européen roux',
      age: '4 ans',
      sex: 'Mâle',
      city: 'Tunis',
      area: 'La Marsa',
      photo: Photos.catOrange,
      description:
          'Simba est un chat calme et très câlin, habitué à la vie en appartement. Il aime les coins ensoleillés, '
          'les couvertures douces et les longues siestes près de son humain. Il vit actuellement dans une famille '
          'qui déménage à l\'étranger et cherche pour lui un foyer stable et aimant.',
      health: 'En bonne santé',
      vaccinated: true,
      sterilized: true,
      extra: const {
        'Entente avec les enfants': 'Oui, à partir de 8 ans',
        'Autres animaux': 'Préfère être le seul chat',
        'Mode de vie': 'Appartement ou maison',
        'Habitudes': 'Câlin, propre, adore le soleil',
      },
    ),
    AdoptionPet(
      id: 'rocky',
      name: 'Rocky',
      species: Species.chien,
      breed: 'Beagle',
      age: '3 ans',
      sex: 'Mâle',
      city: 'Tunis',
      area: 'La Marsa',
      photo: Photos.dogBeagle,
      description:
          'Rocky est un beagle joyeux et curieux, toujours partant pour une promenade. Il connaît les ordres de base, '
          'marche très bien en laisse et adore jouer avec une balle. Il cherche une famille active qui pourra lui offrir '
          'de vraies balades quotidiennes et beaucoup de présence.',
      health: 'En pleine forme',
      vaccinated: true,
      sterilized: true,
      extra: const {
        'Entente avec les enfants': 'Oui',
        'Autres animaux': 'Oui, avec les chiens calmes',
        'Mode de vie': 'Maison avec jardin ou appartement',
        'Habitudes': 'Deux promenades par jour minimum',
      },
    ),
    AdoptionPet(
      id: 'luna',
      name: 'Luna',
      species: Species.chat,
      breed: 'Siamois',
      age: '2 ans',
      sex: 'Femelle',
      city: 'Sousse',
      area: 'Khezama',
      photo: Photos.catTuxedo,
      description:
          'Luna est une jeune chatte curieuse et bavarde, qui suit son humain partout. Elle aime jouer avec les plumes, '
          'observer par la fenêtre et se blottir sur les genoux le soir. Elle a été recueillie par une association et '
          'attend une famille patiente qui lui laissera le temps de prendre ses marques.',
      health: 'En bonne santé',
      vaccinated: true,
      sterilized: true,
      extra: const {
        'Entente avec les enfants': 'Oui, enfants calmes',
        'Autres animaux': 'Oui, avec les chats',
        'Mode de vie': 'Intérieur uniquement',
        'Habitudes': 'Joue beaucoup, très proche de l\'humain',
      },
    ),
    AdoptionPet(
      id: 'milo',
      name: 'Milo',
      species: Species.lapin,
      breed: 'Lapin bélier',
      age: '1 an',
      sex: 'Mâle',
      city: 'Sfax',
      area: 'Route de l\'Aïn',
      photo: Photos.rabbitLop,
      description:
          'Milo est un petit lapin bélier curieux et gourmand. Il vit en liberté dans son espace sécurisé, connaît sa '
          'litière et vient volontiers chercher des caresses. Il cherche un foyer calme, prêt à lui offrir du foin à '
          'volonté, de l\'espace et des cachettes pour se sentir en sécurité.',
      health: 'Suivi vétérinaire régulier',
      vaccinated: false,
      sterilized: true,
      extra: const {
        'Entente avec les enfants': 'Oui, avec surveillance',
        'Autres animaux': 'Préfère être seul',
        'Mode de vie': 'Intérieur, espace sécurisé',
        'Habitudes': 'Foin à volonté, très gourmand',
      },
    ),
    AdoptionPet(
      id: 'nala',
      name: 'Nala',
      species: Species.chien,
      breed: 'Cavalier King Charles',
      age: '5 ans',
      sex: 'Femelle',
      city: 'Tunis',
      area: 'Carthage',
      photo: Photos.dogCavalier,
      description:
          'Nala est une chienne douce et affectueuse, qui s\'entend avec tout le monde. Elle aime les balades tranquilles, '
          'les moments de repos et la compagnie de son humain. Sa famille actuelle ne peut plus s\'en occuper à cause '
          'd\'un déménagement et souhaite lui trouver un foyer où elle sera aimée pour le reste de sa vie.',
      health: 'Légère sensibilité aux articulations',
      vaccinated: true,
      sterilized: true,
      extra: const {
        'Entente avec les enfants': 'Oui',
        'Autres animaux': 'Oui, chats et chiens',
        'Mode de vie': 'Maison calme, peu d\'escaliers',
        'Habitudes': 'Promenades douces, adore les câlins',
      },
    ),
  ];

  static final requests = <AdoptionRequest>[
    AdoptionRequest(
      id: 'adoption-1',
      pet: pets[0],
      fullName: 'Leïla Ben Salah',
      phone: '22 345 678',
      address: '12 rue des Jasmins, La Marsa',
      experience:
          'J\'ai toujours vécu avec des chats et j\'ai adopté un chat adulte il y a quatre ans. '
          'Je connais les soins de base, les visites vétérinaires et les habitudes d\'un chat d\'intérieur.',
      motivation:
          'Je cherche un compagnon calme pour partager mon quotidien. Mon appartement est lumineux, '
          'avec un balcon sécurisé, et je travaille à la maison trois jours par semaine.',
      date: DateTime(2026, 10, 12),
      status: AdoptionStatus.accepted,
      aiScore: 92,
    ),
    AdoptionRequest(
      id: 'adoption-2',
      pet: pets[2],
      fullName: 'Leïla Ben Salah',
      phone: '22 345 678',
      address: '12 rue des Jasmins, La Marsa',
      experience:
          'J\'ai grandi avec des chats et je suis habituée aux chats timides. J\'ai déjà accompagné une chatte '
          'âgée chez le vétérinaire et je sais respecter son rythme.',
      motivation:
          'Luna me touche beaucoup. J\'aimerais lui offrir un foyer calme, sans chien, avec des jeux et '
          'un grand coussin près de la fenêtre.',
      date: DateTime(2026, 10, 18),
      status: AdoptionStatus.pending,
      aiScore: 86,
    ),
    AdoptionRequest(
      id: 'adoption-3',
      pet: pets[1],
      fullName: 'Leïla Ben Salah',
      phone: '22 345 678',
      address: '12 rue des Jasmins, La Marsa',
      experience: 'J\'ai déjà gardé le chien d\'un ami quelques week-ends.',
      motivation:
          'Rocky a l\'air très gentil et j\'aimerais l\'adopter pour m\'accompagner pendant mes balades.',
      date: DateTime(2026, 10, 5),
      status: AdoptionStatus.refused,
      aiScore: 62,
    ),
  ];

  static AdoptionPet byId(String id) =>
      pets.firstWhere((pet) => pet.id == id, orElse: () => pets.first);
}
