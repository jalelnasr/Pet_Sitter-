import 'package:flutter/material.dart' show DateTimeRange;
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/booking_repository.dart';
import 'package:pet_sitter/data/repositories/pet_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Demande de réservation : animaux, service, dates, instructions, devis.
class BookingRequestViewModel extends ViewModel {
  BookingRequestViewModel({required this.sitter, required BookingRepository bookings, required PetRepository pets})
    : _bookings = bookings,
      pets = pets.myPets() {
    _selected.addAll(this.pets.take(2).where(accepts).map((p) => p.id));
    _service = sitter.mainOffer;
  }

  final Sitter sitter;
  final BookingRepository _bookings;
  final List<Pet> pets;

  final Set<String> _selected = {};
  late SitterService _service;
  DateTimeRange _dates = DateTimeRange(start: DateTime(2026, 10, 23), end: DateTime(2026, 10, 26));
  int _visitsPerDay = 1;
  bool _sending = false;

  /// Instructions laissées au sitter (texte saisi dans l'écran).
  String notes = 'Gouttes pour Simba le matin (flacon dans la trousse). Couvrir la cage de Kiwi vers 21 h.';

  SitterService get service => _service;
  DateTimeRange get dates => _dates;
  int get visitsPerDay => _visitsPerDay;
  bool get sending => _sending;

  bool accepts(Pet p) => sitter.species.contains(p.species);
  bool isSelected(Pet p) => _selected.contains(p.id);
  List<Pet> get selectedPets => pets.where(isSelected).toList();
  bool get canSend => _selected.isNotEmpty;
  bool get isHosting => _service.type == ServiceType.accueil;

  int get nights => _dates.end.difference(_dates.start).inDays;
  int get units => isHosting ? nights : (nights + 1) * _visitsPerDay;
  String get unitsLabel => isHosting ? '$units nuit${units > 1 ? 's' : ''}' : '$units visite${units > 1 ? 's' : ''}';

  /// Le calcul du prix vient du modèle (règles métier), pas de l'écran.
  BookingQuote get quote => BookingQuote(unitPrice: _service.price, units: units, petCount: _selected.length);

  void togglePet(Pet p) {
    if (!accepts(p)) return;
    _selected.contains(p.id) ? _selected.remove(p.id) : _selected.add(p.id);
    notify();
  }

  void setService(SitterService s) {
    _service = s;
    notify();
  }

  void setDates(DateTimeRange r) {
    _dates = r;
    notify();
  }

  void setVisitsPerDay(int v) {
    _visitsPerDay = v;
    notify();
  }

  Future<void> send() async {
    _sending = true;
    notify();
    await _bookings.sendRequest(
      sitter: sitter,
      pets: selectedPets,
      service: _service,
      start: _dates.start,
      end: _dates.end,
      notes: notes,
    );
    _sending = false;
    notify();
  }
}

/// Suivi d'une demande : envoyée → en attente → confirmée.
class BookingStatusViewModel extends ViewModel {
  BookingStatusViewModel(BookingRepository bookings, {BookingStatus status = BookingStatus.envoyee})
    : booking = bookings.all().first,
      _status = status;

  /// La demande suivie (démo : la garde chez Amira).
  final Booking booking;

  BookingStatus _status;
  BookingStatus get status => _status;

  Sitter get sitter => booking.sitter;
  List<Pet> get pets => booking.pets;
  int get total => booking.total;

  bool get isSent => _status == BookingStatus.envoyee;
  bool get isConfirmed => _status == BookingStatus.confirmee;

  /// Étape actuelle de la frise (0, 1 ou 2).
  int get step => switch (_status) {
    BookingStatus.envoyee => 0,
    BookingStatus.attente => 1,
    _ => 2,
  };

  void markPending() {
    _status = BookingStatus.attente;
    notify();
  }

  /// Démo : simule l'acceptation par le sitter.
  void simulateAcceptance() {
    _status = BookingStatus.confirmee;
    notify();
  }
}

/// Onglet Réservations : à venir, en cours, passées.
class BookingsViewModel extends ViewModel {
  BookingsViewModel(this._bookings);
  final BookingRepository _bookings;

  List<Booking> get upcoming =>
      _bookings.all().where((b) => b.status == BookingStatus.confirmee || b.status == BookingStatus.attente).toList();
  List<Booking> get current => _bookings.all().where((b) => b.status == BookingStatus.enCours).toList();
  List<Booking> get past =>
      _bookings.all().where((b) => b.status == BookingStatus.terminee || b.status == BookingStatus.annulee).toList();
}
