import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pet_sitter/app/app.dart';
import 'package:pet_sitter/app/dependencies.dart';

/// Point d'entrée : prépare la barre d'état puis lance l'application
/// avec ses dépendances (dépôts de données de démonstration).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(Deps.mock(child: const PetSitterApp()));
}
