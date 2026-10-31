/// ViewModels du module Événements : état d'écran et logique légère.
library;

import 'package:pet_sitter/core/mvvm/view_model.dart';

import 'event_models.dart';
import 'event_repository.dart';

class EventListViewModel extends ViewModel {
  EventListViewModel(EventRepository repository, {this.forceEmpty = false})
    : _repository = repository;

  final EventRepository _repository;
  final bool forceEmpty;

  String _query = '';
  EventCategory? _category;

  String get query => _query;
  EventCategory? get category => _category;
  bool get hasFilters => _query.trim().isNotEmpty || _category != null;
  int get activeFilterCount =>
      (_query.trim().isEmpty ? 0 : 1) + (_category == null ? 0 : 1);

  List<PetEvent> get results {
    if (forceEmpty) return const [];
    final q = _query.trim().toLowerCase();
    return _repository.events().where((event) {
      final sameCategory = _category == null || event.category == _category;
      if (!sameCategory) return false;
      if (q.isEmpty) return true;
      final haystack =
          '${event.title} ${event.description} ${event.location} ${event.category.label}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void setQuery(String value) {
    _query = value;
    notify();
  }

  void setCategory(EventCategory? value) {
    _category = value;
    notify();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    notify();
  }

  /// Rafraîchit après une création, une modification ou une annulation.
  void refresh() => notify();
}

class EventDetailsViewModel extends ViewModel {
  EventDetailsViewModel(this._repository, this.eventId);

  final EventRepository _repository;
  final String eventId;

  /// Relit toujours le dépôt : les places restantes suivent les réservations.
  PetEvent? get event => _repository.byId(eventId);

  bool get canReserve =>
      event != null && event!.status.isOpen && !event!.isFull;

  void refresh() => notify();
}

class EventReservationViewModel extends ViewModel {
  EventReservationViewModel([EventRepository? repository])
    : _repository = repository ?? MockEventRepository.shared;

  final EventRepository _repository;
  bool _sending = false;

  bool get sending => _sending;

  Future<EventReservation> reserve({
    required PetEvent event,
    required String fullName,
    required String phone,
    required int participants,
    required String comment,
  }) async {
    _sending = true;
    notify();
    final reservation = EventReservation(
      id: 'event-reservation-${DateTime.now().microsecondsSinceEpoch}',
      eventId: event.id,
      participantName: fullName,
      reservationDate: DateTime.now(),
      status: ReservationStatus.confirmed,
      participants: participants,
      comment: comment,
    );
    try {
      await _repository.reserve(reservation);
      return reservation;
    } finally {
      _sending = false;
      notify();
    }
  }
}

/// Réservation + événement associé, pour l'affichage des cartes.
class EventReservationItem {
  const EventReservationItem({required this.reservation, required this.event});
  final EventReservation reservation;
  final PetEvent event;
}

class MyEventReservationsViewModel extends ViewModel {
  MyEventReservationsViewModel({
    EventRepository? repository,
    this.forceEmpty = false,
  }) : _repository = repository ?? MockEventRepository.shared;

  final EventRepository _repository;
  final bool forceEmpty;

  List<EventReservationItem> get items {
    if (forceEmpty) return const [];
    final result = <EventReservationItem>[];
    for (final reservation in _repository.reservations()) {
      final event = _repository.byId(reservation.eventId);
      if (event == null) continue;
      result.add(EventReservationItem(reservation: reservation, event: event));
    }
    return result;
  }

  bool get isEmpty => items.isEmpty;
}

class MyEventsViewModel extends ViewModel {
  MyEventsViewModel({EventRepository? repository, this.forceEmpty = false})
    : _repository = repository ?? MockEventRepository.shared;

  final EventRepository _repository;
  final bool forceEmpty;

  List<PetEvent> get events => forceEmpty ? const [] : _repository.myEvents();

  bool get isEmpty => events.isEmpty;

  Future<void> cancel(String id) async {
    await _repository.cancelEvent(id);
    notify();
  }

  void refresh() => notify();
}

class CreateEventViewModel extends ViewModel {
  CreateEventViewModel([EventRepository? repository])
    : _repository = repository ?? MockEventRepository.shared;

  final EventRepository _repository;
  bool _saving = false;

  bool get saving => _saving;

  Future<void> save(PetEvent event, {required bool isNew}) async {
    _saving = true;
    notify();
    try {
      if (isNew) {
        await _repository.create(event);
      } else {
        await _repository.update(event);
      }
    } finally {
      _saving = false;
      notify();
    }
  }
}

/// Génération locale et simulée : aucun appel réseau, aucun modèle externe.
class EventAiAssistant {
  EventAiAssistant._();

  static EventAiSuggestion suggest({
    required String title,
    required String description,
    required EventCategory category,
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

    return EventAiSuggestion(
      summary: summary,
      tags: tags.take(6).toList(),
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
