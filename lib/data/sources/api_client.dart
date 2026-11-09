/// Appels au backend : jeton, décodage JSON et messages d'erreur lisibles.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pet_sitter/core/session/auth_session.dart';

/// Erreur lisible, affichée telle quelle à l'utilisateur.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, required this.session, http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final AuthSession session;
  final http.Client _client;

  Future<dynamic> get(String path, [Duration? timeout]) => _send('GET', path, null, timeout);
  Future<dynamic> post(String path, [Object? body, Duration? timeout]) => _send('POST', path, body, timeout);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<dynamic> patch(String path, Object body) => _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Récupère tous les éléments d'une liste paginée.
  Future<List<Map<String, dynamic>>> getAllPages(String path) async {
    final items = <Map<String, dynamic>>[];
    final separator = path.contains('?') ? '&' : '?';
    var page = 0;
    var totalPages = 1;
    while (page < totalPages) {
      final body = await get('$path${separator}page=$page&size=100') as Map<String, dynamic>;
      items.addAll((body['items'] as List).cast<Map<String, dynamic>>());
      totalPages = body['totalPages'] as int;
      page++;
    }
    return items;
  }

  Future<dynamic> _send(String method, String path, [Object? body, Duration? timeout]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _dispatch(request, timeout);
  }

  /// Envoie un fichier dans le champ `file` d'un formulaire multipart.
  Future<dynamic> upload(String path, Uint8List bytes, String filename) {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    return _dispatch(request);
  }

  Future<dynamic> _dispatch(http.BaseRequest request, [Duration? timeout]) async {
    final token = session.token;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final http.Response response;
    try {
      response = await _client.send(request).then(http.Response.fromStream).timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw const ApiException('Le serveur met trop de temps à répondre. Réessayez.');
    } on http.ClientException {
      throw const ApiException('Impossible de joindre le serveur. Vérifiez votre connexion.');
    }
    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;
    throw await _errorFrom(response.statusCode, decoded, hadToken: token != null);
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      if (response.statusCode < 300) {
        throw const ApiException('Le serveur a envoyé une réponse illisible.');
      }
      return null;
    }
  }

  Future<ApiException> _errorFrom(int status, dynamic body, {required bool hadToken}) async {
    if (status == 401 && hadToken) {
      await session.expire();
      return const ApiException('Votre session a expiré. Reconnectez-vous.', statusCode: 401);
    }
    if (status == 403) {
      return const ApiException('Vous n\'avez pas accès à cette action.', statusCode: 403);
    }
    if (body is Map<String, dynamic>) {
      final fields = body['fieldErrors'] ?? body['fields'];
      if (fields is Map && fields.isNotEmpty) return ApiException('${fields.values.first}', statusCode: status);
      final detail = body['message'] ?? body['detail'];
      if (detail is String && detail.isNotEmpty) return ApiException(detail, statusCode: status);
    }
    return ApiException('Une erreur est survenue. Réessayez.', statusCode: status);
  }
}
