import 'dart:io';

import 'package:pet_sitter/petsitter/petsitter_api_service.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';

class PetSitterRepository {
  PetSitterRepository({PetSitterApiService? api}) : _api = api ?? PetSitterApiService();

  static final PetSitterRepository instance = PetSitterRepository();

  final PetSitterApiService _api;

  PetSitterApiService get api => _api;

  // Sitters
  Future<List<PetSitter>> getSitters({
    String? search,
    String? governorate,
    SitterServiceType? service,
    PetSpeciesType? petType,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? verifiedOnly,
    String? sortBy,
    int page = 0,
    int size = 30,
  }) => _api.getSitters(
    search: search,
    governorate: governorate,
    service: service,
    petType: petType,
    minPrice: minPrice,
    maxPrice: maxPrice,
    minRating: minRating,
    verifiedOnly: verifiedOnly,
    sortBy: sortBy,
    page: page,
    size: size,
  );

  Future<PetSitter> getSitterById(String id) => _api.getSitterById(id);

  Future<PetSitter?> getMyProfile() => _api.getMyProfile();

  Future<PetSitter> createProfile(Map<String, dynamic> payload) => _api.createSitterProfile(payload);

  Future<PetSitter> updateProfile(String id, Map<String, dynamic> payload) => _api.updateSitterProfile(id, payload);

  Future<PetSitter> toggleVisibility(String id) => _api.toggleVisibility(id);

  Future<void> deleteProfile(String id) => _api.deleteSitterProfile(id);

  Future<String> uploadImage(File file) => _api.uploadImage(file);

  // Reservations
  Future<SitterReservation> createReservation({
    required String sitterId,
    required String petName,
    required PetSpeciesType petType,
    required PetSizeType petSize,
    required SitterServiceType service,
    required DateTime startDate,
    required DateTime endDate,
    String? startTime,
    String? endTime,
    String? notes,
  }) => _api.createReservation(
    sitterId: sitterId,
    petName: petName,
    petType: petType,
    petSize: petSize,
    service: service,
    startDate: startDate,
    endDate: endDate,
    startTime: startTime,
    endTime: endTime,
    notes: notes,
  );

  Future<List<SitterReservation>> getMyReservations() => _api.getMyReservations();

  Future<List<SitterReservation>> getIncomingReservations() => _api.getIncomingReservations();

  Future<SitterReservation> getReservationById(String id) => _api.getReservationById(id);

  Future<SitterReservation> updateReservation(String id, Map<String, dynamic> payload) =>
      _api.updateReservation(id, payload);

  Future<SitterReservation> acceptReservation(String id) => _api.acceptReservation(id);

  Future<SitterReservation> rejectReservation(String id, String reason) => _api.rejectReservation(id, reason);

  Future<SitterReservation> cancelReservation(String id) => _api.cancelReservation(id);

  Future<SitterReservation> completeReservation(String id) => _api.completeReservation(id);

  // Reviews
  Future<SitterReview> addReview(String sitterId, {String? reservationId, required int rating, required String comment}) =>
      _api.addReview(sitterId, reservationId: reservationId, rating: rating, comment: comment);

  Future<List<SitterReview>> getReviews(String sitterId) => _api.getReviews(sitterId);

  Future<void> deleteReview(String sitterId, String reviewId) => _api.deleteReview(sitterId, reviewId);

  // Admin
  Future<List<PetSitter>> getAdminSitters({String? search, String? governorate}) =>
      _api.getAdminSitters(search: search, governorate: governorate);

  Future<PetSitter> setSitterVerification(String id, bool verified) => _api.setSitterVerification(id, verified);

  Future<PetSitter> setSitterActive(String id, bool active) => _api.setSitterActive(id, active);

  Future<void> deleteSitterAdmin(String id) => _api.deleteSitterAdmin(id);

  Future<List<SitterReservation>> getAdminReservations() => _api.getAdminReservations();

  Future<void> deleteReservationAdmin(String id) => _api.deleteReservationAdmin(id);

  Future<Map<String, dynamic>> getAdminStats() => _api.getAdminStats();
}
