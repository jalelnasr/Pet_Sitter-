import 'package:flutter/material.dart';
export 'package:pet_sitter/core/utils/format.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';

/// Image réseau avec fond doux pendant le chargement et repli illustré en cas d'erreur.
class LPImage extends StatelessWidget {
  const LPImage(this.url, {super.key, this.width, this.height, this.radius = LP.r16, this.fit = BoxFit.cover});
  final String url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget placeholder([bool error = false]) => Container(
      width: width,
      height: height,
      color: LP.soft,
      alignment: Alignment.center,
      child: Icon(error ? PhosphorIconsRegular.image : PhosphorIconsRegular.pawPrint, color: LP.softDeep, size: 28),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        frameBuilder: (context, child, frame, sync) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: frame == null && !sync ? placeholder() : child,
        ),
        errorBuilder: (_, _, _) => placeholder(true),
      ),
    );
  }
}

class LPAvatar extends StatelessWidget {
  const LPAvatar(this.url, {super.key, this.size = 48, this.ring = false});
  final String url;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final img = LPImage(url, width: size, height: size, radius: size);
    if (!ring) return img;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(color: LP.bg, shape: BoxShape.circle),
      child: img,
    );
  }
}

/// Badge qui signale clairement un exemple fictif.
class FictifBadge extends StatelessWidget {
  const FictifBadge({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: onDark ? LP.bg : LP.accentSoft, borderRadius: BorderRadius.circular(99)),
      child: Text(
        'Profil fictif',
        style: LPText.body(size: 11.5, w: FontWeight.w700, color: LP.accentInk, height: 1.2),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding = LP.pagePadding});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: LPText.h3)),
          if (action != null)
            TextButton(
              onPressed: onAction ?? () {},
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Tarif toujours accompagné de son unité.
class PriceTag extends StatelessWidget {
  const PriceTag(this.amount, this.unit, {super.key, this.big = false, this.prefix});
  final int amount;
  final String unit;
  final bool big;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null) TextSpan(text: '$prefix ', style: LPText.bodyS),
          TextSpan(
            text: '$amount DT',
            style: LPText.price.copyWith(fontSize: big ? 22 : 17),
          ),
          TextSpan(
            text: ' / $unit',
            style: LPText.bodyS.copyWith(fontSize: big ? 15 : 13.5),
          ),
        ],
      ),
    );
  }
}

class SpeciesIcons extends StatelessWidget {
  const SpeciesIcons(this.species, {super.key, this.size = 18, this.color = LP.primary});
  final List<Species> species;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final s in species)
          Tooltip(
            message: s.plural,
            child: Container(
              width: size + 12,
              height: size + 12,
              decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
              child: Icon(s.icon, size: size, color: color, semanticLabel: s.plural),
            ),
          ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      BookingStatus.envoyee => (LP.infoSoft, LP.info, PhosphorIconsBold.paperPlaneRight),
      BookingStatus.attente => (LP.warningSoft, LP.warning, PhosphorIconsBold.hourglassMedium),
      BookingStatus.confirmee => (LP.mint, LP.primaryDark, PhosphorIconsBold.checkCircle),
      BookingStatus.enCours => (LP.accentSoft, LP.accentInk, PhosphorIconsBold.heartbeat),
      BookingStatus.terminee => (LP.soft, LP.muted, PhosphorIconsBold.check),
      BookingStatus.annulee => (LP.errorSoft, LP.error, PhosphorIconsBold.xCircle),
    };
    return Pill(label: status.label, bg: bg, fg: fg, icon: icon);
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.bg = LP.mint, this.fg = LP.primaryDark, this.icon});
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 5)],
          Text(
            label,
            style: LPText.body(size: 12.5, w: FontWeight.w700, color: fg, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Bouton plein avec état de chargement intégré.
class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key, required this.label, required this.onPressed, this.loading = false, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      PawButton(label: label, onPressed: onPressed, loading: loading, icon: icon ?? PhosphorIconsFill.pawPrint);
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton(
    this.icon, {
    super.key,
    this.onTap,
    this.bg = LP.bg,
    this.fg = LP.ink,
    this.size = 44,
    this.tooltip,
    this.badge = false,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;
  final double size;
  final String? tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: bg,
      shape: const CircleBorder(side: BorderSide(color: LP.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? () {},
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 22, color: fg),
              if (badge)
                Positioned(
                  top: size * 0.22,
                  right: size * 0.24,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: LP.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: bg, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
  }
}

class RatingLine extends StatelessWidget {
  const RatingLine(this.rating, this.count, {super.key, this.compact = false});
  final double rating;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(PhosphorIconsFill.star, size: 15, color: LP.accent),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1).replaceAll('.', ','), style: LPText.label.copyWith(fontSize: 13.5)),
        Text(compact ? ' ($count)' : ' · $count avis', style: LPText.bodyS),
      ],
    );
  }
}

class NewSitterTag extends StatelessWidget {
  const NewSitterTag({super.key});
  @override
  Widget build(BuildContext context) =>
      const Pill(label: 'Nouveau', bg: LP.mintPale, fg: LP.primary, icon: PhosphorIconsBold.sparkle);
}

/// Bandeau d'information discret (pas une carte).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.icon = PhosphorIconsRegular.info, this.tone = InfoTone.neutral});
  final String text;
  final IconData icon;
  final InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      InfoTone.neutral => (LP.soft, LP.muted),
      InfoTone.success => (LP.mintPale, LP.primaryDark),
      InfoTone.warning => (LP.warningSoft, LP.warning),
      InfoTone.error => (LP.errorSoft, LP.error),
      InfoTone.apricot => (LP.accentSoft, LP.accentInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(LP.r12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: LPText.body(size: 14, color: fg == LP.muted ? LP.ink : fg)),
          ),
        ],
      ),
    );
  }
}

enum InfoTone { neutral, success, warning, error, apricot }

/// Ligne de liste : icône, titre, sous-titre, chevron.
class LPListTile extends StatelessWidget {
  const LPListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = danger ? LP.error : LP.ink;
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: danger ? LP.errorSoft : LP.mintPale, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: danger ? LP.error : LP.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LPText.body(size: 15.5, w: FontWeight.w600, color: c, height: 1.3),
                  ),
                  if (subtitle != null) Text(subtitle!, style: LPText.bodyS),
                ],
              ),
            ),
            trailing ?? const Icon(PhosphorIconsRegular.caretRight, size: 18, color: LP.muted),
          ],
        ),
      ),
    );
  }
}

/// Barre d'action collée en bas d'écran.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: LP.bg,
        border: Border(top: BorderSide(color: LP.line)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.paddingOf(context).bottom),
      child: child,
    );
  }
}

/// Sélecteur d'espèce rond (catégorie visuelle).
class SpeciesPicker extends StatelessWidget {
  const SpeciesPicker({super.key, required this.selected, required this.onChanged, this.multi = false});
  final Set<Species> selected;
  final ValueChanged<Species> onChanged;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: LP.pagePadding,
        itemCount: Species.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = Species.values[i];
          final on = selected.contains(s);
          return Semantics(
            selected: on,
            button: true,
            label: s.plural,
            child: GestureDetector(
              onTap: () => onChanged(s),
              child: SizedBox(
                width: 64,
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: on ? LP.primary : LP.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: on ? LP.primary : LP.line, width: 1.4),
                      ),
                      child: Icon(on ? s.iconFill : s.icon, size: 28, color: on ? LP.white : LP.primary),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      s.label,
                      style: LPText.body(
                        size: 13,
                        w: on ? FontWeight.w700 : FontWeight.w500,
                        color: on ? LP.primaryDark : LP.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Groupe de puces à choix (simple ou multiple).
class ChoiceGroup extends StatelessWidget {
  const ChoiceGroup({super.key, required this.options, required this.selected, required this.onTap});
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(o),
            selected: selected.contains(o),
            showCheckmark: false,
            onSelected: (_) => onTap(o),
            labelStyle: LPText.body(
              size: 14,
              w: FontWeight.w600,
              color: selected.contains(o) ? LP.white : LP.ink,
              height: 1.2,
            ),
          ),
      ],
    );
  }
}

/// Compteur +/− (promenades, visites par jour…).
class Counter extends StatelessWidget {
  const Counter({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 10});
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(
          PhosphorIconsRegular.minus,
          size: 38,
          onTap: value > min ? () => onChanged(value - 1) : null,
          tooltip: 'Diminuer',
        ),
        SizedBox(
          width: 40,
          child: Text('$value', textAlign: TextAlign.center, style: LPText.title),
        ),
        RoundIconButton(
          PhosphorIconsRegular.plus,
          size: 38,
          onTap: value < max ? () => onChanged(value + 1) : null,
          tooltip: 'Augmenter',
        ),
      ],
    );
  }
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 22, this.color = LP.brandGreen});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pet Sitter',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LogoMark(size: size * 1.45),
          SizedBox(width: size * 0.35),
          Text(
            'Pet Sitter',
            style: brandFont(size: size, color: color),
          ),
        ],
      ),
    );
  }
}

/// Police du mot-symbole : géométrique et très grasse, comme le logo.
TextStyle brandFont({double size = 22, Color color = LP.brandGreen}) =>
    GoogleFonts.outfit(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1, letterSpacing: -0.4);

/// Logo complet fourni (maison verte, empreinte jaune, « Pet Sitter »).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 220});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/logo_pet_sitter.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    semanticLabel: 'Pet Sitter',
  );
}

/// Version vectorielle du symbole (maison + empreinte) pour les petites tailles.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: LogoPainter());
}

class LogoPainter extends CustomPainter {
  LogoPainter({this.draw = 1, this.paw = 1});

  /// Progression du tracé de la maison (0 → 1) et de l'apparition des coussinets.
  final double draw;
  final double paw;

  @override
  void paint(Canvas c, Size s) {
    final u = s.width / 100;
    final stroke = Paint()
      ..color = LP.brandGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final house = Path()
      ..moveTo(u * 31, u * 91)
      ..lineTo(u * 23, u * 91)
      ..quadraticBezierTo(u * 16, u * 91, u * 16, u * 84)
      ..lineTo(u * 16, u * 57)
      ..lineTo(u * 8, u * 51)
      ..lineTo(u * 50, u * 12)
      ..lineTo(u * 92, u * 51)
      ..lineTo(u * 84, u * 57)
      ..lineTo(u * 84, u * 84)
      ..quadraticBezierTo(u * 84, u * 91, u * 77, u * 91)
      ..lineTo(u * 69, u * 91);
    for (final m in house.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * draw.clamp(0, 1)), stroke);
    }
    if (draw > 0.6) {
      final t = ((draw - 0.6) / 0.4).clamp(0.0, 1.0);
      c.drawLine(Offset(u * 76, u * 31), Offset(u * 76, u * (31 - 15 * t)), stroke);
    }
    final p = Paint()..color = LP.brandYellow;
    void pad(int i, Rect r) {
      final k = ((paw * 5) - i).clamp(0.0, 1.0);
      if (k <= 0) return;
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.scale(Curves.easeOutBack.transform(k));
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height), p);
      c.restore();
    }

    pad(0, Rect.fromCenter(center: Offset(u * 31, u * 58), width: u * 11, height: u * 14));
    pad(1, Rect.fromCenter(center: Offset(u * 42.5, u * 44), width: u * 12, height: u * 16));
    pad(2, Rect.fromCenter(center: Offset(u * 57.5, u * 44), width: u * 12, height: u * 16));
    pad(3, Rect.fromCenter(center: Offset(u * 69, u * 58), width: u * 11, height: u * 14));
    final k = ((paw * 5) - 4).clamp(0.0, 1.0);
    if (k > 0) {
      c.save();
      c.translate(u * 50, u * 70);
      c.scale(Curves.easeOutBack.transform(k));
      final main = Path()
        ..moveTo(0, -u * 12)
        ..cubicTo(u * 9, -u * 12, u * 17, u * 2, u * 15, u * 9)
        ..cubicTo(u * 13, u * 14, u * 6, u * 11, 0, u * 11)
        ..cubicTo(-u * 6, u * 11, -u * 13, u * 14, -u * 15, u * 9)
        ..cubicTo(-u * 17, u * 2, -u * 9, -u * 12, 0, -u * 12)
        ..close();
      c.drawPath(main, p);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LogoPainter old) => old.draw != draw || old.paw != paw;
}

/// Bouton pilule avec pastille ronde et empreinte (signature visuelle Pet Sitter).
/// [dark] : pilule noire / pastille blanche. Sinon : pilule blanche / pastille noire.
class PawButton extends StatelessWidget {
  const PawButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.dark = true,
    this.loading = false,
    this.expand = true,
    this.icon = PhosphorIconsFill.pawPrint,
    this.mint = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool dark;
  final bool loading;
  final bool expand;
  final IconData icon;
  final bool mint;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = !enabled
        ? LP.softDeep
        : mint
        ? LP.mint
        : dark
        ? LP.primary
        : LP.white;
    final fg = !enabled ? LP.muted : (dark && !mint ? LP.white : LP.ink);
    final dotBg = dark && !mint ? LP.white : LP.primary;
    final dotFg = dark && !mint ? LP.primary : LP.accent;
    final h = mint ? 44.0 : 58.0;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: h - 10,
          height: h - 10,
          decoration: BoxDecoration(color: enabled ? dotBg : LP.soft, shape: BoxShape.circle),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: dotFg),
                )
              : Icon(icon, size: mint ? 17 : 22, color: enabled ? dotFg : LP.muted),
        ),
        SizedBox(width: mint ? 8 : 14),
        Flexible(
          fit: expand ? FlexFit.tight : FlexFit.loose,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              maxLines: 1,
              style: LPText.body(size: mint ? 14 : 16.5, w: FontWeight.w700, color: fg, height: 1.1),
            ),
          ),
        ),
        SizedBox(width: mint ? 14 : 18),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          color: bg,
          shape: StadiumBorder(side: dark || mint ? BorderSide.none : const BorderSide(color: LP.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: loading ? null : onPressed,
            child: SizedBox(
              height: h,
              child: Padding(padding: const EdgeInsets.only(left: 5), child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Puces d'espèce horizontales façon « All · Cat · Dog · Bird ».
class SpeciesChips extends StatelessWidget {
  const SpeciesChips({super.key, required this.selected, required this.onChanged, this.withAll = true});
  final Species? selected;
  final ValueChanged<Species?> onChanged;
  final bool withAll;

  @override
  Widget build(BuildContext context) {
    final items = <(Species?, String)>[if (withAll) (null, 'Tous'), for (final s in Species.values) (s, s.label)];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: LP.pagePadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (s, label) = items[i];
          final on = s == selected;
          return Semantics(
            selected: on,
            button: true,
            child: PressScale(
              child: GestureDetector(
                onTap: () => onChanged(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? LP.primary : LP.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: on ? LP.primary : LP.softDeep, width: 1.3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (s != null) ...[
                        Icon(on ? s.iconFill : s.icon, size: 17, color: on ? LP.white : LP.ink),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        label,
                        style: LPText.body(size: 14.5, w: FontWeight.w700, color: on ? LP.white : LP.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Bordure pointillée arrondie (tuiles de traits, encart « À propos »).
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.color = LP.nightLine, this.radius = 18, this.padding});
  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashPainter(color, radius),
    child: Padding(padding: padding ?? const EdgeInsets.all(14), child: child),
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => old.color != color;
}
