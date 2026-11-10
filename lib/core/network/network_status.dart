/// État du réseau vu par l'application : le serveur répond-il ?
///
/// Les clients HTTP le mettent à jour à chaque requête : une réponse du serveur
/// (même une erreur 4xx) signale qu'il est joignable ; un délai dépassé ou une
/// connexion impossible signale qu'il ne l'est pas. Le bandeau « Hors ligne »
/// l'écoute pour prévenir que les données affichées viennent du téléphone.
///
/// Une fois hors ligne, une petite vérification ([useProbe]) est relancée à intervalle
/// régulier : dès que le serveur répond de nouveau (câble rebranché, Wi-Fi revenu),
/// l'application repasse en ligne toute seule.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

class NetworkStatus extends ChangeNotifier {
  NetworkStatus._();

  static final NetworkStatus instance = NetworkStatus._();

  bool _offline = false;
  Future<bool> Function()? _probe;
  Duration _probeEvery = const Duration(seconds: 5);
  Timer? _timer;
  bool _checking = false;

  /// Vrai depuis la dernière requête qui n'a pas pu joindre le serveur.
  bool get offline => _offline;

  /// Vérification en cours (bouton « Réessayer »).
  bool get checking => _checking;

  /// Vérification légère du serveur : renvoie vrai s'il répond.
  void useProbe(Future<bool> Function() probe, {Duration every = const Duration(seconds: 5)}) {
    _probe = probe;
    _probeEvery = every;
    if (_offline) _startProbing();
  }

  /// Le serveur a répondu.
  void reportReachable() {
    _timer?.cancel();
    _timer = null;
    if (!_offline) return;
    _offline = false;
    notifyListeners();
  }

  /// Le serveur n'a pas pu être joint (délai dépassé, pas de connexion).
  void reportUnreachable() {
    if (_offline) return;
    _offline = true;
    notifyListeners();
    _startProbing();
  }

  /// Vérifie tout de suite si le serveur est revenu.
  Future<bool> checkNow() async {
    final probe = _probe;
    if (probe == null || _checking) return !_offline;
    _checking = true;
    notifyListeners();
    var reachable = false;
    try {
      reachable = await probe();
    } catch (_) {
      reachable = false;
    }
    _checking = false;
    if (reachable) {
      reportReachable();
    } else {
      notifyListeners();
    }
    return reachable;
  }

  void _startProbing() {
    if (_probe == null) return;
    _timer?.cancel();
    _timer = Timer.periodic(_probeEvery, (_) => checkNow());
  }

  /// Tests : revenir à l'état initial.
  @visibleForTesting
  void reset() {
    _timer?.cancel();
    _timer = null;
    _probe = null;
    _checking = false;
    _offline = false;
    notifyListeners();
  }
}
