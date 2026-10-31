import 'package:flutter/material.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/big_shapes.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/view_models/sitter_profile_view_model.dart';
import 'package:pet_sitter/core/widgets/month_calendar.dart';

class SitterProfileScreen extends StatefulWidget {
  const SitterProfileScreen({super.key, required this.sitter});
  final Sitter sitter;

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  late final vm = SitterProfileViewModel(widget.sitter);

  Sitter get s => vm.sitter;

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Une seule colonne : le panneau sombre est peint après le cercle menthe et le recouvre.
    return GsapTimeline(
      duration: 1.6,
      child: Scaffold(
        backgroundColor: LP.bg,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_hero(context, w), _darkPanel(context), _lightSections(context)],
          ),
        ),
        bottomNavigationBar: _bottomBar(context),
      ),
    );
  }

  // ———— Visuel : grand cercle menthe + portrait

  Widget _hero(BuildContext context, double w) {
    return SizedBox(
      height: 330,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 40,
            child: Tl(
              duration: 1.0,
              vars: const GsapVars(scale: 0.55, opacity: 0),
              ease: Ease.power4Out,
              child: Container(
                width: w * 1.05,
                height: w * 1.05,
                decoration: const BoxDecoration(color: LP.mintBg, shape: BoxShape.circle),
              ),
            ),
          ),
          Positioned(
            top: 70,
            child: Tl(
              at: 0.15,
              duration: 0.9,
              vars: const GsapVars(y: 60, scale: 0.9, opacity: 0),
              child: LPAvatar(s.photo, size: 236),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Row(
                children: [
                  RoundIconButton(
                    PhosphorIconsRegular.caretLeft,
                    onTap: () => Navigator.maybePop(context),
                    tooltip: 'Retour',
                    bg: LP.white,
                  ),
                  const Spacer(),
                  RoundIconButton(PhosphorIconsRegular.shareNetwork, tooltip: 'Partager', bg: LP.white),
                  const SizedBox(width: 8),
                  BounceOnChange(
                    value: vm.favorite,
                    child: RoundIconButton(
                      vm.favorite ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                      fg: vm.favorite ? LP.error : LP.ink,
                      bg: LP.white,
                      tooltip: vm.favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                      onTap: vm.toggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ———— Panneau sombre en dôme

  Widget _darkPanel(BuildContext context) {
    final traits = <(IconData, String, String)>[
      if (vm.showVerifications)
        (PhosphorIconsRegular.sealCheck, 'Vérifiée', '${s.verifications.length} contrôles')
      else
        (PhosphorIconsRegular.sparkle, 'Nouveau', 'sur Pet Sitter'),
      (PhosphorIconsRegular.sparkle, '${s.yearsExperience} ans', 'd\'expérience'),
      (PhosphorIconsRegular.clock, vm.showReviews ? '< 2 h' : '—', 'de réponse'),
    ];
    return Transform.translate(
      offset: const Offset(0, -60),
      child: Tl(
        at: 0.3,
        duration: 0.9,
        vars: const GsapVars(y: 120, opacity: 1),
        ease: Ease.power4Out,
        child: ClipPath(
          clipper: const DomeClipper(rise: 58),
          child: Container(
            color: LP.night,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tuiles de traits : la centrale en pastille blanche
                SizedBox(
                  height: 172,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: _trait(traits[0], 0)),
                      const SizedBox(width: 10),
                      Tl(
                        at: 0.7,
                        duration: 0.9,
                        vars: const GsapVars(scale: 0.3, opacity: 0),
                        ease: Ease.elasticOut,
                        child: Container(
                          width: 108,
                          height: 108,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: const BoxDecoration(color: LP.white, shape: BoxShape.circle),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const GsapLoop(
                                scale: 1.15,
                                duration: 1.4,
                                child: Icon(PhosphorIconsFill.sparkle, size: 24, color: LP.accent),
                              ),
                              const SizedBox(height: 4),
                              Text(traits[1].$2, style: LPText.display(size: 19, w: FontWeight.w800)),
                              Text(traits[1].$3, style: LPText.body(size: 11.5, color: LP.muted, height: 1.1)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: _trait(traits[2], 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Tl(
                  at: 0.65,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${s.firstName} ${s.lastInitial}',
                          style: LPText.display(size: 26, color: LP.onNight, w: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (vm.showVerifications)
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: LP.accent, shape: BoxShape.circle),
                          child: const Icon(PhosphorIconsBold.check, size: 13, color: LP.primaryDark),
                        ),
                      const Spacer(),
                      const FictifBadge(onDark: true),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Tl(
                  at: 0.72,
                  child: Row(
                    children: [
                      Text('${s.area}, ${s.city}', style: LPText.body(size: 14, color: LP.onNightMuted)),
                      const Spacer(),
                      const Icon(PhosphorIconsRegular.mapPin, size: 15, color: LP.onNightMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${s.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                        style: LPText.body(size: 14, color: LP.onNightMuted),
                      ),
                    ],
                  ),
                ),
                if (vm.showReviews) ...[
                  const SizedBox(height: 8),
                  Tl(
                    at: 0.76,
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsFill.star, size: 15, color: LP.accent),
                        const SizedBox(width: 5),
                        Text(
                          s.rating!.toStringAsFixed(1).replaceAll('.', ','),
                          style: LPText.body(size: 14, w: FontWeight.w800, color: LP.onNight),
                        ),
                        Text(' · ${s.reviewCount} avis', style: LPText.body(size: 14, color: LP.onNightMuted)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Tl(
                  at: 0.82,
                  child: DashedBox(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'À propos',
                          style: LPText.body(size: 14, w: FontWeight.w800, color: LP.onNight),
                        ),
                        const SizedBox(height: 6),
                        Text(s.bio, style: LPText.body(size: 14, color: LP.onNightMuted, height: 1.55)),
                        const SizedBox(height: 12),
                        for (final e in s.experience)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(PhosphorIconsBold.check, size: 15, color: LP.accent),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(e, style: LPText.body(size: 14, color: LP.onNight)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Animaux acceptés',
                  style: LPText.body(size: 14, w: FontWeight.w800, color: LP.onNight),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < s.species.length; i++)
                      Tl(
                        at: 0.9 + i * 0.06,
                        duration: 0.5,
                        vars: GsapVars.pop,
                        ease: Ease.backOut,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                          decoration: BoxDecoration(color: LP.nightSoft, borderRadius: BorderRadius.circular(99)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(s.species[i].iconFill, size: 17, color: LP.accent),
                              const SizedBox(width: 7),
                              Text(
                                s.species[i].plural,
                                style: LPText.body(size: 14, w: FontWeight.w700, color: LP.onNight),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Services et tarifs',
                  style: LPText.body(size: 14, w: FontWeight.w800, color: LP.onNight),
                ),
                const SizedBox(height: 6),
                for (final o in s.services) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(color: LP.mint, shape: BoxShape.circle),
                          child: Icon(o.type.icon, size: 20, color: LP.primaryDark),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.name,
                                style: LPText.body(size: 15.5, w: FontWeight.w700, color: LP.onNight),
                              ),
                              Text(o.detail, style: LPText.body(size: 13, color: LP.onNightMuted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${o.price} DT',
                                style: LPText.price.copyWith(color: LP.onNight),
                              ),
                              TextSpan(
                                text: ' / ${o.unit}',
                                style: LPText.body(size: 13, color: LP.onNightMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(height: 1, color: LP.nightSoft),
                ],
                const SizedBox(height: 12),
                Text(
                  'Animal supplémentaire : +10 DT / ${s.mainOffer.unit} · médicaments sans supplément',
                  style: LPText.body(size: 13, color: LP.onNightMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _trait((IconData, String, String) t, int i) {
    return Tl(
      at: 0.55 + i * 0.08,
      duration: 0.6,
      vars: const GsapVars(y: 30, opacity: 0),
      ease: Ease.backOutSoft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: DashedBox(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.$1, size: 24, color: LP.onNight),
                const SizedBox(height: 6),
                Text(
                  t.$2,
                  style: LPText.body(size: 13.5, w: FontWeight.w800, color: LP.onNight, height: 1.1),
                ),
                Text(
                  t.$3,
                  style: LPText.body(size: 11.5, color: LP.onNightMuted, height: 1.2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ———— Sections claires

  Widget _lightSections(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.hostsAtHome) ...[
              _h('Le lieu d\'accueil'),
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.homePhotos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => LPImage(s.homePhotos[i], width: 170, height: 128, radius: 22),
                ),
              ),
              const SizedBox(height: 12),
              for (final f in s.homeFacts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.houseLine, size: 17, color: LP.muted),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: LPText.bodyM)),
                    ],
                  ),
                ),
            ],
            _h('Disponibilités'),
            MonthCalendar(
              month: DateTime(2026, 10),
              unavailable: const {18, 19, 30, 31},
              booked: const {20, 21, 22},
              selectedRange: (23, 26),
            ),
            const SizedBox(height: 10),
            const CalendarLegend(),
            _h('Avis'),
            if (vm.showReviews) ...[
              Row(
                children: [
                  Text(s.rating!.toStringAsFixed(1).replaceAll('.', ','), style: LPText.display(size: 44)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (_) => const Icon(PhosphorIconsFill.star, size: 17, color: LP.primary),
                        ),
                      ),
                      Text('${s.reviewCount} avis de propriétaires', style: LPText.bodyS),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final r in s.reviews)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: LP.mint,
                            child: Text(r.author[0], style: LPText.label.copyWith(color: LP.primaryDark)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.author, style: LPText.label),
                                Text('${r.petLine} · ${r.date}', style: LPText.bodyS.copyWith(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          Row(
                            children: List.generate(
                              r.rating,
                              (_) => const Icon(PhosphorIconsFill.star, size: 13, color: LP.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(r.text, style: LPText.bodyM),
                    ],
                  ),
                ),
              if (s.reviewCount > s.reviews.length)
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: () {},
                  child: Text('Voir les ${s.reviewCount} avis'),
                ),
            ] else
              InfoNote(
                '${s.firstName} débute sur Pet Sitter et n\'a pas encore reçu d\'avis. Prenez le temps d\'échanger avant de réserver.',
                icon: PhosphorIconsRegular.sparkle,
              ),
            _h('Annulation'),
            Text('Flexible : annulation gratuite jusqu\'à 48 h avant le début de la garde.', style: LPText.bodyM),
          ],
        ),
      ),
    );
  }

  Widget _h(String t) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 12),
    child: Text(t, style: LPText.h3),
  );

  // ———— Barre d'action sombre

  Widget _bottomBar(BuildContext context) {
    return Tl(
      at: 0.5,
      duration: 0.7,
      vars: const GsapVars(y: 90, opacity: 1),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(
          color: LP.night,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Contacter ${s.firstName}',
              excludeSemantics: true,
              child: PressScale(
                child: Material(
                  color: LP.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pushNamed(context, R.chat),
                    child: const SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(PhosphorIconsRegular.chatCircleDots, size: 24, color: LP.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PawButton(
                label: 'Demander une réservation',
                dark: false,
                onPressed: () => Navigator.pushNamed(context, R.booking, arguments: s),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
