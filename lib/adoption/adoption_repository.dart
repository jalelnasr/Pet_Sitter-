
/// DÃ©pÃ´t du module Adoption : l'interface utilisÃ©e par les ViewModels.
///
/// L'implÃ©mentation rÃ©elle appelle le backend Spring Boot via
/// [AdoptionApiService]. Aucun Ã©cran ne fait d'appel HTTP directement.
library;
import 'dart:io';

import 'package:pet_sitter/models/species.dart';

import 'adoption_api_service.dart';
import 'adoption_models.dart';

abstract class AdoptionRepository {
  Future<List<AdoptionPet>> listings({Species? species, String? location});

  Future<AdoptionPet> listing(String id);

  Future<List<AdoptionPet>> mine();

  Future<AdoptionPet> create(AdoptionDraft draft, {bool asDraft = false});

  Future<AdoptionPet> update(String id, AdoptionDraft draft);

  Future<AdoptionPet> publish(String id);

  Future<AdoptionPet> pause(String id);

  Future<AdoptionPet> archive(String id);

  Future<List<AdoptionPet>> adminListings();

  Future<AdoptionPet> adminHide(String id);

  Future<AdoptionPet> adminArchive(String id);

  Future<String> uploadImage(File file, {String? contentType});

  Future<AdoptionRequest> sendRequest({
    required String listingId,
    required String fullName,
    required String phone,
    required String address,
    required String message,
    required String experience,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    int? aiScore,
  });

  Future<AdoptionAiAdvice> matchingAdvice({
    required String listingId,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    String? experience,
    String? motivation,
  });

  Future<List<AdoptionRequest>> sentRequests();

  Future<List<AdoptionRequest>> receivedRequests();

  Future<AdoptionRequest> request(String id);

  Future<AdoptionRequest> acceptRequest(String id, {String? message});

  Future<AdoptionRequest> rejectRequest(String id, {String? message});

  Future<AdoptionRequest> cancelRequest(String id, {String? message});
}

class ApiAdoptionRepository implements AdoptionRepository {
  ApiAdoptionRepository({AdoptionApiService? api})
    : _api = api ?? AdoptionApiService.shared;

  /// Instance partagÃ©e par les Ã©crans du module, sans toucher Ã  `Deps`.
  static final ApiAdoptionRepository shared = ApiAdoptionRepository();

  final AdoptionApiService _api;

  @override
  Future<List<AdoptionPet>> listings({Species? species, String? location}) =>
      _api.fetchListings(species: species, location: location);

  @override
  Future<AdoptionPet> listing(String id) => _api.fetchListing(id);

  @override
  Future<List<AdoptionPet>> mine() => _api.fetchMine();

  @override
  Future<AdoptionPet> create(AdoptionDraft draft, {bool asDraft = false}) =>
      _api.createListing(draft, asDraft: asDraft);

  @override
  Future<AdoptionPet> update(String id, AdoptionDraft draft) =>
      _api.updateListing(id, draft);

  @override
  Future<AdoptionPet> publish(String id) => _api.publishListing(id);

  @override
  Future<AdoptionPet> pause(String id) => _api.pauseListing(id);

  @override
  Future<AdoptionPet> archive(String id) => _api.archiveListing(id);

  @override
  Future<List<AdoptionPet>> adminListings() => _api.fetchAllForAdmin();

  @override
  Future<AdoptionPet> adminHide(String id) => _api.adminHide(id);

  @override
  Future<AdoptionPet> adminArchive(String id) => _api.adminArchive(id);

  @override
  Future<String> uploadImage(File file, {String? contentType}) =>
      _api.uploadImage(file, contentType: contentType);

  @override
  Future<AdoptionRequest> sendRequest({
    required String listingId,
    required String fullName,
    required String phone,
    required String address,
    required String message,
    required String experience,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    int? aiScore,
  }) => _api.sendRequest(
    listingId: listingId,
    fullName: fullName,
    phone: phone,
    address: address,
    message: message,
    experience: experience,
    housingType: housingType,
    hasGarden: hasGarden,
    hasOtherPets: hasOtherPets,
    otherPetsDetails: otherPetsDetails,
    aiScore: aiScore,
  );

  @override
  Future<AdoptionAiAdvice> matchingAdvice({
    required String listingId,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    String? experience,
    String? motivation,
  }) =>
      _api.fetchMatchingAdvice(
        listingId: listingId,
        housingType: housingType,
        hasGarden: hasGarden,
        hasOtherPets: hasOtherPets,
        otherPetsDetails: otherPetsDetails,
        experience: experience,
        motivation: motivation,
      );

  @override
  Future<List<AdoptionRequest>> sentRequests() => _api.fetchSent();

  @override
  Future<List<AdoptionRequest>> receivedRequests() => _api.fetchReceived();

  @override
  Future<AdoptionRequest> request(String id) => _api.fetchRequest(id);

  @override
  Future<AdoptionRequest> acceptRequest(String id, {String? message}) =>
      _api.acceptRequest(id, message: message);

  @override
  Future<AdoptionRequest> rejectRequest(String id, {String? message}) =>
      _api.rejectRequest(id, message: message);

  @override
  Future<AdoptionRequest> cancelRequest(String id, {String? message}) =>
      _api.cancelRequest(id, message: message);
}
