import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pet_sitter/app/app.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/app/session_bridge.dart';
import 'package:pet_sitter/core/config/api_constants.dart';
import 'package:pet_sitter/core/network/network_status.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/data/local/session_sqlite_store.dart';
import 'package:pet_sitter/data/sources/local_session_store.dart';

/// Données de démonstration seulement (sans backend) :
/// `flutter run --dart-define=DEMO_DATA=true`.
const _demoData = bool.fromEnvironment('DEMO_DATA');

/// Point d'entrée : prépare la barre d'état, recharge la session enregistrée,
/// puis lance l'application avec ses dépendances.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  final session = AuthSession.instance;
  if (!_demoData) {
    // Téléphone : session dans SQLite. Navigateur (pas de SQLite) : stockage du navigateur.
    session.useStore(kIsWeb ? LocalSessionStore() : SessionSqliteStore());
    await session.restore();
  }
  // Adoption, Événements et Garde suivent le compte connecté.
  bindModuleSessions(session);

  // Hors ligne : le serveur est revérifié toutes les 5 secondes (câble rebranché, Wi-Fi revenu).
  if (!_demoData) {
    NetworkStatus.instance.useProbe(() async {
      await http.get(Uri.parse('${ApiConstants.baseUrl}/products?size=1')).timeout(const Duration(seconds: 3));
      return true; // toute réponse, même une erreur, prouve que le serveur est joignable
    });
  }

  const app = PetSitterApp();
  runApp(_demoData ? Deps.mock(child: app) : Deps.live(child: app));
}
