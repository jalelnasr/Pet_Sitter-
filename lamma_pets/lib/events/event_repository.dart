/// Dépôt local du module Événements : aucune API, aucune base de données.
library;

import 'event_mock.dart';
import 'event_models.dart';

abstract class EventRepository {
  /// Catalogue affiché dans la liste : événements publiés et terminés.
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

  Future<void> reserve(EventReservation reservation);
}

class MockEventRepository implements EventRepository {
  MockEventRepository();

  /// Instance partagée par les écrans du module, sans toucher à `Deps`.
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
    await Future.delayed(const Duration(milliseconds: 800));
    _events.insert(0, event);
  }

  @override
  Future<void> update(PetEvent event) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index == -1) {
      _events.insert(0, event);
    } else {
      _events[index] = event;
    }
  }

  @override
  Future<void> cancelEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _events.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _events[index] = _events[index].copyWith(status: EventStatus.cancelled);
  }

  @override
  Future<void> reserve(EventReservation reservation) async {
    await Future.delayed(const Duration(milliseconds: 900));
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
}
