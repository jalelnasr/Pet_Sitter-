/// Événements : rencontres, ateliers et sorties autour des animaux.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/utils/format.dart';

/// Cycle de vie d'un événement créé par un utilisateur.
enum EventStatus { draft, published, cancelled, completed }

extension EventStatusX on EventStatus {
  String get label => switch (this) {
    EventStatus.draft => 'Brouillon',
    EventStatus.published => 'Publié',
    EventStatus.cancelled => 'Annulé',
    EventStatus.completed => 'Terminé',
  };

  /// Uniquement les événements publiés acceptent des réservations.
  bool get isOpen => this == EventStatus.published;
}

enum ReservationStatus { confirmed, cancelled }

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.confirmed => 'Confirmée',
    ReservationStatus.cancelled => 'Annulée',
  };
}

/// Catégories visuelles, comme les catégories de la boutique.
enum EventCategory { adoption, training, meetup, welfare, walk }

extension EventCategoryX on EventCategory {
  String get label => switch (this) {
    EventCategory.adoption => 'Adoption',
    EventCategory.training => 'Éducation',
    EventCategory.meetup => 'Rencontre',
    EventCategory.welfare => 'Bien-être',
    EventCategory.walk => 'Promenade',
  };

  IconData get icon => switch (this) {
    EventCategory.adoption => PhosphorIconsRegular.pawPrint,
    EventCategory.training => PhosphorIconsRegular.sealCheck,
    EventCategory.meetup => PhosphorIconsRegular.chatCircleDots,
    EventCategory.welfare => PhosphorIconsRegular.heart,
    EventCategory.walk => PhosphorIconsRegular.mapPin,
  };
}

class PetEvent {
  const PetEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.organizerName,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.status,
    this.isMine = false,
  });

  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final String imageUrl;
  final String organizerName;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int currentParticipants;
  final EventStatus status;

  /// Événement créé par l'utilisateur connecté (aucun nouveau rôle : une simple action).
  final bool isMine;

  int get remainingSeats =>
      (maxParticipants - currentParticipants).clamp(0, maxParticipants);

  bool get isFull => remainingSeats == 0;

  double get fillRatio => maxParticipants == 0
      ? 0
      : (currentParticipants / maxParticipants).clamp(0, 1).toDouble();

  /// « sam. 7 nov. · 10:00 – 17:00 » ou « sam. 7 nov. – dim. 8 nov. ».
  String get dateLabel {
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    if (startDay == endDay) {
      return '${frDate(startDate)} · ${_hhmm(startDate)} – ${_hhmm(endDate)}';
    }
    return '${frDate(startDate)} – ${frDate(endDate)}';
  }

  /// « 24 · 25 · 26 octobre 2026 » n'est pas nécessaire ici : la date courte suffit.
  String get seatsLabel => isFull
      ? 'Complet'
      : '$remainingSeats place${remainingSeats > 1 ? 's' : ''} restante${remainingSeats > 1 ? 's' : ''}';

  PetEvent copyWith({
    String? title,
    String? description,
    EventCategory? category,
    String? imageUrl,
    String? organizerName,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? currentParticipants,
    EventStatus? status,
    bool? isMine,
  }) {
    return PetEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerName: organizerName ?? this.organizerName,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      isMine: isMine ?? this.isMine,
    );
  }
}

class EventReservation {
  const EventReservation({
    required this.id,
    required this.eventId,
    required this.participantName,
    required this.reservationDate,
    required this.status,
    this.participants = 1,
    this.comment = '',
  });

  final String id;
  final String eventId;
  final String participantName;
  final DateTime reservationDate;
  final ReservationStatus status;

  /// Nombre de places demandées dans le formulaire.
  final int participants;

  /// Message libre laissé par le participant.
  final String comment;

  EventReservation copyWith({ReservationStatus? status}) => EventReservation(
    id: id,
    eventId: eventId,
    participantName: participantName,
    reservationDate: reservationDate,
    status: status ?? this.status,
    participants: participants,
    comment: comment,
  );
}

/// Conseil simulé : résumé, tags et suggestions générés localement.
class EventAiSuggestion {
  const EventAiSuggestion({
    required this.summary,
    required this.tags,
    required this.suggestions,
  });

  final String summary;
  final List<String> tags;
  final List<String> suggestions;
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
