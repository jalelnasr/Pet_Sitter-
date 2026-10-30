import 'dart:async';

import 'package:flutter/material.dart';

import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';

/// Écran de démarrage animé. Il prend le relais de l'écran de lancement natif
/// (même fond crème, même logo) puis enchaîne sur le guide de bienvenue.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.autoNext = true});

  /// Faux pour l'aperçu depuis le sommaire : l'écran reste affiché.
  final bool autoNext;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _next;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.autoNext || _next != null) return;
    final wait = reducedMotion(context) ? 1200 : 3000;
    _next = Timer(Duration(milliseconds: wait), () {
      if (mounted) Navigator.pushReplacementNamed(context, R.onboarding);
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LP.cream,
      body: GsapTimeline(
        duration: 2.2,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const Spacer(flex: 3),
                SizedBox(
                  width: 300,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // halo qui respire derrière le logo
                      Tl(
                        duration: 1.2,
                        vars: const GsapVars(scale: 0.3, opacity: 0),
                        ease: Ease.power3Out,
                        child: GsapLoop(
                          scale: 1.08,
                          duration: 1.8,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: LP.cream,
                              boxShadow: [
                                BoxShadow(
                                  color: LP.brandYellow.withValues(alpha: 0.28),
                                  blurRadius: 70,
                                  spreadRadius: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Tl(
                        at: 0.15,
                        duration: 1.0,
                        vars: const GsapVars(scale: 0.55, y: 30, opacity: 0),
                        ease: Ease.backOutSoft,
                        child: const GsapLoop(y: -6, duration: 2.2, child: BrandLogo(size: 280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Tl(
                  at: 0.9,
                  duration: 0.7,
                  child: Text(
                    'La garde de vos animaux,\nen toute confiance',
                    textAlign: TextAlign.center,
                    style: LPText.bodyL.copyWith(color: LP.muted, height: 1.4),
                  ),
                ),
                const Spacer(flex: 2),
                const Tl(at: 1.2, duration: 0.6, child: _PawTrail()),
                const SizedBox(height: 18),
                Tl(
                  at: 1.3,
                  duration: 0.6,
                  child: Text('Tunis · Sousse · Sfax', style: LPText.overline.copyWith(color: LP.faint)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur de chargement : des empreintes qui « marchent » de gauche à droite.
class _PawTrail extends StatefulWidget {
  const _PawTrail();

  @override
  State<_PawTrail> createState() => _PawTrailState();
}

class _PawTrailState extends State<_PawTrail> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  static const _count = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reducedMotion(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Chargement',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _count; i++)
              Builder(
                builder: (_) {
                  // chaque empreinte s'allume puis s'éteint, décalée de la précédente
                  final phase = (_c.value * (_count + 2) - i).clamp(0.0, 2.0);
                  final o = reducedMotion(context) ? 1.0 : (phase <= 1 ? phase : 2 - phase);
                  return Transform.translate(
                    offset: Offset(0, i.isEven ? -4 : 4),
                    child: Transform.rotate(
                      angle: 1.5708,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(
                          PhosphorIconsFill.pawPrint,
                          size: 18,
                          color: Color.lerp(
                            LP.softDeep,
                            i.isEven ? LP.brandGreen : LP.brandYellow,
                            Ease.power2Out.transform(o),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
