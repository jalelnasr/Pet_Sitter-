import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';
import 'package:pet_sitter/petsitter/petsitter_repository.dart';

// ==========================================
// 1. SITTER LIST VIEWMODEL (OWNER BROWSE)
// ==========================================

class SitterListViewModel extends ViewModel {
  SitterListViewModel({PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    load();
  }

  final PetSitterRepository _repo;

  List<PetSitter> _sitters = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _search = '';
  String? _governorate;
  SitterServiceType? _service;
  PetSpeciesType? _petType;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool _verifiedOnly = false;
  String _sortBy = 'rating';

  List<PetSitter> get sitters => _sitters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get search => _search;
  String? get governorate => _governorate;
  SitterServiceType? get service => _service;
  PetSpeciesType? get petType => _petType;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  bool get verifiedOnly => _verifiedOnly;
  String get sortBy => _sortBy;

  int get activeFiltersCount {
    int count = 0;
    if (_governorate != null && _governorate!.isNotEmpty) count++;
    if (_service != null) count++;
    if (_petType != null) count++;
    if (_minPrice != null || _maxPrice != null) count++;
    if (_minRating != null) count++;
    if (_verifiedOnly) count++;
    return count;
  }

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notify();

    try {
      _sitters = await _repo.getSitters(
        search: _search,
        governorate: _governorate,
        service: _service,
        petType: _petType,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        verifiedOnly: _verifiedOnly ? true : null,
        sortBy: _sortBy,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  void setSearch(String query) {
    _search = query;
    load();
  }

  void setFilters({
    String? governorate,
    SitterServiceType? service,
    PetSpeciesType? petType,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? verifiedOnly,
    String? sortBy,
  }) {
    _governorate = governorate;
    _service = service;
    _petType = petType;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    if (verifiedOnly != null) _verifiedOnly = verifiedOnly;
    if (sortBy != null) _sortBy = sortBy;
    load();
  }

  void resetFilters() {
    _search = '';
    _governorate = null;
    _service = null;
    _petType = null;
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _verifiedOnly = false;
    _sortBy = 'rating';
    load();
  }
}

// ==========================================
// 2. SITTER DETAILS VIEWMODEL
// ==========================================

class SitterDetailsViewModel extends ViewModel {
  SitterDetailsViewModel({required this.sitterId, PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    load();
  }

  final String sitterId;
  final PetSitterRepository _repo;

  PetSitter? _sitter;
  List<SitterReview> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  PetSitter? get sitter => _sitter;
  List<SitterReview> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notify();

    try {
      final results = await Future.wait([
        _repo.getSitterById(sitterId),
        _repo.getReviews(sitterId),
      ]);
      _sitter = results[0] as PetSitter;
      _reviews = results[1] as List<SitterReview>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> addReview({
    String? reservationId,
    required int rating,
    required String comment,
  }) async {
    await _repo.addReview(
      sitterId,
      reservationId: reservationId,
      rating: rating,
      comment: comment,
    );
    await load();
  }
}

// ==========================================
// 3. RESERVATION FORM VIEWMODEL
// ==========================================

class ReservationFormViewModel extends ViewModel {
  ReservationFormViewModel({required this.sitter, PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    _service = sitter.services.isNotEmpty
        ? sitter.services.first
        : SitterServiceType.boarding;
    _petType = sitter.acceptedPetTypes.isNotEmpty
        ? sitter.acceptedPetTypes.first
        : PetSpeciesType.dog;
    _petSize = sitter.acceptedSizes.isNotEmpty
        ? sitter.acceptedSizes.first
        : PetSizeType.small;
  }

  final PetSitter sitter;
  final PetSitterRepository _repo;

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  String _petName = '';
  late PetSpeciesType _petType;
  late PetSizeType _petSize;
  late SitterServiceType _service;
  String _notes = '';

  bool _isSubmitting = false;
  String? _errorMessage;

  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  TimeOfDay? get startTime => _startTime;
  TimeOfDay? get endTime => _endTime;
  String get petName => _petName;
  PetSpeciesType get petType => _petType;
  PetSizeType get petSize => _petSize;
  SitterServiceType get service => _service;
  String get notes => _notes;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  int get daysCount {
    final diff = _endDate.difference(_startDate).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  double get calculatedTotalPrice {
    if (_startTime != null && _endTime != null) {
      final hours = _endTime!.hour - _startTime!.hour;
      final effectiveHours = hours <= 0 ? 1 : hours;
      return daysCount * effectiveHours * sitter.pricePerHour;
    }
    return daysCount * sitter.pricePerDay;
  }

  void setDates(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    notify();
  }

  void setTimes(TimeOfDay? start, TimeOfDay? end) {
    _startTime = start;
    _endTime = end;
    notify();
  }

  void setPetName(String val) {
    _petName = val;
    notify();
  }

  void setPetType(PetSpeciesType val) {
    _petType = val;
    notify();
  }

  void setPetSize(PetSizeType val) {
    _petSize = val;
    notify();
  }

  void setService(SitterServiceType val) {
    _service = val;
    notify();
  }

  void setNotes(String val) {
    _notes = val;
    notify();
  }

  Future<SitterReservation?> submit() async {
    if (_petName.trim().isEmpty) {
      _errorMessage = "Veuillez renseigner le nom de votre animal.";
      notify();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notify();

    try {
      final res = await _repo.createReservation(
        sitterId: sitter.id,
        petName: _petName.trim(),
        petType: _petType,
        petSize: _petSize,
        service: _service,
        startDate: _startDate,
        endDate: _endDate,
        startTime: _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        endTime: _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00'
            : null,
        notes: _notes.trim().isEmpty ? null : _notes.trim(),
      );
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notify();
    }
  }
}

// ==========================================
// 4. MY RESERVATIONS VIEWMODEL (OWNER)
// ==========================================

class MyReservationsViewModel extends ViewModel {
  MyReservationsViewModel({PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    load();
  }

  final PetSitterRepository _repo;

  List<SitterReservation> _all = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SitterReservation> get reservations => _all;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<SitterReservation> get pending =>
      _all.where((r) => r.status == ReservationStatus.pending).toList();

  List<SitterReservation> get accepted =>
      _all.where((r) => r.status == ReservationStatus.accepted).toList();

  List<SitterReservation> get completed =>
      _all.where((r) => r.status == ReservationStatus.completed).toList();

  List<SitterReservation> get other => _all
      .where((r) =>
          r.status == ReservationStatus.rejected ||
          r.status == ReservationStatus.cancelled)
      .toList();

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notify();

    try {
      _all = await _repo.getMyReservations();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> cancel(String id) async {
    await _repo.cancelReservation(id);
    await load();
  }

  Future<void> addReview(String sitterId, String reservationId, int rating, String comment) async {
    await _repo.addReview(sitterId, reservationId: reservationId, rating: rating, comment: comment);
    await load();
  }
}

// ==========================================
// 5. SITTER SPACE VIEWMODEL (SITTER DASHBOARD)
// ==========================================

class SitterSpaceViewModel extends ViewModel {
  SitterSpaceViewModel({PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    load();
  }

  final PetSitterRepository _repo;

  PetSitter? _profile;
  List<SitterReservation> _incoming = [];
  List<SitterReview> _reviews = [];
  bool _isLoading = false;
  String? _errorMessage;

  PetSitter? get profile => _profile;
  List<SitterReservation> get incoming => _incoming;
  List<SitterReview> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get pendingCount =>
      _incoming.where((r) => r.status == ReservationStatus.pending).length;

  int get upcomingCount =>
      _incoming.where((r) => r.status == ReservationStatus.accepted).length;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notify();

    try {
      _profile = await _repo.getMyProfile();
      _incoming = await _repo.getIncomingReservations();
      if (_profile != null) {
        _reviews = await _repo.getReviews(_profile!.id);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> accept(String id) async {
    await _repo.acceptReservation(id);
    await load();
  }

  Future<void> reject(String id, String reason) async {
    await _repo.rejectReservation(id, reason);
    await load();
  }

  Future<void> complete(String id) async {
    await _repo.completeReservation(id);
    await load();
  }

  Future<void> toggleVisibility() async {
    if (_profile == null) return;
    _profile = await _repo.toggleVisibility(_profile!.id);
    notify();
  }
}

// ==========================================
// 6. SITTER PROFILE FORM VIEWMODEL
// ==========================================

class SitterProfileFormViewModel extends ViewModel {
  SitterProfileFormViewModel({this.initialProfile, PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    if (initialProfile != null) {
      _initFromProfile(initialProfile!);
    }
  }

  final PetSitter? initialProfile;
  final PetSitterRepository _repo;

  String fullName = '';
  String bio = '';
  String governorate = 'Tunis';
  String city = 'La Marsa';
  String address = '';
  String phone = '';
  String photoUrl = '';
  int experienceYears = 2;
  double pricePerHour = 12.0;
  double pricePerDay = 35.0;
  Set<SitterServiceType> services = {
    SitterServiceType.boarding,
    SitterServiceType.walking,
  };
  Set<PetSpeciesType> acceptedPetTypes = {
    PetSpeciesType.dog,
    PetSpeciesType.cat,
  };
  Set<PetSizeType> acceptedSizes = {
    PetSizeType.small,
    PetSizeType.medium,
  };
  bool hasGarden = false;
  bool hasOwnPets = false;
  String availability = 'Tous les jours';

  bool isUploading = false;
  bool isSaving = false;
  String? errorMessage;

  void _initFromProfile(PetSitter p) {
    fullName = p.fullName;
    bio = p.bio;
    governorate = p.governorate;
    city = p.city;
    address = p.address;
    phone = p.phone;
    photoUrl = p.photoUrl;
    experienceYears = p.experienceYears;
    pricePerHour = p.pricePerHour;
    pricePerDay = p.pricePerDay;
    services = Set.from(p.services);
    acceptedPetTypes = Set.from(p.acceptedPetTypes);
    acceptedSizes = Set.from(p.acceptedSizes);
    hasGarden = p.hasGarden;
    hasOwnPets = p.hasOwnPets;
    availability = p.availability;
  }

  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    isUploading = true;
    errorMessage = null;
    notify();

    try {
      final url = await _repo.uploadImage(File(picked.path));
      photoUrl = url;
    } catch (e) {
      errorMessage = "Erreur upload : $e";
    } finally {
      isUploading = false;
      notify();
    }
  }

  Future<PetSitter?> save() async {
    if (fullName.trim().isEmpty) {
      errorMessage = "Le nom complet est obligatoire.";
      notify();
      return null;
    }

    isSaving = true;
    errorMessage = null;
    notify();

    final payload = {
      'fullName': fullName.trim(),
      'bio': bio.trim(),
      'governorate': governorate.trim(),
      'city': city.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'photoUrl': photoUrl.trim(),
      'experienceYears': experienceYears,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'services': services.map((s) => s.apiValue).toList(),
      'acceptedPetTypes': acceptedPetTypes.map((p) => p.apiValue).toList(),
      'acceptedSizes': acceptedSizes.map((s) => s.apiValue).toList(),
      'hasGarden': hasGarden,
      'hasOwnPets': hasOwnPets,
      'availability': availability.trim(),
    };

    try {
      if (initialProfile != null) {
        return await _repo.updateProfile(initialProfile!.id, payload);
      } else {
        return await _repo.createProfile(payload);
      }
    } catch (e) {
      errorMessage = e.toString();
      return null;
    } finally {
      isSaving = false;
      notify();
    }
  }
}

// ==========================================
// 7. ADMIN SITTERS VIEWMODEL
// ==========================================

class AdminSittersViewModel extends ViewModel {
  AdminSittersViewModel({PetSitterRepository? repository})
      : _repo = repository ?? PetSitterRepository.instance {
    load();
  }

  final PetSitterRepository _repo;

  List<PetSitter> _sitters = [];
  List<SitterReservation> _reservations = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _errorMessage;

  List<PetSitter> get sitters => _sitters;
  List<SitterReservation> get reservations => _reservations;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notify();

    try {
      final res = await Future.wait([
        _repo.getAdminSitters(),
        _repo.getAdminReservations(),
        _repo.getAdminStats(),
      ]);
      _sitters = res[0] as List<PetSitter>;
      _reservations = res[1] as List<SitterReservation>;
      _stats = res[2] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notify();
    }
  }

  Future<void> setVerification(String id, bool verified) async {
    await _repo.setSitterVerification(id, verified);
    await load();
  }

  Future<void> setActive(String id, bool active) async {
    await _repo.setSitterActive(id, active);
    await load();
  }

  Future<void> deleteSitter(String id) async {
    await _repo.deleteSitterAdmin(id);
    await load();
  }

  Future<void> deleteReservation(String id) async {
    await _repo.deleteReservationAdmin(id);
    await load();
  }
}
