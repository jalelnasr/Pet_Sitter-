import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mini-moteur de motion inspiré de GSAP, en Flutter natif.
///
/// GSAP est une bibliothèque JavaScript : elle ne tourne pas dans Flutter.
/// On en reprend ici le modèle — `gsap.from()`, timelines à position,
/// `stagger`, `yoyo`, eases nommées — avec des AnimationController.
/// Toutes les animations se désactivent si l'utilisateur a demandé
/// la réduction des animations (MediaQuery.disableAnimations).

/// Eases au nom GSAP (power1 = quad, power2 = cubic, power3 = quart, power4 = quint).
class Ease {
  Ease._();
  static const Curve none = Curves.linear;
  static const Curve power1Out = Curves.easeOutQuad;
  static const Curve power2Out = Curves.easeOutCubic;
  static const Curve power3Out = Curves.easeOutQuart;
  static const Curve power4Out = Curves.easeOutQuint;
  static const Curve power2InOut = Curves.easeInOutCubic;
  static const Curve expoOut = Curves.easeOutExpo;
  static const Curve sineInOut = Curves.easeInOutSine;
  static const Curve backOut = Curves.easeOutBack; // back.out(1.7)
  static const Curve backOutSoft = Cubic(0.34, 1.36, 0.64, 1); // back.out(1.2)
  static const Curve elasticOut = ElasticOutCurve(0.55); // elastic.out(1, 0.55)
}

bool reducedMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Propriétés de départ d'un tween « from ».
class GsapVars {
  const GsapVars({this.opacity = 0, this.x = 0, this.y = 0, this.scale = 1, this.rotation = 0});
  final double opacity;
  final double x;
  final double y;
  final double scale;
  final double rotation; // en degrés

  static const fadeUp = GsapVars(y: 28);
  static const fadeDown = GsapVars(y: -20);
  static const fadeLeft = GsapVars(x: 32);
  static const pop = GsapVars(scale: 0.6);
}

Widget _applyVars(GsapVars v, double t, Widget child) {
  // t : 0 = état « from », 1 = état naturel
  final inv = 1 - t;
  return Opacity(
    opacity: (v.opacity + (1 - v.opacity) * t).clamp(0.0, 1.0),
    child: Transform.translate(
      offset: Offset(v.x * inv, v.y * inv),
      child: Transform.rotate(
        angle: v.rotation * inv * math.pi / 180,
        child: Transform.scale(scale: v.scale + (1 - v.scale) * t, child: child),
      ),
    ),
  );
}

// ————————————————————————————————————————————— gsap.from()

/// `gsap.from(el, {y: 28, opacity: 0, duration: .6, delay, ease})`
class GsapFrom extends StatefulWidget {
  const GsapFrom({
    super.key,
    required this.child,
    this.vars = GsapVars.fadeUp,
    this.duration = 0.6,
    this.delay = 0,
    this.ease = Ease.power3Out,
  });

  final Widget child;
  final GsapVars vars;
  final double duration; // secondes, comme GSAP
  final double delay;
  final Curve ease;

  @override
  State<GsapFrom> createState() => _GsapFromState();
}

class _GsapFromState extends State<GsapFrom> with SingleTickerProviderStateMixin {
  // Le délai fait partie de la courbe (Interval) : un seul contrôleur, aucun Timer.
  late final double _total = widget.delay + widget.duration;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_total * 1000).round()),
  );
  late final CurvedAnimation _a = CurvedAnimation(
    parent: _c,
    curve: Interval(_total == 0 ? 0 : widget.delay / _total, 1, curve: widget.ease),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    reducedMotion(context) ? _c.value = 1 : _c.forward();
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => _applyVars(widget.vars, _a.value, child!),
    );
  }
}

extension GsapWidget on Widget {
  /// Raccourci : `monWidget.from(y: 30, delay: .2)`
  Widget from({
    double opacity = 0,
    double x = 0,
    double y = 0,
    double scale = 1,
    double rotation = 0,
    double duration = 0.6,
    double delay = 0,
    Curve ease = Ease.power3Out,
    Key? key,
  }) => GsapFrom(
    key: key,
    vars: GsapVars(opacity: opacity, x: x, y: y, scale: scale, rotation: rotation),
    duration: duration,
    delay: delay,
    ease: ease,
    child: this,
  );
}

/// `stagger: { each }` — délai progressif pour une liste d'éléments.
/// Au-delà de [max] éléments, plus de décalage (on n'anime pas une longue liste entière).
double stagger(int index, {double each = 0.06, double start = 0, int max = 8}) => start + math.min(index, max) * each;

// ————————————————————————————————————————————— Timeline

/// `gsap.timeline()` : un seul contrôleur, des segments placés à une position (en secondes).
/// Rejouable (`replay()`), comme `tl.restart()`.
class GsapTimeline extends StatefulWidget {
  const GsapTimeline({super.key, required this.duration, required this.child, this.autoplay = true, this.replayKey});
  final double duration;
  final Widget child;
  final bool autoplay;

  /// Changer cette valeur relance la timeline depuis le début.
  final Object? replayKey;

  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TimelineScope>()!.animation;

  static double durationOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TimelineScope>()!.duration;

  @override
  State<GsapTimeline> createState() => _GsapTimelineState();
}

class _GsapTimelineState extends State<GsapTimeline> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.duration * 1000).round()),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reducedMotion(context)) {
      _c.value = 1;
    } else if (widget.autoplay) {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(covariant GsapTimeline old) {
    super.didUpdateWidget(old);
    if (old.replayKey != widget.replayKey) {
      reducedMotion(context) ? _c.value = 1 : _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _TimelineScope(animation: _c, duration: widget.duration, child: widget.child);
}

class _TimelineScope extends InheritedWidget {
  const _TimelineScope({required this.animation, required this.duration, required super.child});
  final Animation<double> animation;
  final double duration;
  @override
  bool updateShouldNotify(_TimelineScope old) => old.animation != animation;
}

/// Segment de timeline : `tl.from(el, {...}, at)`.
class Tl extends StatelessWidget {
  const Tl({
    super.key,
    required this.child,
    this.at = 0,
    this.duration = 0.6,
    this.vars = GsapVars.fadeUp,
    this.ease = Ease.power3Out,
  });

  final Widget child;
  final double at;
  final double duration;
  final GsapVars vars;
  final Curve ease;

  @override
  Widget build(BuildContext context) {
    final parent = GsapTimeline.of(context);
    final total = GsapTimeline.durationOf(context);
    final start = (at / total).clamp(0.0, 1.0);
    final end = ((at + duration) / total).clamp(start, 1.0);
    final curve = Interval(start, end, curve: ease);
    return AnimatedBuilder(
      animation: parent,
      child: child,
      builder: (_, child) => _applyVars(vars, curve.transform(parent.value), child!),
    );
  }
}

/// Valeur brute d'un segment (pour piloter un CustomPainter, un tracé…).
class TlValue extends StatelessWidget {
  const TlValue({super.key, this.at = 0, this.duration = 1, this.ease = Ease.power2Out, required this.builder});
  final double at;
  final double duration;
  final Curve ease;
  final Widget Function(BuildContext, double t) builder;

  @override
  Widget build(BuildContext context) {
    final parent = GsapTimeline.of(context);
    final total = GsapTimeline.durationOf(context);
    final start = (at / total).clamp(0.0, 1.0);
    final end = ((at + duration) / total).clamp(start, 1.0);
    final curve = Interval(start, end, curve: ease);
    return AnimatedBuilder(animation: parent, builder: (c, _) => builder(c, curve.transform(parent.value)));
  }
}

/// Équivalent de SplitText + stagger : chaque mot monte à son tour.
class TlSplitWords extends StatelessWidget {
  const TlSplitWords(
    this.text, {
    super.key,
    required this.style,
    this.at = 0,
    this.each = 0.07,
    this.duration = 0.7,
    this.textAlign = TextAlign.center,
    this.trailing,
  });

  final String text;
  final TextStyle style;
  final double at;
  final double each;
  final double duration;
  final TextAlign textAlign;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final words = text.split(' ');
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        alignment: switch (textAlign) {
          TextAlign.center => WrapAlignment.center,
          TextAlign.right => WrapAlignment.end,
          _ => WrapAlignment.start,
        },
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (var i = 0; i < words.length; i++)
            ClipRect(
              child: Tl(
                at: at + i * each,
                duration: duration,
                vars: GsapVars(y: (style.fontSize ?? 30) * 1.1, opacity: 0),
                ease: Ease.power4Out,
                child: Text('${words[i]}${i < words.length - 1 ? ' ' : ''}', style: style),
              ),
            ),
          if (trailing != null)
            Tl(
              at: at + words.length * each,
              duration: 0.6,
              vars: const GsapVars(scale: 0, rotation: -40),
              ease: Ease.backOut,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— Boucles (repeat: -1, yoyo: true)

class GsapLoop extends StatefulWidget {
  const GsapLoop({
    super.key,
    required this.child,
    this.y = 0,
    this.x = 0,
    this.rotation = 0,
    this.scale = 1,
    this.duration = 2.4,
    this.ease = Ease.sineInOut,
  });

  final Widget child;
  final double y;
  final double x;
  final double rotation;
  final double scale;
  final double duration;
  final Curve ease;

  @override
  State<GsapLoop> createState() => _GsapLoopState();
}

class _GsapLoopState extends State<GsapLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (widget.duration * 1000).round()),
  );
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: widget.ease);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!reducedMotion(context)) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) {
        final t = _a.value;
        return Transform.translate(
          offset: Offset(widget.x * t, widget.y * t),
          child: Transform.rotate(
            angle: widget.rotation * t * math.pi / 180,
            child: Transform.scale(scale: 1 + (widget.scale - 1) * t, child: child),
          ),
        );
      },
    );
  }
}

// ————————————————————————————————————————————— Compteur (gsap.to(obj, {val, snap}))

class CountUp extends StatelessWidget {
  const CountUp(this.value, {super.key, required this.style, this.suffix = '', this.duration = 0.7});
  final int value;
  final TextStyle style;
  final String suffix;
  final double duration;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return Text('$value$suffix', style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: Duration(milliseconds: (duration * 1000).round()),
      curve: Ease.power3Out,
      builder: (_, v, _) => Text('${v.round()}$suffix', style: style),
    );
  }
}

// ————————————————————————————————————————————— Micro-interaction d'appui

/// Léger enfoncement au toucher (scale .96, 120 ms) puis retour en back.out.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96});
  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 120 : 380),
        curve: _down ? Ease.power2Out : Ease.backOut,
        child: widget.child,
      ),
    );
  }
}

/// Petit rebond quand une valeur change (favori, sélection…).
class BounceOnChange extends StatelessWidget {
  const BounceOnChange({super.key, required this.value, required this.child});
  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Ease.elasticOut,
      builder: (_, s, c) => Transform.scale(scale: s, child: c),
      child: child,
    );
  }
}

// ————————————————————————————————————————————— Transition de page

/// Transition entre écrans : fondu + montée de 24 px en power3.out (≈ 420 ms).
class GsapPageTransitionsBuilder extends PageTransitionsBuilder {
  const GsapPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reducedMotion(context)) return FadeTransition(opacity: animation, child: child);
    final a = CurvedAnimation(parent: animation, curve: Ease.power3Out, reverseCurve: Curves.easeInCubic);
    final out = CurvedAnimation(parent: secondaryAnimation, curve: Ease.power2Out);
    return AnimatedBuilder(
      animation: Listenable.merge([a, out]),
      child: child,
      builder: (_, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - a.value)),
          child: Transform.scale(scale: 1 - 0.03 * out.value, child: child),
        ),
      ),
    );
  }
}
