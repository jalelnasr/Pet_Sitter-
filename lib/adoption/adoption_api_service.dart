/// Service REST du module Adoption.
///
/// Il traduit les réponses JSON du backend Spring Boot en modèles Flutter.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pet_sitter/models/species.dart';

import 'adoption_local_store.dart';
import 'adoption_models.dart';
import 'api/api_client.dart';
import 'api/demo_session.dart';

class AdoptionApiService {
  AdoptionApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Instance partagée par le module, sans modifier `Deps`.
  static final AdoptionApiService shared = AdoptionApiService();

  final ApiClient _client;

  // ————————————————————————————————————————————— ANNONCES

  Future<List<AdoptionPet>> fetchListings({
    Species? species,
    String? location,
  }) async {
    final dynamic json;
    try {
      json = await _client.get(
        '/adoption-listings',
        query: {
          'page': '0',
          'size': '50',
          'species': species == null ? null : _speciesApi(species),
          'location': location,
        },
      );
    } on ApiException catch (e) {
      // Pas de réseau : annonces enregistrées dans SQLite.
      if (e.statusCode != 0) rethrow;
      final saved = await _local.readAll(species: species == null ? null : _speciesApi(species));
      if (saved.isEmpty) rethrow;
      return _pets(saved);
    }
    if (species == null && (location == null || location.isEmpty)) {
      final items = json is Map<String, dynamic> ? json['content'] : json;
      if (items is List) await _local.saveAll(items.whereType<Map<String, dynamic>>().toList());
    }
    return _pets(json);
  }

  final _local = const AdoptionLocalStore();

  Future<AdoptionPet> fetchListing(String id) async {
    final json = await _client.get('/adoption-listings/$id');
    return AdoptionPet.fromJson(_map(json));
  }

  Future<List<AdoptionPet>> fetchMine() async {
    final json = await _client.get('/adoption-listings/mine');
    return _pets(json);
  }

  Future<AdoptionPet> createListing(
    AdoptionDraft draft, {
    bool asDraft = false,
  }) async {
    final json = await _client.post(
      '/adoption-listings',
      draft.toCreateJson(draft: asDraft),
    );
    return AdoptionPet.fromJson(_map(json));
  }

  Future<AdoptionPet> updateListing(String id, AdoptionDraft draft) async {
    final json = await _client.put(
      '/adoption-listings/$id',
      draft.toUpdateJson(),
    );
    return AdoptionPet.fromJson(_map(json));
  }

  Future<AdoptionPet> publishListing(String id) async {
    final json = await _client.patch('/adoption-listings/$id/publish');
    return AdoptionPet.fromJson(_map(json));
  }

  Future<AdoptionPet> pauseListing(String id) async {
    final json = await _client.patch('/adoption-listings/$id/pause');
    return AdoptionPet.fromJson(_map(json));
  }

  Future<AdoptionPet> archiveListing(String id) async {
    final json = await _client.patch('/adoption-listings/$id/archive');
    return AdoptionPet.fromJson(_map(json));
  }

  // ————————————————————————————————————————————— MODÉRATION

  Future<List<AdoptionPet>> fetchAllForAdmin() async {
    final json = await _client.get('/admin/adoption-listings');
    return _pets(json);
  }

  Future<AdoptionPet> adminHide(String id) async {
    final json = await _client.patch('/admin/adoption-listings/$id/hide');
    return AdoptionPet.fromJson(_map(json));
  }

  Future<AdoptionPet> adminArchive(String id) async {
    final json = await _client.patch('/admin/adoption-listings/$id/archive');
    return AdoptionPet.fromJson(_map(json));
  }

  // ————————————————————————————————————————————— DEMANDES

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
  }) async {
    final json = await _client.post('/adoption-requests', {
      'listingId': listingId,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'message': message,
      'housingType': housingType.apiValue,
      'hasGarden': hasGarden,
      'hasOtherPets': hasOtherPets,
      'otherPetsDetails': otherPetsDetails,
      'experience': experience,
      'aiScore': aiScore,
    });
    return AdoptionRequest.fromJson(_map(json));
  }

  Future<List<AdoptionRequest>> fetchSent() async {
    final json = await _client.get('/adoption-requests/sent');
    return _requests(json);
  }

  Future<List<AdoptionRequest>> fetchReceived() async {
    final json = await _client.get('/adoption-requests/received');
    return _requests(json);
  }

  Future<AdoptionRequest> fetchRequest(String id) async {
    final json = await _client.get('/adoption-requests/$id');
    return AdoptionRequest.fromJson(_map(json));
  }

  // �?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?"�?" CONSEIL IA

  Future<AdoptionAiAdvice> fetchMatchingAdvice({
    required String listingId,
    required HousingType housingType,
    required bool hasGarden,
    required bool hasOtherPets,
    String? otherPetsDetails,
    String? experience,
    String? motivation,
  }) async {
    final json = await _client.post('/adoption-matching/advice', {
      'listingId': listingId,
      'housingType': housingType.apiValue,
      'hasGarden': hasGarden,
      'hasOtherPets': hasOtherPets,
      'otherPetsDetails': otherPetsDetails,
      'experience': experience,
      'motivation': motivation,
    });
    return AdoptionAiAdvice.fromJson(_map(json));
  }

  Future<AdoptionRequest> acceptRequest(String id, {String? message}) =>
      _processRequest(id, 'accept', message);

  Future<AdoptionRequest> rejectRequest(String id, {String? message}) =>
      _processRequest(id, 'reject', message);

  Future<AdoptionRequest> cancelRequest(String id, {String? message}) =>
      _processRequest(id, 'cancel', message);

  Future<AdoptionRequest> _processRequest(
    String id,
    String action,
    String? message,
  ) async {
    final json = await _client.patch('/adoption-requests/$id/$action', {
      'responseMessage': message,
    });
    return AdoptionRequest.fromJson(_map(json));
  }

  // ---- IMAGES

  Future<String> uploadImage(File file, {String? contentType}) async {
    final uri = Uri.parse('${_client.baseUrl}/adoption-listings/images');
    final request = http.MultipartRequest('POST', uri);
    request.headers['X-Demo-User-Id'] =
        DemoSessionProvider.instance.currentUser.id;
    final lower = file.path.toLowerCase();
    final resolvedType = contentType ??
        (lower.endsWith('.jpg') || lower.endsWith('.jpeg')
            ? 'image/jpeg'
            : lower.endsWith('.png')
                ? 'image/png'
                : lower.endsWith('.webp')
                    ? 'image/webp'
                    : 'application/octet-stream');
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: http.MediaType.parse(resolvedType),
      ),
    );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String code = 'UPLOAD_FAILED';
      String message = body.isEmpty ? 'Echec de l envoi de l image.' : body;
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          code = (decoded['code'] as String?) ?? code;
          message = (decoded['message'] as String?) ?? message;
        }
      } catch (_) {}
      throw ApiException(response.statusCode, code, message);
    }
    final json = body.trim().isEmpty ? const {} : jsonDecode(body);
    if (json is Map<String, dynamic> && json['url'] is String) {
      return json['url'] as String;
    }
    throw const ApiException(500, 'BAD_RESPONSE', 'Reponse d envoi illisible.');
  }

  // ————————————————————————————————————————————— HELPERS

  List<AdoptionPet> _pets(dynamic json) {
    final items = json is Map<String, dynamic> ? json['content'] : json;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(AdoptionPet.fromJson)
        .toList();
  }

  List<AdoptionRequest> _requests(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(AdoptionRequest.fromJson)
        .toList();
  }

  Map<String, dynamic> _map(dynamic json) =>
      json is Map<String, dynamic> ? json : const {};

  String _speciesApi(Species species) => switch (species) {
    Species.chien => 'DOG',
    Species.chat => 'CAT',
    Species.oiseau => 'BIRD',
    Species.lapin => 'RABBIT',
    _ => 'OTHER',
  };
}
