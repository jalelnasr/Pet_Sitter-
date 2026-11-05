/// ViewModels du module Événements : état d'écran et logique légère.
library;

import 'dart:io';

import 'package:pet_sitter/adoption/api/api_client.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';

import 'event_models.dart';
import 'event_repository.dart';

String eventErrorMessage(Object error) {
  if (error is ApiException) return error.message;
  final str = error.toString();
  if (str.contains('Exception:')) {
    return str.replaceFirst('Exception:', '').trim();
  }
  return 'Une erreur est survenue. Veuillez réessayer.';
}

class EventListViewModel extends ViewModel {
  EventListViewModel(EventRepository repository, {this.forceEmpty = false})
      : _repository = repository {
    load();
  }

  final EventRepository _repository;
  final bool forceEmpty;

  List<PetEvent> _events = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  String _query = '';
  EventCategory? _category;

  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;
  String get query => _query;
  EventCategory? get category => _category;
  bool get hasFilters => _query.trim().isNotEmpty || _category != null;
  int get activeFilterCount =>
      (_query.trim().isEmpty ? 0 : 1) + (_category == null ? 0 : 1);

  List<PetEvent> get results {
    if (forceEmpty) return const [];
    final q = _query.trim().toLowerCase();
    return _events.where((event) {
      final sameCategory = _category == null || event.category == _category;
      if (!sameCategory) return false;
      if (q.isEmpty) return true;
      final haystack =
          '${event.title} ${event.description} ${event.location} ${event.category.label}'
              .toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> load({bool refresh = false}) async {
    if (forceEmpty) {
      _loading = false;
      _refreshing = false;
      _events = const [];
      notify();
      return;
    }
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();

    try {
      _events = await _repository.fetchEvents(category: _category);
    } catch (e) {
      _error = eventErrorMessage(e);
      if (_events.isEmpty) {
        _events = _repository.events();
      }
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  void setQuery(String value) {
    _query = value;
    notify();
  }

  void setCategory(EventCategory? value) {
    if (_category == value) return;
    _category = value;
    notify();
    load();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    notify();
    load();
  }

  /// Rafraîchit après une création, une modification ou une annulation.
  void refresh() => load(refresh: true);
}

class EventDetailsViewModel extends ViewModel {
  EventDetailsViewModel(
    this._repository,
    this.eventId, {
    PetEvent? initial,
  }) : _event = initial {
    load();
  }

  final EventRepository _repository;
  final String eventId;

  PetEvent? _event;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  PetEvent? get event => _event ?? _repository.byId(eventId);
  bool get loading => _loading;
  bool get actionLoading => _actionLoading;
  String? get error => _error;

  bool get canReserve =>
      event != null && event!.status.isOpen && !event!.isFull;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();

    try {
      _event = await _repository.fetchById(eventId);
    } catch (e) {
      _error = eventErrorMessage(e);
      _event ??= _repository.byId(eventId);
    } finally {
      _loading = false;
      notify();
    }
  }

  Future<void> cancelEvent() async {
    _actionLoading = true;
    _error = null;
    notify();
    try {
      await _repository.cancelEvent(eventId);
      await load();
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _actionLoading = false;
      notify();
    }
  }

  Future<void> deleteEvent() async {
    _actionLoading = true;
    _error = null;
    notify();
    try {
      await _repository.delete(eventId);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _actionLoading = false;
      notify();
    }
  }

  void refresh() => load();
}

class EventReservationViewModel extends ViewModel {
  EventReservationViewModel([EventRepository? repository])
      : _repository = repository ?? ApiEventRepository.shared;

  final EventRepository _repository;
  bool _sending = false;
  String? _error;

  bool get sending => _sending;
  String? get error => _error;

  Future<EventReservation> reserve({
    required PetEvent event,
    required String fullName,
    required String phone,
    required int participants,
    required String comment,
  }) async {
    _sending = true;
    _error = null;
    notify();

    try {
      if (_repository is ApiEventRepository) {
        return await (_repository as ApiEventRepository).reserveDetails(
          eventId: event.id,
          participantName: fullName,
          phone: phone,
          numberOfPlaces: participants,
          comment: comment,
        );
      } else {
        final reservation = EventReservation(
          id: 'event-reservation-${DateTime.now().microsecondsSinceEpoch}',
          eventId: event.id,
          participantName: fullName,
          phone: phone,
          reservationDate: DateTime.now(),
          status: ReservationStatus.confirmed,
          participants: participants,
          comment: comment,
        );
        await _repository.reserve(reservation);
        return reservation;
      }
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
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
  }) : _repository = repository ?? ApiEventRepository.shared {
    load();
  }

  final EventRepository _repository;
  final bool forceEmpty;

  List<EventReservationItem> _items = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<EventReservationItem> get items => forceEmpty ? const [] : _items;
  bool get isEmpty => items.isEmpty;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (forceEmpty) {
      _loading = false;
      _items = const [];
      notify();
      return;
    }
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();

    try {
      final reservations = await _repository.fetchMyReservations();
      final list = <EventReservationItem>[];
      for (final res in reservations) {
        PetEvent? ev = res.event ?? _repository.byId(res.eventId);
        if (ev == null) {
          try {
            ev = await _repository.fetchById(res.eventId);
          } catch (_) {}
        }
        if (ev != null) {
          list.add(EventReservationItem(reservation: res, event: ev));
        }
      }
      _items = list;
    } catch (e) {
      _error = eventErrorMessage(e);
      if (_items.isEmpty) {
        final list = <EventReservationItem>[];
        for (final res in _repository.reservations()) {
          final ev = _repository.byId(res.eventId);
          if (ev != null) list.add(EventReservationItem(reservation: res, event: ev));
        }
        _items = list;
      }
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<void> cancel(String reservationId) async {
    try {
      await _repository.cancelReservation(reservationId);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }
}

class MyEventsViewModel extends ViewModel {
  MyEventsViewModel({EventRepository? repository, this.forceEmpty = false})
      : _repository = repository ?? ApiEventRepository.shared {
    load();
  }

  final EventRepository _repository;
  final bool forceEmpty;

  List<PetEvent> _events = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<PetEvent> get events => forceEmpty ? const [] : _events;
  bool get isEmpty => events.isEmpty;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (forceEmpty) {
      _loading = false;
      _events = const [];
      notify();
      return;
    }
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();

    try {
      _events = await _repository.fetchMyEvents();
    } catch (e) {
      _error = eventErrorMessage(e);
      if (_events.isEmpty) {
        _events = _repository.myEvents();
      }
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _repository.cancelEvent(id);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }

  void refresh() => load(refresh: true);
}

class CreateEventViewModel extends ViewModel {
  CreateEventViewModel([EventRepository? repository])
      : _repository = repository ?? ApiEventRepository.shared;

  final EventRepository _repository;
  bool _saving = false;
  String? _error;

  bool get saving => _saving;
  String? get error => _error;

  Future<void> save(PetEvent event, {required bool isNew}) async {
    _saving = true;
    _error = null;
    notify();
    try {
      if (isNew) {
        await _repository.create(event);
      } else {
        await _repository.update(event);
      }
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _saving = false;
      notify();
    }
  }

  Future<String> uploadImage(File file) async {
    return await _repository.uploadImage(file);
  }

  // ————————————————————————————————————————————— ASSISTANT IA

  bool _aiLoading = false;
  String? _aiError;
  EventAiSuggestion? _aiSuggestion;

  bool get aiLoading => _aiLoading;
  String? get aiError => _aiError;
  EventAiSuggestion? get aiSuggestion => _aiSuggestion;

  Future<EventAiSuggestion> fetchAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) async {
    _aiLoading = true;
    _aiError = null;
    notify();
    try {
      final res = await _repository.getAiSuggestion(
        title: title,
        keywords: keywords,
        category: category,
        location: location,
        description: description,
      );
      _aiSuggestion = res;
      return res;
    } catch (e) {
      _aiError = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _aiLoading = false;
      notify();
    }
  }
}

class EventAiViewModel extends ViewModel {
  EventAiViewModel([EventRepository? repository])
      : _repository = repository ?? ApiEventRepository.shared;

  final EventRepository _repository;
  bool _loading = false;
  String? _error;
  EventAiSuggestion? _suggestion;

  bool get loading => _loading;
  String? get error => _error;
  EventAiSuggestion? get suggestion => _suggestion;

  Future<EventAiSuggestion> fetch({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) async {
    _loading = true;
    _error = null;
    notify();
    try {
      final res = await _repository.getAiSuggestion(
        title: title,
        keywords: keywords,
        category: category,
        location: location,
        description: description,
      );
      _suggestion = res;
      return res;
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _loading = false;
      notify();
    }
  }
}

// ==========================================
// ViewModels pour les propositions
// ==========================================

class MyProposalsViewModel extends ViewModel {
  MyProposalsViewModel({EventRepository? repository})
      : _repository = repository ?? ApiEventRepository.shared {
    load();
  }

  final EventRepository _repository;
  List<PetEvent> _proposals = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<PetEvent> get proposals => _proposals;
  bool get isEmpty => _proposals.isEmpty;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();

    try {
      _proposals = await _repository.fetchMyProposals();
    } catch (e) {
      _error = eventErrorMessage(e);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<void> withdraw(String id) async {
    try {
      await _repository.withdrawProposal(id);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }

  void refresh() => load(refresh: true);
}

class ProposalsViewModel extends ViewModel {
  ProposalsViewModel({EventRepository? repository})
      : _repository = repository ?? ApiEventRepository.shared {
    load();
  }

  final EventRepository _repository;
  List<PetEvent> _proposals = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  List<PetEvent> get proposals => _proposals;
  bool get isEmpty => _proposals.isEmpty;
  bool get loading => _loading;
  bool get refreshing => _refreshing;
  String? get error => _error;

  Future<void> load({bool refresh = false}) async {
    if (refresh) {
      _refreshing = true;
    } else {
      _loading = true;
    }
    _error = null;
    notify();

    try {
      _proposals = await _repository.fetchAllProposals();
    } catch (e) {
      _error = eventErrorMessage(e);
    } finally {
      _loading = false;
      _refreshing = false;
      notify();
    }
  }

  Future<void> approve(String id) async {
    try {
      await _repository.approveProposal(id);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }

  Future<void> reject(String id, String reason) async {
    try {
      await _repository.rejectProposal(id, reason);
      await load(refresh: true);
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    }
  }

  void refresh() => load(refresh: true);
}

class ProposalFormViewModel extends ViewModel {
  ProposalFormViewModel([EventRepository? repository])
      : _repository = repository ?? ApiEventRepository.shared;

  final EventRepository _repository;
  bool _saving = false;
  String? _error;

  bool get saving => _saving;
  String? get error => _error;

  Future<void> submit(PetEvent event, {required bool isNew}) async {
    _saving = true;
    _error = null;
    notify();
    try {
      if (isNew) {
        await _repository.submitProposal(event);
      } else {
        await _repository.updateProposal(event.id, event);
      }
    } catch (e) {
      _error = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _saving = false;
      notify();
    }
  }

  Future<String> uploadImage(File file) async {
    return await _repository.uploadImage(file);
  }

  // ————————————————————————————————————————————— ASSISTANT IA

  bool _aiLoading = false;
  String? _aiError;
  EventAiSuggestion? _aiSuggestion;

  bool get aiLoading => _aiLoading;
  String? get aiError => _aiError;
  EventAiSuggestion? get aiSuggestion => _aiSuggestion;

  Future<EventAiSuggestion> fetchAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) async {
    _aiLoading = true;
    _aiError = null;
    notify();
    try {
      final res = await _repository.getAiSuggestion(
        title: title,
        keywords: keywords,
        category: category,
        location: location,
        description: description,
      );
      _aiSuggestion = res;
      return res;
    } catch (e) {
      _aiError = eventErrorMessage(e);
      notify();
      rethrow;
    } finally {
      _aiLoading = false;
      notify();
    }
  }
}

class EventParticipantsViewModel extends ViewModel {
  EventParticipantsViewModel(this.eventId, [EventRepository? repository])
      : _repository = repository ?? ApiEventRepository.shared {
    load();
  }

  final String eventId;
  final EventRepository _repository;

  List<EventReservation> _reservations = const [];
  bool _loading = true;
  String? _error;

  List<EventReservation> get reservations => _reservations;
  bool get isEmpty => _reservations.isEmpty;
  bool get loading => _loading;
  String? get error => _error;

  int get totalPlaces =>
      _reservations.fold(0, (sum, r) => sum + (r.status == ReservationStatus.confirmed ? r.participants : 0));

  Future<void> load() async {
    _loading = true;
    _error = null;
    notify();
    try {
      _reservations = await _repository.fetchEventReservations(eventId);
    } catch (e) {
      _error = eventErrorMessage(e);
    } finally {
      _loading = false;
      notify();
    }
  }
}
