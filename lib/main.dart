import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_sitter/app/app.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/data/sources/api_config.dart';
import 'package:pet_sitter/data/sources/session.dart';

/// Point d'entrée : prépare la barre d'état puis lance l'application
/// avec ses dépendances (dépôts de données de démonstration).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  const app = PetSitterApp();
  if (ApiConfig.useApi) {
    final session = Session(persist: true);
    await session.restore();
    runApp(Deps.api(session: session, child: app));
  } else {
    runApp(Deps.mock(child: app));
  }
}
