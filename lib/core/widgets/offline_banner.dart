import 'package:flutter/material.dart';
import 'package:pet_sitter/core/network/network_status.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';

/// Bandeau en haut de l'application quand le serveur est injoignable :
/// les écrans affichent alors les données enregistrées sur le téléphone.
///
/// La structure ne change jamais (bandeau de hauteur nulle quand tout va bien) :
/// la navigation et l'état des écrans sont conservés quand le bandeau apparaît.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child, this.status});

  final Widget child;

  /// État du réseau ; par défaut celui de toute l'application.
  final NetworkStatus? status;

  @override
  Widget build(BuildContext context) {
    final network = status ?? NetworkStatus.instance;
    return ListenableBuilder(
      listenable: network,
      builder: (context, _) {
        final offline = network.offline;
        return Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: offline
                  ? Material(
                      color: LP.night,
                      child: SafeArea(
                        bottom: false,
                        child: Semantics(
                          liveRegion: true,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_off_rounded, size: 18, color: LP.white),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Hors ligne : données enregistrées sur le téléphone',
                                    style: LPText.body(size: 13, w: FontWeight.w700, color: LP.white),
                                  ),
                                ),
                                // Vérifie tout de suite si le serveur est revenu (sinon : toutes les 5 s).
                                network.checking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: LP.white),
                                      )
                                    : TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: LP.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          minimumSize: const Size(0, 32),
                                        ),
                                        onPressed: network.checkNow,
                                        child: const Text('Réessayer'),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            Expanded(
              // Le bandeau occupe déjà la zone de la barre d'état.
              child: MediaQuery.removePadding(context: context, removeTop: offline, child: child),
            ),
          ],
        );
      },
    );
  }
}
