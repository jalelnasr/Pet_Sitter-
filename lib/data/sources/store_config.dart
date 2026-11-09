/// Réglages de la boutique, passés au lancement.
library;

class StoreConfig {
  StoreConfig._();

  /// Clé de l'API Gemini : `--dart-define-from-file=gemini.local.json` (fichier ignoré par Git).
  /// Vide = l'onglet Ventes affiche le commentaire de secours du serveur.
  static const geminiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Modèle Gemini, modifiable avec `--dart-define=GEMINI_MODEL=...`.
  static const geminiModel = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash-lite');
}
