/// Données de démonstration du module Événements.
library;

import 'package:pet_sitter/data/sources/mock_data.dart' show Mock, Photos;

import 'event_models.dart';

class EventMock {
  EventMock._();

  /// Images proposées lors de la création d'un événement (Unsplash, comme le reste du projet).
  static final images = <String>[
    Photos.catAndDog,
    Photos.dogAussie,
    Photos.dogsDuo,
    Photos.dogBeagle,
    Photos.dogCavalier,
    Photos.kitten,
  ];

  static final events = <PetEvent>[
    PetEvent(
      id: 'adoption-day',
      title: 'Adoption Day',
      description:
          'Une journée portes ouvertes pour rencontrer les chats et les chiens du refuge. Les bénévoles '
          'présentent chaque animal, son caractère et ses besoins, puis organisent des rencontres calmes '
          'avec les familles intéressées. Stands conseils sur les premiers jours à la maison, la '
          'stérilisation et les soins vétérinaires.',
      category: EventCategory.adoption,
      imageUrl: Photos.catAndDog,
      organizerName: 'Refuge Les Amis des Bêtes',
      location: 'Parc de la Marsa, Tunis',
      startDate: DateTime(2026, 11, 7, 10),
      endDate: DateTime(2026, 11, 7, 17),
      maxParticipants: 40,
      currentParticipants: 26,
      status: EventStatus.published,
    ),
    PetEvent(
      id: 'dog-training',
      title: 'Dog Training Workshop',
      description:
          'Atelier pratique pour apprendre les ordres de base : assis, au pied, rappel et marche en '
          'laisse sans tirer. Les exercices se font en petits groupes, avec des éducateurs canins '
          'bénévoles. Prévoyez une laisse, des friandises et de l\'eau pour votre chien.',
      category: EventCategory.training,
      imageUrl: Photos.dogAussie,
      organizerName: 'École canine El Medina',
      location: 'Parc du Belvédère, Tunis',
      startDate: DateTime(2026, 11, 14, 9, 30),
      endDate: DateTime(2026, 11, 14, 12, 30),
      maxParticipants: 18,
      currentParticipants: 12,
      status: EventStatus.published,
    ),
    PetEvent(
      id: 'pet-meetup',
      title: 'Pet Meetup',
      description:
          'Rencontre conviviale entre voisins et leurs animaux. Au programme : présentations, jeux '
          'd\'obéissance ludique, coin détente pour les animaux timides et échange de conseils sur '
          'l\'alimentation et les promenades en ville. Les animaux doivent être à jour de leurs vaccins.',
      category: EventCategory.meetup,
      imageUrl: Photos.dogsDuo,
      organizerName: Mock.ownerFullName,
      location: 'Plage de Khezama, Sousse',
      startDate: DateTime(2026, 12, 5, 15),
      endDate: DateTime(2026, 12, 5, 18),
      maxParticipants: 30,
      currentParticipants: 19,
      status: EventStatus.published,
      isMine: true,
    ),
    PetEvent(
      id: 'animal-welfare-day',
      title: 'Animal Welfare Day',
      description:
          'Journée de sensibilisation au bien-être animal : adoption responsable, identification, '
          'stérilisation et premiers soins. Une clinique mobile propose des contrôles gratuits et les '
          'bénévoles expliquent comment aider les animaux errants du quartier.',
      category: EventCategory.welfare,
      imageUrl: Photos.dogCavalier,
      organizerName: 'Association Patte Tendre',
      location: 'Centre culturel, Sfax',
      startDate: DateTime(2026, 10, 4, 10),
      endDate: DateTime(2026, 10, 4, 16),
      maxParticipants: 60,
      currentParticipants: 60,
      status: EventStatus.completed,
    ),
    PetEvent(
      id: 'dog-walking-event',
      title: 'Dog Walking Event',
      description:
          'Balade collective le long de la côte, ouverte aux chiens sociables et à leurs humains. '
          'Deux boucles sont proposées : 3 km pour les petits gabarits et 6 km pour les plus sportifs. '
          'Collation et point d\'eau prévus à mi-parcours.',
      category: EventCategory.walk,
      imageUrl: Photos.dogBeagle,
      organizerName: Mock.ownerFullName,
      location: 'Corniche de Carthage, Tunis',
      startDate: DateTime(2026, 10, 11, 8),
      endDate: DateTime(2026, 10, 11, 10),
      maxParticipants: 20,
      currentParticipants: 7,
      status: EventStatus.cancelled,
      isMine: true,
    ),
    PetEvent(
      id: 'chiens-et-cafes',
      title: 'Chiens & Cafés',
      description:
          'Petit-déjeuner entre propriétaires de chiens dans une terrasse accueillante. L\'idée : '
          'discuter des bonnes adresses du quartier, des promenades à partager et des gardes entre '
          'voisins. Places limitées pour rester au calme.',
      category: EventCategory.meetup,
      imageUrl: Photos.kitchen,
      organizerName: Mock.ownerFullName,
      location: 'Café El Manara, Tunis',
      startDate: DateTime(2026, 11, 22, 9),
      endDate: DateTime(2026, 11, 22, 11),
      maxParticipants: 16,
      currentParticipants: 0,
      status: EventStatus.draft,
      isMine: true,
    ),
  ];

  static final reservations = <EventReservation>[
    EventReservation(
      id: 'event-reservation-1',
      eventId: 'adoption-day',
      participantName: 'Leïla Ben Salah',
      reservationDate: DateTime(2026, 10, 18),
      status: ReservationStatus.confirmed,
      participants: 2,
      comment: 'Nous venons avec notre fille de 9 ans.',
    ),
    EventReservation(
      id: 'event-reservation-2',
      eventId: 'pet-meetup',
      participantName: 'Leïla Ben Salah',
      reservationDate: DateTime(2026, 10, 16),
      status: ReservationStatus.confirmed,
      participants: 1,
    ),
    EventReservation(
      id: 'event-reservation-3',
      eventId: 'animal-welfare-day',
      participantName: 'Leïla Ben Salah',
      reservationDate: DateTime(2026, 9, 28),
      status: ReservationStatus.cancelled,
      participants: 1,
      comment: 'Empêchement de dernière minute.',
    ),
  ];

  static PetEvent byId(String id) =>
      events.firstWhere((event) => event.id == id, orElse: () => events.first);
}
