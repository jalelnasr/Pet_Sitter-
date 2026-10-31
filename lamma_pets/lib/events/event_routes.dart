/// Routes nommées du module Événements.
///
/// À brancher dans `lib/app/routes.dart` sans modifier les routes existantes :
/// `final eventRoute = onGenerateEventRoute(settings); if (eventRoute != null) return eventRoute;`
/// (à placer au début de `onGenerateRoute`).
library;

import 'package:flutter/material.dart';

import 'event_mock.dart';
import 'event_models.dart';
import 'event_screens.dart';

class EventRoutes {
  EventRoutes._();
  static const list = '/events';
  static const details = '/event-details';
  static const reservation = '/event-reservation';
  static const myReservations = '/event-reservations';
  static const myEvents = '/my-events';
  static const create = '/event-create';
  static const emptyList = '/events-empty';
  static const emptyReservations = '/event-reservations-empty';
  static const emptyMyEvents = '/my-events-empty';
}

Route<dynamic>? onGenerateEventRoute(RouteSettings settings) {
  final a = settings.arguments;
  final Widget? page = switch (settings.name) {
    EventRoutes.list => const EventsListScreen(),
    EventRoutes.details => EventDetailsScreen(
      event: a is PetEvent ? a : EventMock.events.first,
    ),
    EventRoutes.reservation => EventReservationScreen(
      event: a is PetEvent ? a : EventMock.events.first,
    ),
    EventRoutes.myReservations => const MyEventReservationsScreen(),
    EventRoutes.myEvents => const MyEventsScreen(),
    EventRoutes.create => const CreateEventScreen(),
    EventRoutes.emptyList => const EventsListScreen(forceEmpty: true),
    EventRoutes.emptyReservations => const MyEventReservationsScreen(
      forceEmpty: true,
    ),
    EventRoutes.emptyMyEvents => const MyEventsScreen(forceEmpty: true),
    _ => null,
  };
  if (page == null) return null;
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
