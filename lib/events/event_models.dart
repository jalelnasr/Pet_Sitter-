/// Événements : rencontres, ateliers et sorties autour des animaux.
library;

import 'package:flutter/widgets.dart';
import 'package:pet_sitter/core/config/api_constants.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/utils/format.dart';

/// Cycle de vie d'un événement ou d'une proposition.
enum EventStatus { draft, pending, rejected, published, cancelled, completed }

extension EventStatusX on EventStatus {
  String get label => switch (this) {
    EventStatus.draft => 'Brouillon',
    EventStatus.pending => 'En attente',
    EventStatus.rejected => 'Refusé',
    EventStatus.published => 'Publié',
    EventStatus.cancelled => 'Annulé',
    EventStatus.completed => 'Terminé',
  };

  String get apiValue => switch (this) {
    EventStatus.draft => 'DRAFT',
    EventStatus.pending => 'PENDING',
    EventStatus.rejected => 'REJECTED',
    EventStatus.published => 'PUBLISHED',
    EventStatus.cancelled => 'CANCELLED',
    EventStatus.completed => 'COMPLETED',
  };

  /// Uniquement les événements publiés acceptent des réservations.
  bool get isOpen => this == EventStatus.published;

  static EventStatus fromString(String? value) {
    if (value == null) return EventStatus.published;
    return switch (value.toUpperCase()) {
      'DRAFT' => EventStatus.draft,
      'PENDING' => EventStatus.pending,
      'REJECTED' => EventStatus.rejected,
      'CANCELLED' => EventStatus.cancelled,
      'COMPLETED' => EventStatus.completed,
      _ => EventStatus.published,
    };
  }
}

enum ReservationStatus { confirmed, cancelled, cancelledByAdmin }

extension ReservationStatusX on ReservationStatus {
  String get label => switch (this) {
    ReservationStatus.confirmed => 'Confirmée',
    ReservationStatus.cancelled => 'Annulée',
    ReservationStatus.cancelledByAdmin => 'Annulée par l\'admin',
  };

  String get apiValue => switch (this) {
    ReservationStatus.confirmed => 'CONFIRMED',
    ReservationStatus.cancelled => 'CANCELLED',
    ReservationStatus.cancelledByAdmin => 'CANCELLED_BY_ADMIN',
  };

  static ReservationStatus fromString(String? value) {
    if (value == null) return ReservationStatus.confirmed;
    return switch (value.toUpperCase()) {
      'CANCELLED' => ReservationStatus.cancelled,
      'CANCELLED_BY_ADMIN' => ReservationStatus.cancelledByAdmin,
      _ => ReservationStatus.confirmed,
    };
  }
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

  String get apiValue => switch (this) {
    EventCategory.adoption => 'ADOPTION',
    EventCategory.training => 'TRAINING',
    EventCategory.meetup => 'MEETUP',
    EventCategory.welfare => 'WELFARE',
    EventCategory.walk => 'WALK',
  };

  IconData get icon => switch (this) {
    EventCategory.adoption => PhosphorIconsRegular.pawPrint,
    EventCategory.training => PhosphorIconsRegular.sealCheck,
    EventCategory.meetup => PhosphorIconsRegular.chatCircleDots,
    EventCategory.welfare => PhosphorIconsRegular.heart,
    EventCategory.walk => PhosphorIconsRegular.mapPin,
  };

  static EventCategory fromString(String? value) {
    if (value == null) return EventCategory.meetup;
    return switch (value.toUpperCase()) {
      'ADOPTION' => EventCategory.adoption,
      'TRAINING' => EventCategory.training,
      'MEETUP' => EventCategory.meetup,
      'WELFARE' => EventCategory.welfare,
      'WALK' => EventCategory.walk,
      _ => EventCategory.meetup,
    };
  }
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
    this.organizerId,
    this.rejectionReason,
    this.isMine = false,
  });

  final String id;
  final String title;
  final String description;
  final EventCategory category;
  final String imageUrl;
  final String organizerName;
  final String? organizerId;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxParticipants;
  final int currentParticipants;
  final EventStatus status;
  final String? rejectionReason;

  /// Événement créé ou proposé par l'utilisateur connecté.
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

  String get seatsLabel => isFull
      ? 'Complet'
      : '$remainingSeats place${remainingSeats > 1 ? 's' : ''} restante${remainingSeats > 1 ? 's' : ''}';

  PetEvent copyWith({
    String? title,
    String? description,
    EventCategory? category,
    String? imageUrl,
    String? organizerName,
    String? organizerId,
    String? location,
    DateTime? startDate,
    DateTime? endDate,
    int? maxParticipants,
    int? currentParticipants,
    EventStatus? status,
    String? rejectionReason,
    bool? isMine,
  }) {
    return PetEvent(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      organizerName: organizerName ?? this.organizerName,
      organizerId: organizerId ?? this.organizerId,
      location: location ?? this.location,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isMine: isMine ?? this.isMine,
    );
  }

  factory PetEvent.fromJson(Map<String, dynamic> json) {
    DateTime start;
    if (json['startDate'] != null) {
      start = DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now();
    } else if (json['date'] != null && json['startTime'] != null) {
      start = DateTime.tryParse('${json['date']}T${json['startTime']}') ?? DateTime.now();
    } else if (json['date'] != null) {
      start = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    } else {
      start = DateTime.now();
    }

    DateTime end;
    if (json['endDate'] != null) {
      end = DateTime.tryParse(json['endDate'].toString()) ?? start.add(const Duration(hours: 2));
    } else if (json['date'] != null && json['endTime'] != null) {
      end = DateTime.tryParse('${json['date']}T${json['endTime']}') ?? start.add(const Duration(hours: 2));
    } else {
      end = start.add(const Duration(hours: 2));
    }

    final rawImage = (json['imageUrl'] as String?) ?? '';
    final resolvedImage = rawImage.isEmpty ? '' : ApiConstants.resolveMediaUrl(rawImage);

    final capacity = (json['capacity'] as num?)?.toInt() ??
        (json['maxParticipants'] as num?)?.toInt() ??
        20;
    final current = (json['currentParticipants'] as num?)?.toInt() ?? 0;

    return PetEvent(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: EventCategoryX.fromString(json['category'] as String?),
      imageUrl: resolvedImage,
      organizerName: (json['organizerName'] as String?) ?? 'Organisateur',
      organizerId: json['organizerId'] as String?,
      location: (json['location'] as String?) ?? '',
      startDate: start,
      endDate: end,
      maxParticipants: capacity,
      currentParticipants: current,
      status: EventStatusX.fromString(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      isMine: json['isMine'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'category': category.apiValue,
    'location': location,
    'date': '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'startTime': '${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}:00',
    'endTime': '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}:00',
    'capacity': maxParticipants,
    'imageUrl': imageUrl,
    'status': status.apiValue,
    if (rejectionReason != null) 'rejectionReason': rejectionReason,
  };
}

class EventReservation {
  const EventReservation({
    required this.id,
    required this.eventId,
    required this.participantName,
    this.phone = '',
    required this.reservationDate,
    required this.status,
    this.participants = 1,
    this.comment = '',
    this.event,
  });

  final String id;
  final String eventId;
  final String participantName;
  final String phone;
  final DateTime reservationDate;
  final ReservationStatus status;

  /// Nombre de places demandées dans le formulaire.
  final int participants;

  /// Message libre laissé par le participant.
  final String comment;

  /// Détails de l'événement associé s'ils sont renvoyés par l'API.
  final PetEvent? event;

  EventReservation copyWith({
    ReservationStatus? status,
    PetEvent? event,
  }) => EventReservation(
    id: id,
    eventId: eventId,
    participantName: participantName,
    phone: phone,
    reservationDate: reservationDate,
    status: status ?? this.status,
    participants: participants,
    comment: comment,
    event: event ?? this.event,
  );

  factory EventReservation.fromJson(Map<String, dynamic> json) {
    PetEvent? parsedEvent;
    if (json['event'] is Map<String, dynamic>) {
      parsedEvent = PetEvent.fromJson(json['event'] as Map<String, dynamic>);
    }

    return EventReservation(
      id: (json['id'] as String?) ?? '',
      eventId: (json['eventId'] as String?) ?? parsedEvent?.id ?? '',
      participantName: (json['participantName'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      reservationDate: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      status: ReservationStatusX.fromString(json['status'] as String?),
      participants: (json['numberOfPlaces'] as num?)?.toInt() ??
          (json['participants'] as num?)?.toInt() ??
          1,
      comment: (json['comment'] as String?) ?? '',
      event: parsedEvent,
    );
  }

  Map<String, dynamic> toJson() => {
    'participantName': participantName,
    'phone': phone,
    'numberOfPlaces': participants,
    'comment': comment,
  };
}

/// Suggestion générée par l'assistant IA (Groq LLM ou fallback local).
class EventAiSuggestion {
  const EventAiSuggestion({
    required this.titles,
    required this.description,
    required this.summary,
    required this.tags,
    required this.checklist,
    required this.suggestedCategory,
    required this.tip,
    this.source = 'fallback',
    this.suggestions = const [],
  });

  final List<String> titles;
  final String description;
  final String summary;
  final List<String> tags;
  final List<String> checklist;
  final String suggestedCategory;
  final String tip;
  final String source;
  final List<String> suggestions;

  bool get isFromLlm => source.toLowerCase() == 'llm';

  factory EventAiSuggestion.fromJson(Map<String, dynamic> json) {
    final titlesRaw = json['titles'];
    final List<String> parsedTitles = [];
    if (titlesRaw is List) {
      for (final item in titlesRaw) {
        if (item != null) parsedTitles.add(item.toString());
      }
    } else if (json['title'] != null) {
      parsedTitles.add(json['title'].toString());
    }

    final tagsRaw = json['tags'];
    final List<String> parsedTags = [];
    if (tagsRaw is List) {
      for (final item in tagsRaw) {
        if (item != null) parsedTags.add(item.toString());
      }
    }

    final checklistRaw = json['checklist'];
    final List<String> parsedChecklist = [];
    if (checklistRaw is List) {
      for (final item in checklistRaw) {
        if (item != null) parsedChecklist.add(item.toString());
      }
    }

    return EventAiSuggestion(
      titles: parsedTitles,
      description: (json['description'] as String?) ?? '',
      summary: (json['summary'] as String?) ?? '',
      tags: parsedTags,
      checklist: parsedChecklist,
      suggestedCategory: (json['suggestedCategory'] as String?) ?? 'Rencontre',
      tip: (json['tip'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'fallback',
      suggestions: parsedChecklist,
    );
  }

  Map<String, dynamic> toJson() => {
    'titles': titles,
    'description': description,
    'summary': summary,
    'tags': tags,
    'checklist': checklist,
    'suggestedCategory': suggestedCategory,
    'tip': tip,
    'source': source,
  };
}

/// Génération locale et simulée : aucun appel réseau, aucun modèle externe.
class EventAiAssistant {
  EventAiAssistant._();

  static EventAiSuggestion suggest({
    required String title,
    required String description,
    required EventCategory category,
    List<String>? keywords,
    String? location,
  }) {
    final t = title.trim();
    final d = description.trim();
    final text = '${t.toLowerCase()} ${d.toLowerCase()}';

    final tags = <String>{..._categoryTags(category)};
    void tagIf(bool condition, String tag) {
      if (condition) tags.add(tag);
    }

    tagIf(text.contains('chat'), '#cats');
    tagIf(
      text.contains('chien') || text.contains('chiot') || text.contains('dog'),
      '#dogs',
    );
    tagIf(text.contains('famille') || text.contains('enfant'), '#family');
    tagIf(
      text.contains('bénévol') || text.contains('association'),
      '#solidarity',
    );
    tagIf(
      text.contains('atelier') ||
          text.contains('formation') ||
          text.contains('apprendre'),
      '#workshop',
    );
    tagIf(text.contains('promenade') || text.contains('balade'), '#walking');
    tagIf(text.contains('adoption'), '#adoption');
    tagIf(
      text.contains('santé') ||
          text.contains('vaccin') ||
          text.contains('vétérinaire'),
      '#health',
    );

    final base = switch (category) {
      EventCategory.adoption =>
        'un temps de rencontre autour de l\'adoption responsable',
      EventCategory.training => 'un atelier pratique d\'éducation canine',
      EventCategory.meetup =>
        'une rencontre conviviale entre propriétaires et leurs animaux',
      EventCategory.welfare =>
        'une journée de sensibilisation au bien-être animal',
      EventCategory.walk => 'une sortie collective en plein air',
    };

    final audience = switch (category) {
      EventCategory.adoption =>
        'Les familles qui souhaitent adopter y trouveront des conseils concrets et pourront rencontrer les animaux dans un cadre calme.',
      EventCategory.training =>
        'Il convient aux propriétaires de chiens qui veulent travailler les ordres de base et la marche en laisse.',
      EventCategory.meetup =>
        'Il est adapté aux voisins qui cherchent à partager promenades, conseils et gardes entre eux.',
      EventCategory.welfare =>
        'Il s\'adresse aux bénévoles et aux habitants sensibles à la cause animale.',
      EventCategory.walk =>
        'Il convient aux propriétaires de chiens sociables qui aiment marcher en groupe.',
    };

    final summary = t.isEmpty
        ? 'Décrivez votre événement pour obtenir un résumé.'
        : '« $t » est $base. $audience';

    final suggestions = <String>[];
    if (t.length < 12) {
      suggestions.add(
        'Ajoutez un titre plus descriptif : l\'espèce concernée et le lieu aident à comprendre l\'événement.',
      );
    }
    if (d.length < 80) {
      suggestions.add(
        'Détaillez le déroulé : accueil, activités, pauses et matériel à prévoir.',
      );
    }
    switch (category) {
      case EventCategory.adoption:
        if (!text.contains('vaccin')) {
          suggestions.add(
            'Mentionnez les vaccins et l\'identification des animaux présentés.',
          );
        }
      case EventCategory.training:
        if (!text.contains('laisse') && !text.contains('friandise')) {
          suggestions.add(
            'Précisez le matériel demandé : laisse, collier, friandises, eau.',
          );
        }
      case EventCategory.welfare:
        if (!text.contains('bénévole')) {
          suggestions.add(
            'Indiquez si vous cherchez des bénévoles et comment les contacter.',
          );
        }
      case EventCategory.meetup:
        if (!text.contains('lieu')) {
          suggestions.add(
            'Ajoutez un point de rendez-vous précis et un contact sur place.',
          );
        }
      case EventCategory.walk:
        if (!text.contains('km')) {
          suggestions.add(
            'Précisez la distance et le niveau des participants attendu.',
          );
        }
    }
    if (!text.contains(RegExp(r'\d'))) {
      suggestions.add(
        'Ajoutez un horaire ou une capacité chiffrée pour rassurer les participants.',
      );
    }
    if (suggestions.length < 3) {
      suggestions.add(
        'Privilégiez des groupes de 20 personnes maximum pour garder un moment convivial.',
      );
    }
    if (suggestions.length < 3) {
      suggestions.add(
        'Prévoyez un plan B en cas de pluie : un lieu couvert ou un report annoncé à l\'avance.',
      );
    }

    final locStr = (location != null && location.trim().isNotEmpty) ? ' à ${location.trim()}' : '';
    final titles = [
      if (t.isNotEmpty) 'Grand rassemblement : $t$locStr' else 'Grand rassemblement pour nos animaux$locStr',
      if (t.isNotEmpty) '$t$locStr – Moments complices' else 'Moments complices avec nos compagnons$locStr',
      if (t.isNotEmpty) 'Atelier convivial : $t' else 'Atelier convivial et découverte',
    ];

    final descText = d.isNotEmpty
        ? d
        : 'Rejoignez-nous pour ${t.isNotEmpty ? t.toLowerCase() : "cet événement"}$locStr ! '
          'Un rendez-vous chaleureux pensé pour nos compagnons et leurs propriétaires. '
          'Profitez d\'un moment de partage, d\'échanges et de jeux en toute sécurité. '
          'Nous vous attendons nombreux !';

    final categoryChecklists = {
      EventCategory.adoption: [
        'Gamelles d\'eau fraîche',
        'Dossiers d\'adoption et formulaires',
        'Laisses et harnais de sécurité',
        'Friandises et jouets d\'accueil',
        'Kit de premiers secours vétérinaire',
      ],
      EventCategory.training: [
        'Friandises appétentes de récompense',
        'Saccoche à friandises et clicker',
        'Longes d\'éducation (5-10m)',
        'Tapis de repos pour chaque chien',
        'Gamelles d\'eau individuelles',
      ],
      EventCategory.meetup: [
        'Gamelles d\'eau partagées et bouteilles',
        'Sacs à déjections canines',
        'Jouets d\'interaction adaptés',
        'Trousse de premiers secours',
        'Badges nominatifs pour les propriétaires',
      ],
      EventCategory.welfare: [
        'Brosses et serviettes douces',
        'Tapis confortables et coussins',
        'Espace calme et ombragé',
        'Diffuseurs apaisants naturels',
        'Eau fraîche à volonté',
      ],
      EventCategory.walk: [
        'Laisses solides et colliers ajustés',
        'Gourdes de voyage et gamelles pliables',
        'Sacs à déjections en quantité',
        'Gilets fluorescents ou foulards repères',
        'Trousse de secours pour pattes',
      ],
    };

    final checklist = categoryChecklists[category] ?? [
      'Gamelles d\'eau fraîche',
      'Laisses de sécurité',
      'Friandises de bienvenue',
      'Trousse de secours',
    ];

    final tip = suggestions.isNotEmpty
        ? suggestions.first
        : switch (category) {
            EventCategory.adoption => 'Limitez à 15 participants simultanés pour ne pas stresser les animaux candidats.',
            EventCategory.training => 'Prévoyez un espace de 3 à 5 mètres entre chaque binôme maître-chien.',
            EventCategory.meetup => 'Favorisez un terrain clos et prévoyez une zone de décompression.',
            EventCategory.welfare => 'Maintenez un volume sonore bas et une température ambiante agréable.',
            EventCategory.walk => 'Vérifiez la météo avant le départ et prévoyez une pause boisson régulière.',
          };

    final cleanSummary = summary.length > 120 ? '${summary.substring(0, 117)}...' : summary;

    return EventAiSuggestion(
      titles: titles,
      description: descText,
      summary: cleanSummary,
      tags: tags.take(6).toList(),
      checklist: checklist,
      suggestedCategory: category.label,
      tip: tip,
      source: 'fallback',
      suggestions: suggestions.take(3).toList(),
    );
  }

  static List<String> _categoryTags(EventCategory category) =>
      switch (category) {
        EventCategory.adoption => const ['#adoption', '#pets'],
        EventCategory.training => const ['#training', '#education'],
        EventCategory.meetup => const ['#meetup', '#community'],
        EventCategory.welfare => const ['#welfare', '#solidarity'],
        EventCategory.walk => const ['#walking', '#outdoor'],
      };
}

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
