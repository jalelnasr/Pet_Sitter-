/// Accès au backend, réglé au lancement :
/// `flutter run --dart-define=USE_API=true [--dart-define=API_URL=http://192.168.1.10:8080/api]`.
library;

import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  /// Sans cette option, l'application reste sur ses données de démonstration.
  static const useApi = bool.fromEnvironment('USE_API');

  static const _customUrl = String.fromEnvironment('API_URL');

  /// Adresse complète d'une photo envoyée par le serveur (`/api/images/…`).
  static String imageUrl(String path) => Uri.parse(baseUrl).resolve(path).toString();

  static String get baseUrl {
    if (_customUrl.isNotEmpty) return _customUrl;
    // Sur l'émulateur Android, 10.0.2.2 désigne l'ordinateur qui l'héberge.
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8080/api' : 'http://localhost:8080/api';
  }
}
