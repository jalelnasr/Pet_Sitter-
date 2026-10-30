import 'package:flutter/material.dart';

import 'package:pet_sitter/data/sources/mock_data.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/big_shapes.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/view_models/onboarding_view_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.initialPage = 0});
  final int initialPage;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final vm = OnboardingViewModel(pageCount: _pages.length, initialPage: widget.initialPage);

  late final _ctrl = PageController(initialPage: widget.initialPage);

  static final _pages = [
    (
      BigShape.paw,
      LP.brandYellow,
      LP.cream,
      Photos.catTuxedo,
      'Partez l\'esprit tranquille',
      'Trouvez près de chez vous une personne de confiance pour votre chat, chien, oiseau, lapin ou poisson.',
    ),
    (
      BigShape.house,
      LP.brandGreen,
      LP.cream,
      Photos.rabbitWhite,
      'Une garde adaptée à ses habitudes',
      'Accueil chez le sitter ou visites à domicile : choisissez ce qui lui convient le mieux.',
    ),
    (
      BigShape.bubble,
      LP.brandGreen,
      LP.brandYellow,
      Photos.lovebird,
      'Gardez le lien, même à distance',
      'Messages et nouvelles en photos tout au long de la garde.',
    ),
  ];

  void _next() => _ctrl.nextPage(duration: const Duration(milliseconds: 520), curve: Ease.power3Out);

  @override
  void dispose() {
    vm.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      backgroundColor: LP.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const Wordmark(size: 19).from(y: -12, duration: 0.5),
                  const Spacer(),
                  // « Passer » s'efface sur le dernier écran : aucun autre bouton ne prend sa place,
                  // pour qu'un double appui ne mène jamais à un écran inattendu.
                  AnimatedOpacity(
                    opacity: vm.isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 220),
                    child: IgnorePointer(
                      ignoring: vm.isLast,
                      child: TextButton(
                        onPressed: () => _ctrl.animateToPage(
                          _pages.length - 1,
                          duration: const Duration(milliseconds: 620),
                          curve: Ease.power3Out,
                        ),
                        child: const Text('Passer'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: vm.setPage,
                itemBuilder: (_, i) {
                  final (shape, color, cutout, photo, title, body) = _pages[i];
                  return GsapTimeline(
                    duration: 1.9,
                    autoplay: i == vm.page,
                    replayKey: i == vm.page,
                    child: _Slide(shape: shape, color: color, cutout: cutout, photo: photo, title: title, body: body),
                  );
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 360),
              curve: Ease.power3Out,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 20, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Ease.power3Out,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: vm.isLast
                      ? Column(
                          key: const ValueKey('end'),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _Dots(count: _pages.length, index: vm.page),
                            ),
                            const SizedBox(height: 16),
                            PawButton(
                              label: 'Créer un compte',
                              onPressed: () => Navigator.pushNamed(context, R.signup),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => Navigator.pushNamed(context, R.login),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Déjà inscrit ? ',
                                      style: LPText.body(size: 15, color: LP.muted),
                                    ),
                                    const TextSpan(text: 'Se connecter'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('next'),
                          children: [
                            _Dots(count: _pages.length, index: vm.page),
                            const Spacer(),
                            PawButton(label: 'Suivant', dark: false, expand: false, onPressed: _next),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.shape,
    required this.color,
    required this.cutout,
    required this.photo,
    required this.title,
    required this.body,
  });
  final BigShape shape;
  final Color color;
  final Color cutout;
  final String photo;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // trait de fond qui se dessine
        Positioned.fill(
          child: TlValue(
            duration: 1.5,
            ease: Ease.power2InOut,
            builder: (_, t) => CustomPaint(painter: SquigglePainter(t, color: const Color(0xFFFBE6AE))),
          ),
        ),
        Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final side = (c.maxHeight * 0.9).clamp(200.0, 330.0);
                  return Center(
                    child: SizedBox(
                      width: side * 1.05,
                      height: side,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            width: side * 0.86,
                            height: side * 0.86,
                            child: Tl(
                              at: 0.05,
                              duration: 0.9,
                              vars: const GsapVars(scale: 0.4, rotation: -14, opacity: 0),
                              ease: Ease.backOutSoft,
                              child: CustomPaint(
                                painter: BigShapePainter(shape, color: color, cutout: cutout),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: side * 0.02,
                            width: side * 0.44,
                            height: side * 0.44,
                            child: Tl(
                              at: 0.4,
                              duration: 0.8,
                              vars: const GsapVars(x: 70, rotation: 10, opacity: 0),
                              child: GsapLoop(
                                y: -7,
                                rotation: 1.5,
                                duration: 2.6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: const [
                                      BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12)),
                                    ],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: LPImage(photo, radius: 6, width: side * 0.44, height: side * 0.44),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  TlSplitWords(
                    title,
                    at: 0.55,
                    style: LPText.display(size: 34, color: LP.primaryDark),
                    trailing: const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 10),
                      child: Icon(PhosphorIconsFill.pawPrint, size: 22, color: LP.accent),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Tl(
                    at: 0.95,
                    duration: 0.7,
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      style: LPText.bodyM.copyWith(color: const Color(0xFF2E3A36)),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Écran ${index + 1} sur $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 420),
              curve: Ease.power3Out,
              margin: const EdgeInsets.only(right: 5),
              width: i == index ? 28 : 12,
              height: 6,
              decoration: BoxDecoration(
                color: i == index ? LP.primary : LP.mintBg,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}
