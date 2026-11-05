/// Configuration partagée de l'API Adoption.
library;

class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8081/api',
  );

  static const Duration timeout = Duration(seconds: 20);

  /// Résout un chemin média relatif par rapport à l'origine du backend.
  static String resolveMediaUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (trimmed.startsWith('/')) {
      return '$origin$trimmed';
    }
    return '$origin/$trimmed';
  }
}