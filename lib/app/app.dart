/// L'application : thème, langue, navigation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/views/catalog/catalog_screen.dart';

class PetSitterApp extends StatefulWidget {
  const PetSitterApp({super.key, this.session});

  /// Session suivie pour renvoyer vers la connexion quand le serveur refuse le jeton.
  final AuthSession? session;

  @override
  State<PetSitterApp> createState() => _PetSitterAppState();
}

class _PetSitterAppState extends State<PetSitterApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final AuthSession _session = widget.session ?? AuthSession.instance;
  late bool _wasSignedIn = _session.isAuthenticated;

  @override
  void initState() {
    super.initState();
    _session.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Session expirée (jeton refusé, mot de passe changé ailleurs, compte suspendu) :
  /// retour à l'écran de connexion, qui affiche la raison.
  void _onSessionChanged() {
    final signedIn = _session.isAuthenticated;
    if (_wasSignedIn && !signedIn && _session.wasExpired) {
      _navigator.currentState?.pushNamedAndRemoveUntil(R.login, (r) => r.settings.name == R.catalog);
    }
    _wasSignedIn = signedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigator,
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
      // Démarrage : splash puis guide (ou accueil si une session est enregistrée).
      // Le sommaire des maquettes reste dessous (retour arrière).
      home: const CatalogScreen(),
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
