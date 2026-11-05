/// Dépôt du module Événements : interface partagée entre Mock et API réelle.
library;

import 'dart:io';

import 'event_api_service.dart';
import 'event_mock.dart';
import 'event_models.dart';

abstract class EventRepository {
  /// Catalogue en mémoire / synchrone (utilisé par l'accueil et les replis).
  List<PetEvent> events();

  /// Tous les événements, y compris brouillons et annulés.
  List<PetEvent> allEvents();

  /// Événements créés par l'utilisateur connecté.
  List<PetEvent> myEvents();

  List<EventReservation> reservations();

  PetEvent? byId(String id);

  Future<void> create(PetEvent event);

  Future<void> update(PetEvent event);

  Future<void> cancelEvent(String id);

  Future<void> delete(String id);

  Future<void> reserve(EventReservation reservation);

  // Méthodes asynchrones pour intégration API

  Future<List<PetEvent>> fetchEvents({
    EventCategory? category,
    String? query,
    bool? upcomingOnly,
    EventStatus? status,
  });

  Future<PetEvent> fetchById(String id);

  Future<List<PetEvent>> fetchMyEvents();

  Future<List<EventReservation>> fetchMyReservations();

  Future<void> cancelReservation(String reservationId);

  Future<String> uploadImage(File file);

  // Méthodes pour le workflow de proposition (rôles PETSITTER et ADMIN)

  Future<PetEvent> submitProposal(PetEvent event);

  Future<PetEvent> updateProposal(String id, PetEvent event);

  Future<void> withdrawProposal(String id);

  Future<List<PetEvent>> fetchMyProposals();

  Future<List<PetEvent>> fetchAllProposals({EventStatus? status});

  Future<PetEvent> approveProposal(String id);

  Future<PetEvent> rejectProposal(String id, String reason);

  Future<List<EventReservation>> fetchEventReservations(String eventId);

  // Assistant IA de rédaction
  Future<EventAiSuggestion> getAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  });
}

class MockEventRepository implements EventRepository {
  MockEventRepository();

  /// Instance partagée par les écrans du module en mode mock.
  static final shared = MockEventRepository();

  final List<PetEvent> _events = List.of(EventMock.events);
  final List<EventReservation> _reservations = List.of(EventMock.reservations);

  @override
  List<PetEvent> allEvents() => List.unmodifiable(_events);

  @override
  List<PetEvent> events() => List.unmodifiable(
    _events.where(
      (event) =>
          event.status == EventStatus.published ||
          event.status == EventStatus.completed,
    ),
  );

  @override
  List<PetEvent> myEvents() =>
      List.unmodifiable(_events.where((event) => event.isMine));

  @override
  List<EventReservation> reservations() => List.unmodifiable(_reservations);

  @override
  PetEvent? byId(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Future<void> create(PetEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _events.insert(0, event);
  }

  @override
  Future<void> update(PetEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      _events.insert(0, event);
    } else {
      _events[index] = event;
    }
  }

  @override
  Future<void> cancelEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _events.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _events[index] = _events[index].copyWith(status: EventStatus.cancelled);
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _events.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> reserve(EventReservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _reservations.insert(0, reservation);
    final index = _events.indexWhere((item) => item.id == reservation.eventId);
    if (index == -1) return;
    final event = _events[index];
    final seats = (event.currentParticipants + reservation.participants).clamp(
      0,
      event.maxParticipants,
    );
    _events[index] = event.copyWith(currentParticipants: seats);
  }

  @override
  Future<List<PetEvent>> fetchEvents({
    EventCategory? category,
    String? query,
    bool? upcomingOnly,
    EventStatus? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query?.trim().toLowerCase() ?? '';
    return _events.where((event) {
      if (category != null && event.category != category) return false;
      if (upcomingOnly == true && event.endDate.isBefore(DateTime.now())) {
        return false;
      }
      if (q.isNotEmpty) {
        final haystack =
            '${event.title} ${event.description} ${event.location} ${event.category.label}'
                .toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      if (status != null) {
        return event.status == status;
      }
      return event.status == EventStatus.published ||
          event.status == EventStatus.completed;
    }).toList();
  }

  @override
  Future<PetEvent> fetchById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final event = byId(id);
    if (event == null) throw Exception('Événement introuvable : $id');
    return event;
  }

  @override
  Future<List<PetEvent>> fetchMyEvents() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return myEvents();
  }

  @override
  Future<List<EventReservation>> fetchMyReservations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return reservations();
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _reservations.indexWhere((r) => r.id == reservationId);
    if (index == -1) return;
    final res = _reservations[index];
    _reservations[index] = res.copyWith(status: ReservationStatus.cancelled);
    final eventIndex = _events.indexWhere((e) => e.id == res.eventId);
    if (eventIndex != -1) {
      final ev = _events[eventIndex];
      _events[eventIndex] = ev.copyWith(
        currentParticipants:
            (ev.currentParticipants - res.participants).clamp(0, ev.maxParticipants),
      );
    }
  }

  @override
  Future<String> uploadImage(File file) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return EventMock.images.first;
  }

  @override
  Future<PetEvent> submitProposal(PetEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final proposal = event.copyWith(status: EventStatus.pending);
    _events.insert(0, proposal);
    return proposal;
  }

  @override
  Future<PetEvent> updateProposal(String id, PetEvent event) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      _events[index] = event;
      return event;
    }
    _events.insert(0, event);
    return event;
  }

  @override
  Future<void> withdrawProposal(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _events.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<PetEvent>> fetchMyProposals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _events.where((e) => e.status == EventStatus.pending || e.status == EventStatus.rejected).toList();
  }

  @override
  Future<List<PetEvent>> fetchAllProposals({EventStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _events.where((e) => e.status == EventStatus.pending || e.status == EventStatus.rejected).toList();
  }

  @override
  Future<PetEvent> approveProposal(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final approved = _events[index].copyWith(status: EventStatus.published);
      _events[index] = approved;
      return approved;
    }
    throw Exception('Proposition introuvable');
  }

  @override
  Future<PetEvent> rejectProposal(String id, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _events.indexWhere((e) => e.id == id);
    if (index != -1) {
      final rejected = _events[index].copyWith(
        status: EventStatus.rejected,
        rejectionReason: reason,
      );
      _events[index] = rejected;
      return rejected;
    }
    throw Exception('Proposition introuvable');
  }

  @override
  Future<List<EventReservation>> fetchEventReservations(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _reservations.where((r) => r.eventId == eventId).toList();
  }

  @override
  Future<EventAiSuggestion> getAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cat = EventCategoryX.fromString(category);
    return EventAiAssistant.suggest(
      title: title,
      description: description ?? '',
      category: cat,
      keywords: keywords,
      location: location,
    );
  }
}

class ApiEventRepository implements EventRepository {
  ApiEventRepository({EventApiService? api})
      : _api = api ?? EventApiService.shared;

  /// Instance partagée par les écrans du module en mode API.
  static final ApiEventRepository shared = ApiEventRepository();

  final EventApiService _api;

  List<PetEvent> _cachedEvents = [];
  List<PetEvent> _cachedMyEvents = [];
  List<EventReservation> _cachedReservations = [];

  @override
  List<PetEvent> events() => List.unmodifiable(_cachedEvents);

  @override
  List<PetEvent> allEvents() => List.unmodifiable(_cachedEvents);

  @override
  List<PetEvent> myEvents() => List.unmodifiable(_cachedMyEvents);

  @override
  List<EventReservation> reservations() =>
      List.unmodifiable(_cachedReservations);

  @override
  PetEvent? byId(String id) {
    for (final event in _cachedEvents) {
      if (event.id == id) return event;
    }
    for (final event in _cachedMyEvents) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Future<List<PetEvent>> fetchEvents({
    EventCategory? category,
    String? query,
    bool? upcomingOnly,
    EventStatus? status,
  }) async {
    final list = await _api.fetchEvents(
      category: category,
      search: query,
      upcomingOnly: upcomingOnly,
      status: status,
    );
    _cachedEvents = list;
    return list;
  }

  @override
  Future<PetEvent> fetchById(String id) async {
    final event = await _api.fetchEvent(id);
    final idx = _cachedEvents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _cachedEvents[idx] = event;
    }
    return event;
  }

  @override
  Future<List<PetEvent>> fetchMyEvents() async {
    final list = await _api.fetchMine();
    _cachedMyEvents = list;
    return list;
  }

  @override
  Future<List<EventReservation>> fetchMyReservations() async {
    final list = await _api.fetchMyReservations();
    _cachedReservations = list;
    return list;
  }

  @override
  Future<void> create(PetEvent event) async {
    final created = await _api.createEvent(event);
    _cachedEvents.insert(0, created);
    _cachedMyEvents.insert(0, created);
  }

  @override
  Future<void> update(PetEvent event) async {
    final updated = await _api.updateEvent(event.id, event);
    final idx = _cachedEvents.indexWhere((e) => e.id == event.id);
    if (idx != -1) _cachedEvents[idx] = updated;
    final myIdx = _cachedMyEvents.indexWhere((e) => e.id == event.id);
    if (myIdx != -1) _cachedMyEvents[myIdx] = updated;
  }

  @override
  Future<void> cancelEvent(String id) async {
    final cancelled = await _api.cancelEvent(id);
    final idx = _cachedEvents.indexWhere((e) => e.id == id);
    if (idx != -1) _cachedEvents[idx] = cancelled;
    final myIdx = _cachedMyEvents.indexWhere((e) => e.id == id);
    if (myIdx != -1) _cachedMyEvents[myIdx] = cancelled;
  }

  @override
  Future<void> delete(String id) async {
    await _api.deleteEvent(id);
    _cachedEvents.removeWhere((e) => e.id == id);
    _cachedMyEvents.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> reserve(EventReservation reservation) async {
    final created = await _api.reserve(
      eventId: reservation.eventId,
      participantName: reservation.participantName,
      phone: reservation.phone.isNotEmpty ? reservation.phone : 'N/A',
      numberOfPlaces: reservation.participants,
      comment: reservation.comment,
    );
    _cachedReservations.insert(0, created);
  }

  Future<EventReservation> reserveDetails({
    required String eventId,
    required String participantName,
    required String phone,
    required int numberOfPlaces,
    String? comment,
  }) async {
    final res = await _api.reserve(
      eventId: eventId,
      participantName: participantName,
      phone: phone,
      numberOfPlaces: numberOfPlaces,
      comment: comment,
    );
    _cachedReservations.insert(0, res);
    return res;
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    final cancelled = await _api.cancelReservation(reservationId);
    final idx = _cachedReservations.indexWhere((r) => r.id == reservationId);
    if (idx != -1) _cachedReservations[idx] = cancelled;
  }

  @override
  Future<String> uploadImage(File file) => _api.uploadImage(file);

  @override
  Future<PetEvent> submitProposal(PetEvent event) => _api.submitProposal(event);

  @override
  Future<PetEvent> updateProposal(String id, PetEvent event) => _api.updateProposal(id, event);

  @override
  Future<void> withdrawProposal(String id) => _api.withdrawProposal(id);

  @override
  Future<List<PetEvent>> fetchMyProposals() => _api.fetchMyProposals();

  @override
  Future<List<PetEvent>> fetchAllProposals({EventStatus? status}) =>
      _api.fetchAllProposals(status: status);

  @override
  Future<PetEvent> approveProposal(String id) => _api.approveProposal(id);

  @override
  Future<PetEvent> rejectProposal(String id, String reason) => _api.rejectProposal(id, reason);

  @override
  Future<List<EventReservation>> fetchEventReservations(String eventId) =>
      _api.fetchEventReservations(eventId);

  @override
  Future<EventAiSuggestion> getAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) =>
      _api.getAiSuggestion(
        title: title,
        keywords: keywords,
        category: category,
        location: location,
        description: description,
      );
}
