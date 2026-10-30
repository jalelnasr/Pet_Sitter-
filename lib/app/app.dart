/// L'application : thème, langue, navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';

class PetSitterApp extends StatelessWidget {
  const PetSitterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Sitter',
      debugShowCheckedModeBanner: false,
      theme: buildPetSitterTheme(),
      locale: const Locale('fr', 'TN'),
      supportedLocales: const [Locale('fr', 'TN'), Locale('fr'), Locale('ar', 'TN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Démarrage : splash puis guide. Le sommaire des maquettes reste dessous (retour arrière).
      initialRoute: R.splash,
      onGenerateRoute: onGenerateRoute,
      // Sur grand écran (web), l'app est présentée dans un cadre de téléphone.
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        if (size.width <= 520) return child!;
        return ColoredBox(
          color: LP.softDeep,
          child: Center(
            child: Container(
              width: 410,
              height: 864,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: LP.bg,
                borderRadius: BorderRadius.circular(46),
                border: Border.all(color: LP.primaryDark, width: 10),
              ),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(size: const Size(390, 844), padding: const EdgeInsets.only(top: 28, bottom: 12)),
                child: child!,
              ),
            ),
          ),
        );
      },
    );
  }
}
