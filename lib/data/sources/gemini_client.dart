/// Appel direct à l'API Gemini de Google depuis l'application.
///
/// La clé est passée au lancement (`--dart-define=GEMINI_API_KEY=...`) et n'est jamais écrite dans le code.
/// Elle reste lisible dans l'application compilée : clé de test avec limite de dépense uniquement.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Erreur lisible, affichée telle quelle à l'utilisateur.
class GeminiException implements Exception {
  const GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GeminiClient {
  GeminiClient({required this.apiKey, required this.model, http.Client? client}) : _client = client ?? http.Client();

  static const _timeout = Duration(seconds: 30);

  final String apiKey;
  final String model;
  final http.Client _client;

  bool get enabled => apiKey.isNotEmpty;

  /// Envoie [prompt] et renvoie la réponse de Gemini, contrainte par [schema] (format JSON imposé).
  Future<Map<String, dynamic>> generateJson({
    required String instructions,
    required String prompt,
    required Map<String, dynamic> schema,
  }) async {
    final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent');
    final http.Response response;
    try {
      response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': instructions},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {'responseMimeType': 'application/json', 'responseSchema': schema},
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const GeminiException('Gemini met trop de temps à répondre. Réessayez.');
    } on http.ClientException {
      throw const GeminiException('Impossible de joindre Gemini. Vérifiez votre connexion.');
    }

    final body = _decode(response);
    if (response.statusCode != 200) throw _errorFrom(response.statusCode, body);
    try {
      final candidates = body['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw const GeminiException('Gemini a refusé de répondre à cette demande.');
      }
      final candidate = candidates.first as Map<String, dynamic>;
      if (candidate['finishReason'] == 'SAFETY') {
        throw const GeminiException('Gemini a refusé de répondre à cette demande.');
      }
      final text = (candidate['content']['parts'] as List).first['text'] as String;
      return jsonDecode(text) as Map<String, dynamic>;
    } on GeminiException {
      rethrow;
    } catch (_) {
      throw const GeminiException('Gemini a envoyé une réponse illisible. Réessayez.');
    }
  }

  Map<String, dynamic> _decode(http.Response r) {
    try {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  GeminiException _errorFrom(int status, Map<String, dynamic> body) {
    final error = body['error'];
    final reason = error is Map ? '${error['status']} ${error['message']}' : '';
    if (status == 429) return const GeminiException('Quota Gemini atteint. Réessayez plus tard.');
    if (reason.contains('API_KEY') || reason.contains('API key') || status == 401 || status == 403) {
      return const GeminiException('Clé Gemini refusée. Vérifiez GEMINI_API_KEY.');
    }
    if (status == 404) return GeminiException('Modèle Gemini introuvable : $model.');
    return const GeminiException('Gemini est indisponible pour le moment.');
  }
}
