/// AccÃ¨s HTTP centralisÃ© du module Adoption.
///
/// Toutes les requÃªtes passent par [ApiClient] : l'URL de base, les en-tÃªtes
/// JSON et l'identifiant de l'utilisateur de dÃ©monstration ne sont dÃ©finis
/// qu'ici, jamais dans les Ã©crans.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'demo_session.dart';

import 'package:pet_sitter/core/network/network_status.dart';
import 'package:pet_sitter/core/session/auth_session.dart';

import 'package:pet_sitter/core/config/api_constants.dart';

export 'package:pet_sitter/core/config/api_constants.dart';


/// Erreur renvoyÃ©e par le backend ou par le rÃ©seau.
class ApiException implements Exception {
  const ApiException(
    this.statusCode,
    this.code,
    this.message, {
    this.fieldErrors,
  });

  final int statusCode;
  final String code;
  final String message;
  final Map<String, String>? fieldErrors;

  bool get isNetwork => statusCode == 0;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode, $code) : $message';
}

class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = ApiConstants.baseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-User-Id': DemoSessionProvider.instance.currentUser.id,
    'X-Demo-User-Id': DemoSessionProvider.instance.currentUser.id,
    // Jeton de session : quand il est présent, le backend ignore les en-têtes de démonstration.
    ...AuthSession.instance.authHeaders,
  };

  Uri _uri(String path, [Map<String, String?>? query]) {
    final uri = Uri.parse('$baseUrl$path');
    if (query == null) return uri;
    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Object? body]) => _send(
    () => _client.post(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> put(String path, [Object? body]) => _send(
    () => _client.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> patch(String path, [Object? body]) => _send(
    () => _client.patch(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers()));

  /// Envoi d'un fichier en multipart (champ « file »), avec le jeton de session.
  Future<dynamic> upload(String path, Uint8List bytes, String filename) => _send(() async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({
        'Accept': 'application/json',
        'X-User-Id': DemoSessionProvider.instance.currentUser.id,
        'X-Demo-User-Id': DemoSessionProvider.instance.currentUser.id,
        ...AuthSession.instance.authHeaders,
      })
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    return http.Response.fromStream(await _client.send(request));
  });

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(ApiConstants.timeout);
      NetworkStatus.instance.reportReachable();
      return _decode(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      NetworkStatus.instance.reportUnreachable();
      throw const ApiException(
        0,
        'TIMEOUT',
        'Le serveur met trop de temps Ã  rÃ©pondre. RÃ©essayez.',
      );
    } on SocketException {
      NetworkStatus.instance.reportUnreachable();
      throw const ApiException(
        0,
        'NETWORK_ERROR',
        'Impossible de joindre le serveur. VÃ©rifiez que le backend est dÃ©marrÃ©.',
      );
    } on http.ClientException {
      NetworkStatus.instance.reportUnreachable();
      throw const ApiException(
        0,
        'NETWORK_ERROR',
        'Connexion au serveur impossible. VÃ©rifiez l\'adresse de l\'API.',
      );
    } on FormatException {
      throw const ApiException(
        0,
        'BAD_RESPONSE',
        'La rÃ©ponse du serveur est illisible.',
      );
    }
  }

  dynamic _decode(http.Response response) {
    final body = response.body.trim();
    dynamic json;
    if (body.isNotEmpty) {
      try {
        json = jsonDecode(body);
      } on FormatException {
        json = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json;
    }

    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    // Jeton refusé (expiré, mot de passe changé, compte suspendu) : la session est fermée.
    if (response.statusCode == 401 && map['code'] == 'SESSION_EXPIRED') {
      AuthSession.instance.expire();
    }
    throw ApiException(
      response.statusCode,
      (map['code'] as String?) ?? 'HTTP_${response.statusCode}',
      (map['message'] as String?) ?? 'Une erreur est survenue.',
      fieldErrors: _fieldErrors(map['fieldErrors']),
    );
  }

  Map<String, String>? _fieldErrors(dynamic value) {
    if (value is! Map) return null;
    final fields = <String, String>{};
    value.forEach((key, message) {
      fields['$key'] = '$message';
    });
    return fields.isEmpty ? null : fields;
  }
}
