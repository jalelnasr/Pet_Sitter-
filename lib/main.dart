import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_sitter/app/app.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/app/session_bridge.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
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
    session.useStore(LocalSessionStore());
    await session.restore();
  }
  // Adoption, Événements et Garde suivent le compte connecté.
  bindModuleSessions(session);

  const app = PetSitterApp();
  runApp(_demoData ? Deps.mock(child: app) : Deps.live(child: app));
}
