/// Service REST du module Événements.
///
/// Il communique avec le backend Spring Boot via [ApiClient] et convertit
/// les réponses JSON en modèles [PetEvent] et [EventReservation].
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:pet_sitter/adoption/api/api_client.dart';
import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/session/auth_session.dart';

import 'event_local_store.dart';
import 'event_models.dart';

class EventApiService {
  EventApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Instance partagée par le module.
  static final EventApiService shared = EventApiService();

  final ApiClient _client;

  Map<String, String> _customHeaders() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-User-Id': DemoSessionProvider.instance.currentUser.id,
    'X-Demo-User-Id': DemoSessionProvider.instance.currentUser.id,
    ...AuthSession.instance.authHeaders,
  };

  // ————————————————————————————————————————————— ÉVÉNEMENTS

  Future<List<PetEvent>> fetchEvents({
    EventCategory? category,
    String? search,
    bool? upcomingOnly,
    EventStatus? status,
  }) async {
    final dynamic json;
    try {
      json = await _client.get(
        '/events',
        query: {
          'category': category == null ? null : category.apiValue,
          'search': (search != null && search.trim().isNotEmpty) ? search.trim() : null,
          'upcomingOnly': upcomingOnly == true ? 'true' : null,
          'status': status == null ? null : status.apiValue,
        },
      );
    } on ApiException catch (e) {
      // Pas de réseau : événements enregistrés dans SQLite.
      if (e.statusCode != 0) rethrow;
      final saved = await _local.readAll(category: category?.apiValue, search: search);
      if (saved.isEmpty) rethrow;
      return _parseEvents(saved);
    }
    if (category == null && (search == null || search.trim().isEmpty) && status == null) {
      final items = json is Map<String, dynamic> ? json['content'] : json;
      if (items is List) await _local.saveAll(items.whereType<Map<String, dynamic>>().toList());
    }
    return _parseEvents(json);
  }

  final _local = const EventLocalStore();

  Future<PetEvent> fetchEvent(String id) async {
    final json = await _client.get('/events/$id');
    return PetEvent.fromJson(_map(json));
  }

  Future<List<PetEvent>> fetchMine() async {
    final json = await _client.get('/events/mine');
    return _parseEvents(json);
  }

  Future<PetEvent> createEvent(PetEvent event) async {
    final json = await _client.post('/events', event.toJson());
    return PetEvent.fromJson(_map(json));
  }

  Future<PetEvent> updateEvent(String id, PetEvent event) async {
    final json = await _client.put('/events/$id', event.toJson());
    return PetEvent.fromJson(_map(json));
  }

  Future<PetEvent> cancelEvent(String id) async {
    final json = await _client.post('/events/$id/cancel', {});
    return PetEvent.fromJson(_map(json));
  }

  Future<void> deleteEvent(String id) async {
    final uri = Uri.parse('${_client.baseUrl}/events/$id');
    final response = await http.delete(uri, headers: _customHeaders());
    if (response.statusCode >= 400) {
      String message = "Échec de la suppression de l'événement.";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw ApiException(
        response.statusCode,
        'DELETE_FAILED',
        message,
      );
    }
  }

  // ————————————————————————————————————————————— PROPOSITIONS

  Future<PetEvent> submitProposal(PetEvent event) async {
    final json = await _client.post('/events/proposals', event.toJson());
    return PetEvent.fromJson(_map(json));
  }

  Future<PetEvent> updateProposal(String id, PetEvent event) async {
    final json = await _client.put('/events/proposals/$id', event.toJson());
    return PetEvent.fromJson(_map(json));
  }

  Future<void> withdrawProposal(String id) async {
    final uri = Uri.parse('${_client.baseUrl}/events/proposals/$id');
    final response = await http.delete(uri, headers: _customHeaders());
    if (response.statusCode >= 400) {
      String message = "Échec du retrait de la proposition.";
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}
      throw ApiException(
        response.statusCode,
        'WITHDRAW_FAILED',
        message,
      );
    }
  }

  Future<List<PetEvent>> fetchMyProposals() async {
    final json = await _client.get('/events/proposals/mine');
    return _parseEvents(json);
  }

  Future<List<PetEvent>> fetchAllProposals({EventStatus? status}) async {
    final json = await _client.get(
      '/events/proposals',
      query: {
        'status': status == null ? null : status.apiValue,
      },
    );
    return _parseEvents(json);
  }

  Future<PetEvent> approveProposal(String id) async {
    final json = await _client.post('/events/proposals/$id/approve', {});
    return PetEvent.fromJson(_map(json));
  }

  Future<PetEvent> rejectProposal(String id, String reason) async {
    final json = await _client.post('/events/proposals/$id/reject', {
      'reason': reason,
    });
    return PetEvent.fromJson(_map(json));
  }

  // ————————————————————————————————————————————— RÉSERVATIONS

  Future<EventReservation> reserve({
    required String eventId,
    required String participantName,
    required String phone,
    required int numberOfPlaces,
    String? comment,
  }) async {
    final json = await _client.post('/events/$eventId/reservations', {
      'participantName': participantName,
      'phone': phone,
      'numberOfPlaces': numberOfPlaces,
      'comment': comment ?? '',
    });
    return EventReservation.fromJson(_map(json));
  }

  Future<List<EventReservation>> fetchMyReservations() async {
    final json = await _client.get('/event-reservations/mine');
    return _parseReservations(json);
  }

  Future<EventReservation> cancelReservation(String reservationId) async {
    final json = await _client.post('/event-reservations/$reservationId/cancel', {});
    return EventReservation.fromJson(_map(json));
  }

  Future<List<EventReservation>> fetchEventReservations(String eventId) async {
    final json = await _client.get('/events/$eventId/reservations');
    return _parseReservations(json);
  }

  // ————————————————————————————————————————————— IMAGE UPLOAD

  Future<String> uploadImage(File file, {String? contentType}) async {
    final uri = Uri.parse('${_client.baseUrl}/events/images');
    final request = http.MultipartRequest('POST', uri);
    request.headers['X-User-Id'] = DemoSessionProvider.instance.currentUser.id;
    request.headers['X-Demo-User-Id'] = DemoSessionProvider.instance.currentUser.id;
    request.headers.addAll(AuthSession.instance.authHeaders);

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
        contentType: MediaType.parse(resolvedType),
      ),
    );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String code = 'UPLOAD_FAILED';
      String message = body.isEmpty ? "Échec de l'envoi de l'image." : body;
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
    throw const ApiException(500, 'BAD_RESPONSE', "Réponse d'envoi d'image invalide.");
  }

  // ————————————————————————————————————————————— ASSISTANT IA

  Future<EventAiSuggestion> getAiSuggestion({
    required String title,
    List<String>? keywords,
    String? category,
    String? location,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      if (keywords != null && keywords.isNotEmpty) 'keywords': keywords,
      if (category != null && category.isNotEmpty) 'category': category,
      if (location != null && location.isNotEmpty) 'location': location,
      if (description != null && description.isNotEmpty) 'description': description,
    };
    final json = await _client.post('/events/ai/suggest', payload);
    return EventAiSuggestion.fromJson(_map(json));
  }

  // ————————————————————————————————————————————— HELPERS

  List<PetEvent> _parseEvents(dynamic json) {
    final items = json is Map<String, dynamic> ? json['content'] : json;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PetEvent.fromJson)
        .toList();
  }

  List<EventReservation> _parseReservations(dynamic json) {
    if (json is! List) return const [];
    return json
        .whereType<Map<String, dynamic>>()
        .map(EventReservation.fromJson)
        .toList();
  }

  Map<String, dynamic> _map(dynamic json) =>
      json is Map<String, dynamic> ? json : const {};
}
