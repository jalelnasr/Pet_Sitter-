import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/data/repositories/sitter_space_repository.dart';
import 'package:pet_sitter/models/models.dart';

/// Tableau de bord du sitter : demandes reçues (accepter / refuser), gardes à venir.
class SitterDashboardViewModel extends ViewModel {
  SitterDashboardViewModel(SitterSpaceRepository repo)
    : me = repo.me,
      requests = repo.requests(),
      upcoming = repo.upcoming();

  final Sitter me;
  final List<SitterRequest> requests;
  final List<UpcomingCare> upcoming;

  int get pendingCount => requests.where((r) => r.state == RequestState.pending).length;

  void accept(SitterRequest r) {
    r.state = RequestState.accepted;
    notify();
  }

  void refuse(SitterRequest r) {
    r.state = RequestState.refused;
    notify();
  }
}

/// Calendrier de disponibilité et règles de réservation.
class AvailabilityViewModel extends ViewModel {
  AvailabilityViewModel(SitterSpaceRepository repo) : _off = repo.unavailableDays(), _booked = repo.bookedDays();

  final Map<int, Set<int>> _off;
  final Map<int, Set<int>> _booked;

  int _month = 0; // 0 = octobre 2026, 1 = novembre 2026
  int get month => _month;
  String get monthLabel => _month == 0 ? 'Octobre 2026' : 'Novembre 2026';
  DateTime get monthDate => DateTime(2026, 10 + _month);
  bool get canGoBack => _month > 0;
  bool get canGoForward => _month < 1;

  Set<int> get off => _off[_month]!;
  Set<int> get booked => _booked[_month]!;

  int _maxPets = 3;
  int get maxPets => _maxPets;

  String _notice = '24 h';
  String get notice => _notice;

  bool _lastMinute = true;
  bool get lastMinute => _lastMinute;

  void previousMonth() {
    if (!canGoBack) return;
    _month--;
    notify();
  }

  void nextMonth() {
    if (!canGoForward) return;
    _month++;
    notify();
  }

  /// Un jour réservé ne peut pas être modifié.
  void toggleDay(int day) {
    if (booked.contains(day)) return;
    off.contains(day) ? off.remove(day) : off.add(day);
    notify();
  }

  void openAll() {
    off.clear();
    notify();
  }

  void blockWeekends() {
    final days = DateTime(2026, 11 + _month, 0).day;
    for (var d = 1; d <= days; d++) {
      if (DateTime(2026, 10 + _month, d).weekday >= 6 && !booked.contains(d)) off.add(d);
    }
    notify();
  }

  void setMaxPets(int v) {
    _maxPets = v;
    notify();
  }

  void setNotice(String v) {
    _notice = v;
    notify();
  }

  void setLastMinute(bool v) {
    _lastMinute = v;
    notify();
  }
}

/// Services proposés, tarifs, espèces acceptées.
class ServicesPricingViewModel extends ViewModel {
  ServicesPricingViewModel(this._repo) : services = _repo.services();

  final SitterSpaceRepository _repo;
  final List<EditableService> services;
  final Set<Species> species = {Species.chat, Species.lapin, Species.oiseau, Species.autre};

  int _extraPetFee = 10;
  int get extraPetFee => _extraPetFee;

  bool _saving = false;
  bool get saving => _saving;

  void toggleService(EditableService s, bool on) {
    s.on = on;
    notify();
  }

  void setPrice(EditableService s, int price) {
    s.price = price;
    notify();
  }

  void setExtraPetFee(int v) {
    _extraPetFee = v;
    notify();
  }

  void toggleSpecies(Species s) {
    species.contains(s) ? species.remove(s) : species.add(s);
    notify();
  }

  Future<void> save() async {
    _saving = true;
    notify();
    await _repo.saveServices(services);
    _saving = false;
    notify();
  }
}
