import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:pet_sitter/core/config/api_constants.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/petsitter/petsitter_local_store.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';
import 'package:pet_sitter/petsitter/petsitter_session.dart';

class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  ApiException(this.statusCode, this.code, this.message);

  @override
  String toString() => message;
}

class PetSitterApiService {
  PetSitterApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl => ApiConstants.baseUrl;

  Map<String, String> _headers({bool json = true}) {
    final userId = PetSitterSession.instance.currentUserId;
    final map = <String, String>{
      'X-User-Id': userId,
      'X-Demo-User-Id': userId,
      ...AuthSession.instance.authHeaders,
    };
    if (json) {
      map['Content-Type'] = 'application/json';
      map['Accept'] = 'application/json';
    }
    return map;
  }

  dynamic _handleResponse(http.Response response) {
    final body = response.body.trim();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    }

    String code = 'ERROR';
    String message = 'Une erreur est survenue (${response.statusCode})';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        code = decoded['code'] as String? ?? code;
        message = decoded['message'] as String? ?? message;
      }
    } catch (_) {
      if (body.isNotEmpty) message = body;
    }

    throw ApiException(response.statusCode, code, message);
  }

  // ==========================================
  // SITTERS
  // ==========================================

  Future<List<PetSitter>> getSitters({
    String? search,
    String? governorate,
    SitterServiceType? service,
    PetSpeciesType? petType,
    Double? minPrice,
    Double? maxPrice,
    Double? minRating,
    bool? verifiedOnly,
    String? sortBy,
    int page = 0,
    int size = 30,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (governorate != null && governorate.trim().isNotEmpty)
        'governorate': governorate.trim(),
      if (service != null) 'service': service.apiValue,
      if (petType != null) 'petType': petType.apiValue,
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (minRating != null) 'minRating': minRating.toString(),
      if (verifiedOnly == true) 'verifiedOnly': 'true',
    };

    final uri = Uri.parse('$_baseUrl/sitters').replace(queryParameters: query);
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: _headers())
          .timeout(ApiConstants.timeout);
    } on Exception catch (e) {
      // Pas de réseau (délai dépassé, serveur injoignable) : sitters enregistrés dans SQLite.
      if (e is! TimeoutException && e is! SocketException && e is! http.ClientException) rethrow;
      final saved = await _local.readAll(search: search, governorate: governorate);
      if (saved.isEmpty) rethrow;
      return saved.map(PetSitter.fromJson).toList();
    }
    final data = _handleResponse(response);

    if (data is Map<String, dynamic> && data['content'] is List) {
      final items = (data['content'] as List).whereType<Map<String, dynamic>>().toList();
      await _local.saveAll(items);
      return items.map(PetSitter.fromJson).toList();
    }
    return [];
  }

  final _local = const SitterLocalStore();

  Future<PetSitter> getSitterById(String id) async {
    final uri = Uri.parse('$_baseUrl/sitters/$id');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<PetSitter?> getMyProfile() async {
    try {
      final uri = Uri.parse('$_baseUrl/sitters/me');
      final response = await _client
          .get(uri, headers: _headers())
          .timeout(ApiConstants.timeout);
      final data = _handleResponse(response);
      return PetSitter.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PetSitter> createSitterProfile(Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/sitters');
    final response = await _client
        .post(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<PetSitter> updateSitterProfile(
      String id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/sitters/$id');
    final response = await _client
        .put(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<PetSitter> toggleVisibility(String id) async {
    final uri = Uri.parse('$_baseUrl/sitters/$id/visibility');
    final response = await _client
        .patch(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSitterProfile(String id) async {
    final uri = Uri.parse('$_baseUrl/sitters/$id');
    final response = await _client
        .delete(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    _handleResponse(response);
  }

  Future<String> uploadImage(File file) async {
    final uri = Uri.parse('$_baseUrl/sitters/images');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers(json: false));

    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(
      'file',
      stream,
      length,
      filename: file.path.split(Platform.pathSeparator).last,
    );
    request.files.add(multipartFile);

    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final data = _handleResponse(response);
    if (data is Map<String, dynamic> && data['url'] is String) {
      return data['url'] as String;
    }
    throw ApiException(500, 'UPLOAD_ERROR', 'URL non reçue');
  }

  // ==========================================
  // RESERVATIONS
  // ==========================================

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
  }) async {
    final uri = Uri.parse('$_baseUrl/reservations');
    final payload = {
      'sitterId': sitterId,
      'petName': petName,
      'petType': petType.apiValue,
      'petSize': petSize.apiValue,
      'service': service.apiValue,
      'startDate': startDate.toIso8601String().split('T').first,
      'endDate': endDate.toIso8601String().split('T').first,
      if (startTime != null && startTime.isNotEmpty) 'startTime': startTime,
      if (endTime != null && endTime.isNotEmpty) 'endTime': endTime,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await _client
        .post(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SitterReservation>> getMyReservations() async {
    final uri = Uri.parse('$_baseUrl/reservations/my');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    if (data is List) {
      return data
          .map((e) => SitterReservation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<SitterReservation>> getIncomingReservations() async {
    final uri = Uri.parse('$_baseUrl/reservations/incoming');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    if (data is List) {
      return data
          .map((e) => SitterReservation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<SitterReservation> getReservationById(String id) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<SitterReservation> updateReservation(
      String id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id');
    final response = await _client
        .put(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<SitterReservation> acceptReservation(String id) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id/accept');
    final response = await _client
        .patch(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<SitterReservation> rejectReservation(String id, String reason) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id/reject');
    final response = await _client
        .patch(uri, headers: _headers(), body: jsonEncode({'reason': reason}))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<SitterReservation> cancelReservation(String id) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id/cancel');
    final response = await _client
        .patch(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  Future<SitterReservation> completeReservation(String id) async {
    final uri = Uri.parse('$_baseUrl/reservations/$id/complete');
    final response = await _client
        .patch(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReservation.fromJson(data as Map<String, dynamic>);
  }

  // ==========================================
  // REVIEWS
  // ==========================================

  Future<SitterReview> addReview(
    String sitterId, {
    String? reservationId,
    required int rating,
    required String comment,
  }) async {
    final uri = Uri.parse('$_baseUrl/sitters/$sitterId/reviews');
    final payload = <String, dynamic>{
      'rating': rating,
      'comment': comment,
    };
    if (reservationId != null) {
      payload['reservationId'] = reservationId;
    }
    final response = await _client
        .post(uri, headers: _headers(), body: jsonEncode(payload))
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return SitterReview.fromJson(data as Map<String, dynamic>);
  }

  Future<List<SitterReview>> getReviews(String sitterId) async {
    final uri = Uri.parse('$_baseUrl/sitters/$sitterId/reviews');
    final response = await _client
        .get(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    if (data is List) {
      return data
          .map((e) => SitterReview.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> deleteReview(String sitterId, String reviewId) async {
    final uri = Uri.parse('$_baseUrl/sitters/$sitterId/reviews/$reviewId');
    final response = await _client
        .delete(uri, headers: _headers())
        .timeout(ApiConstants.timeout);
    _handleResponse(response);
  }

  // ==========================================
  // ADMIN
  // ==========================================

  Future<List<PetSitter>> getAdminSitters({String? search, String? governorate}) async {
    final query = <String, String>{
      'size': '100',
      if (search != null && search.isNotEmpty) 'search': search,
      if (governorate != null && governorate.isNotEmpty) 'governorate': governorate,
    };
    final uri = Uri.parse('$_baseUrl/admin/sitters').replace(queryParameters: query);
    final response = await _client.get(uri, headers: _headers()).timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List)
          .map((item) => PetSitter.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<PetSitter> setSitterVerification(String id, bool verified) async {
    final uri = Uri.parse('$_baseUrl/admin/sitters/$id/verify?verified=$verified');
    final response = await _client.patch(uri, headers: _headers()).timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<PetSitter> setSitterActive(String id, bool active) async {
    final uri = Uri.parse('$_baseUrl/admin/sitters/$id/activate?active=$active');
    final response = await _client.patch(uri, headers: _headers()).timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return PetSitter.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSitterAdmin(String id) async {
    final uri = Uri.parse('$_baseUrl/admin/sitters/$id');
    final response = await _client.delete(uri, headers: _headers()).timeout(ApiConstants.timeout);
    _handleResponse(response);
  }

  Future<List<SitterReservation>> getAdminReservations() async {
    final uri = Uri.parse('$_baseUrl/admin/reservations');
    final response = await _client.get(uri, headers: _headers()).timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    if (data is List) {
      return data.map((e) => SitterReservation.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<void> deleteReservationAdmin(String id) async {
    final uri = Uri.parse('$_baseUrl/admin/reservations/$id');
    final response = await _client.delete(uri, headers: _headers()).timeout(ApiConstants.timeout);
    _handleResponse(response);
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final uri = Uri.parse('$_baseUrl/admin/sitters/stats');
    final response = await _client.get(uri, headers: _headers()).timeout(ApiConstants.timeout);
    final data = _handleResponse(response);
    return data as Map<String, dynamic>;
  }
}

typedef Double = double;
