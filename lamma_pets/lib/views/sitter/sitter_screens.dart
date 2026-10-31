import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/view_models/sitter_space_view_model.dart';
import 'package:pet_sitter/core/widgets/floating_nav.dart';
import 'package:pet_sitter/core/widgets/month_calendar.dart';
import 'package:pet_sitter/views/messages/messages_screens.dart';

// ————————————————————————————————————————————— SHELL SITTER

class SitterShell extends StatefulWidget {
  const SitterShell({super.key, this.initialTab = 0, this.preview});
  final int initialTab;

  /// Aperçu transmis à la page de l'onglet initial (captures du sommaire).
  final String? preview;

  @override
  State<SitterShell> createState() => _SitterShellState();
}

class _SitterShellState extends State<SitterShell> {
  late int _tab = widget.initialTab;

  static const _items = [
    NavItem(PhosphorIconsRegular.squaresFour, PhosphorIconsFill.squaresFour, 'Accueil'),
    NavItem(PhosphorIconsRegular.calendarDots, PhosphorIconsFill.calendarDots, 'Calendrier'),
    NavItem(PhosphorIconsRegular.chatCircleDots, PhosphorIconsFill.chatCircleDots, 'Messages', badge: true),
    NavItem(PhosphorIconsRegular.userCircle, PhosphorIconsFill.userCircle, 'Profil'),
  ];

  Widget _page() => switch (_tab) {
    0 => SitterDashboardScreen(preview: _tab == widget.initialTab ? widget.preview : null),
    1 => const AvailabilityScreen(embedded: true),
    2 => const MessagesListScreen(asSitter: true),
    _ => const _SitterAccount(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: KeyedSubtree(key: ValueKey(_tab), child: _page()),
      bottomNavigationBar: FloatingNav(items: _items, index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

// ————————————————————————————————————————————— TABLEAU DE BORD

class SitterDashboardScreen extends StatefulWidget {
  const SitterDashboardScreen({super.key, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  @override
  State<SitterDashboardScreen> createState() => _SitterDashboardScreenState();
}

class _SitterDashboardScreenState extends State<SitterDashboardScreen> {
  late final vm = SitterDashboardViewModel(Deps.of(context).sitterSpace);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preview == 'refuse') _refuse(vm.requests.first);
      if (widget.preview == 'accepted') vm.accept(vm.requests.first);
    });
  }

  Future<void> _refuse(SitterRequest r) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => _RefuseSheet(owner: r.owner),
    );
    if (ok == true) vm.refuse(r);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final pending = vm.pendingCount;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
            child: Row(
              children: [
                LPAvatar(vm.me.photo, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Espace pet sitter', style: LPText.bodyS.copyWith(fontSize: 14.5)),
                          const SizedBox(width: 8),
                          const FictifBadge(),
                        ],
                      ),
                      Text('Bonjour, Amira', style: LPText.h2),
                    ],
                  ),
                ),
                RoundIconButton(PhosphorIconsRegular.bell, badge: true, tooltip: 'Notifications'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Repères — sur une seule bande, sans cartes multiples
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
            decoration: BoxDecoration(color: LP.night, borderRadius: BorderRadius.circular(LP.r28)),
            child: Row(
              children: [
                _kpi('$pending', 'demande${pending > 1 ? 's' : ''}\nen attente'),
                _sep(),
                _kpi('3', 'gardes\nà venir'),
                _sep(),
                _kpi('420 DT', 'gagnés\nen octobre'),
              ],
            ),
          ).from(y: 24, scale: 0.96, delay: 0.1, duration: 0.7),

          const SizedBox(height: 28),
          SectionHeader('Demandes reçues', action: pending > 0 ? '$pending nouvelle${pending > 1 ? 's' : ''}' : null),
          for (final (i, r) in vm.requests.indexed) ...[
            _requestTile(r).from(y: 30, delay: stagger(i, start: 0.25, each: 0.1)),
            const Divider(indent: 20, endIndent: 20),
          ],

          const SizedBox(height: 24),
          const SectionHeader('Gardes à venir'),
          for (final u in vm.upcoming) _upcoming(u.photo, u.pets, u.who, u.when, live: u.live),

          const SizedBox(height: 24),
          const SectionHeader('Gérer mon activité'),
          LPListTile(
            icon: PhosphorIconsRegular.calendarDots,
            title: 'Calendrier de disponibilité',
            subtitle: '9 jours bloqués en novembre',
            onTap: () => Navigator.pushNamed(context, R.availability),
          ),
          LPListTile(
            icon: PhosphorIconsRegular.tag,
            title: 'Services et tarifs',
            subtitle: 'Accueil 35 DT / nuit · Visite 18 DT / visite',
            onTap: () => Navigator.pushNamed(context, R.services),
          ),
          LPListTile(
            icon: PhosphorIconsRegular.eye,
            title: 'Voir mon profil public',
            onTap: () => Navigator.pushNamed(context, R.sitter, arguments: vm.me),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String v, String l) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(v, style: LPText.display(size: 22, color: LP.white)),
        const SizedBox(height: 2),
        Text(l, style: LPText.body(size: 12.5, color: LP.mint, height: 1.25)),
      ],
    ),
  );

  Widget _sep() => Container(
    width: 1,
    height: 40,
    color: LP.white.withValues(alpha: 0.2),
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );

  Widget _requestTile(SitterRequest r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LPAvatar(r.petPhoto, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.pets, style: LPText.title.copyWith(fontSize: 15.5)),
                    Text('De ${r.owner} · ${r.received}', style: LPText.bodyS.copyWith(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _info(PhosphorIconsRegular.houseLine, r.service),
          _info(PhosphorIconsRegular.calendarBlank, r.dates),
          _info(PhosphorIconsRegular.coins, 'Vous recevez ${r.earn} DT', strong: true),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r12)),
            child: Text(
              '« ${r.message} »',
              style: LPText.body(size: 14, color: LP.ink).copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (r.state) {
              RequestState.pending => Row(
                key: const ValueKey('p'),
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: LP.error,
                        side: const BorderSide(color: LP.line, width: 1.4),
                      ),
                      onPressed: () => _refuse(r),
                      child: const Text('Refuser'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                      onPressed: () => vm.accept(r),
                      icon: const Icon(PhosphorIconsBold.check, size: 18),
                      label: const Text('Accepter'),
                    ),
                  ),
                ],
              ),
              RequestState.accepted => InfoNote(
                'Demande acceptée. ${r.owner} est prévenu·e et peut finaliser le paiement.',
                key: const ValueKey('a'),
                icon: PhosphorIconsRegular.checkCircle,
                tone: InfoTone.success,
              ),
              RequestState.refused => InfoNote(
                'Demande refusée. ${r.owner} a reçu votre message.',
                key: const ValueKey('r'),
                icon: PhosphorIconsRegular.xCircle,
              ),
            },
          ),
        ],
      ),
    );
  }

  Widget _info(IconData i, String t, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(i, size: 17, color: strong ? LP.primary : LP.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t,
            style: LPText.body(
              size: 14,
              w: strong ? FontWeight.w700 : FontWeight.w500,
              color: strong ? LP.primary : LP.ink,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _upcoming(String photo, String pets, String who, String when, {bool live = false}) => InkWell(
    onTap: live ? () => Navigator.pushNamed(context, R.journal, arguments: true) : null,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          LPAvatar(photo, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pets, style: LPText.label.copyWith(fontSize: 15)),
                Text(who, style: LPText.bodyS.copyWith(fontSize: 13)),
              ],
            ),
          ),
          live
              ? const Pill(label: 'En cours', bg: LP.accentSoft, fg: LP.accentInk, icon: PhosphorIconsBold.heartbeat)
              : Text(when, style: LPText.bodyS.copyWith(fontSize: 12.5)),
        ],
      ),
    ),
  );
}

class _RefuseSheet extends StatefulWidget {
  const _RefuseSheet({required this.owner});
  final String owner;

  @override
  State<_RefuseSheet> createState() => _RefuseSheetState();
}

class _RefuseSheetState extends State<_RefuseSheet> {
  String? _reason;
  static const _reasons = [
    'Je ne suis plus disponible à ces dates',
    'Ces besoins dépassent mes compétences',
    'J\'ai déjà trop d\'animaux sur cette période',
    'Autre raison',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Refuser la demande', style: LPText.h2),
          const SizedBox(height: 6),
          Text(
            '${widget.owner} recevra un message courtois et des suggestions d\'autres sitters.',
            style: LPText.bodyS,
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v),
            child: Column(
              children: [
                for (final r in _reasons)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: r,
                    title: Text(r, style: LPText.bodyM),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: LP.error),
              onPressed: _reason == null ? null : () => Navigator.pop(context, true),
              child: const Text('Confirmer le refus'),
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— CALENDRIER DE DISPONIBILITÉ

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final vm = AvailabilityViewModel(Deps.of(context).sitterSpace);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final off = vm.off;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.embedded,
        leading: widget.embedded ? null : const BackButton(),
        title: Text('Disponibilités', style: widget.embedded ? LPText.h2 : null),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, widget.embedded ? 130 : 32),
        children: [
          Text(
            'Touchez un jour pour l\'ouvrir ou le bloquer. Les jours réservés ne peuvent pas être modifiés.',
            style: LPText.bodyS,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(vm.monthLabel, style: LPText.h3)),
              RoundIconButton(
                PhosphorIconsRegular.caretLeft,
                size: 40,
                tooltip: 'Mois précédent',
                onTap: vm.canGoBack ? vm.previousMonth : null,
              ),
              const SizedBox(width: 8),
              RoundIconButton(
                PhosphorIconsRegular.caretRight,
                size: 40,
                tooltip: 'Mois suivant',
                onTap: vm.canGoForward ? vm.nextMonth : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          MonthCalendar(
            month: vm.monthDate,
            showHeader: false,
            today: vm.month == 0 ? 16 : 0,
            unavailable: off,
            booked: vm.booked,
            onTapDay: vm.toggleDay,
          ),
          const SizedBox(height: 12),
          const CalendarLegend(withSelection: false),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: vm.openAll,
                  child: const Text('Tout ouvrir'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  onPressed: vm.blockWeekends,
                  child: const Text('Bloquer les week-ends'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text('Règles de réservation', style: LPText.h3),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Animaux en même temps', style: LPText.label),
                    Text('Toutes familles confondues', style: LPText.bodyS),
                  ],
                ),
              ),
              Counter(value: vm.maxPets, min: 1, max: 6, onChanged: vm.setMaxPets),
            ],
          ),
          const SizedBox(height: 20),
          Text('Délai de prévenance minimum', style: LPText.label),
          const SizedBox(height: 10),
          ChoiceGroup(
            options: const ['Aucun', '24 h', '48 h', '1 semaine'],
            selected: {vm.notice},
            onTap: vm.setNotice,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: vm.lastMinute,
            onChanged: vm.setLastMinute,
            title: Text('Accepter les demandes de dernière minute', style: LPText.bodyL),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Disponibilités enregistrées.'))),
              child: const Text('Enregistrer'),
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— SERVICES ET TARIFS

class ServicesPricingScreen extends StatefulWidget {
  const ServicesPricingScreen({super.key});

  @override
  State<ServicesPricingScreen> createState() => _ServicesPricingScreenState();
}

class _ServicesPricingScreenState extends State<ServicesPricingScreen> {
  late final vm = ServicesPricingViewModel(Deps.of(context).sitterSpace);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Services et tarifs')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Text(
            'Activez les services que vous proposez et fixez votre prix. Les propriétaires voient toujours l\'unité (par nuit, par visite…).',
            style: LPText.bodyS,
          ),
          const SizedBox(height: 10),
          for (final s in vm.services) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: s.on ? LP.accentSoft : LP.soft, shape: BoxShape.circle),
                        child: Icon(s.icon, size: 21, color: s.on ? LP.accentInk : LP.muted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name, style: LPText.title.copyWith(fontSize: 16, color: s.on ? LP.ink : LP.muted)),
                            Text(s.detail, style: LPText.bodyS.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      Switch(value: s.on, onChanged: (v) => vm.toggleService(s, v)),
                    ],
                  ),
                  if (s.on) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 54),
                        Text('Tarif', style: LPText.label),
                        const Spacer(),
                        Counter(value: s.price, min: 5, max: 200, onChanged: (v) => vm.setPrice(s, v)),
                        const SizedBox(width: 8),
                        SizedBox(width: 78, child: Text('DT / ${s.unit}', style: LPText.bodyS)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Supplément par animal', style: LPText.label),
                    Text('Appliqué à partir du 2ᵉ animal', style: LPText.bodyS),
                  ],
                ),
              ),
              Counter(value: vm.extraPetFee, max: 50, onChanged: vm.setExtraPetFee),
              const SizedBox(width: 6),
              Text('DT', style: LPText.bodyS),
            ],
          ),
          const SizedBox(height: 28),
          Text('Espèces acceptées', style: LPText.h3),
          const SizedBox(height: 12),
          ChoiceGroup(
            options: [for (final s in Species.values) s.plural],
            selected: {for (final s in vm.species) s.plural},
            onTap: (l) => vm.toggleSpecies(Species.values.firstWhere((e) => e.plural == l)),
          ),
          const SizedBox(height: 24),
          const InfoNote(
            'Prix moyens observés à La Marsa : accueil 30–40 DT / nuit, visite 15–20 DT.',
            icon: PhosphorIconsRegular.chartBar,
          ),
          const SizedBox(height: 24),
          LoadingButton(
            label: 'Enregistrer les modifications',
            loading: vm.saving,
            onPressed: () async {
              await vm.save();
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Services et tarifs mis à jour.')));
            },
          ),
        ],
      ),
    );
  }
}

class _SitterAccount extends StatelessWidget {
  const _SitterAccount();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SitterDashboardViewModel>(
      create: (context) => SitterDashboardViewModel(Deps.of(context).sitterSpace),
      builder: (context, vm) => _content(context, vm.me),
    );
  }

  Widget _content(BuildContext context, Sitter me) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                LPAvatar(me.photo, size: 72),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amira B.', style: LPText.h2),
                      Text('Pet sitter · La Marsa', style: LPText.bodyS),
                      const SizedBox(height: 6),
                      const FictifBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LPListTile(
            icon: PhosphorIconsRegular.eye,
            title: 'Mon profil public',
            onTap: () => Navigator.pushNamed(context, R.sitter, arguments: me),
          ),
          LPListTile(
            icon: PhosphorIconsRegular.tag,
            title: 'Services et tarifs',
            onTap: () => Navigator.pushNamed(context, R.services),
          ),
          LPListTile(icon: PhosphorIconsRegular.sealCheck, title: 'Vérifications', subtitle: '3 sur 3 effectuées'),
          LPListTile(
            icon: PhosphorIconsRegular.wallet,
            title: 'Versements',
            subtitle: 'Prochain versement : 135 DT le 27 oct.',
          ),
          LPListTile(
            icon: PhosphorIconsRegular.arrowsLeftRight,
            title: 'Passer en mode propriétaire',
            subtitle: 'Faire garder mes propres animaux',
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, R.owner, (r) => r.settings.name == R.catalog),
          ),
          LPListTile(
            icon: PhosphorIconsRegular.gearSix,
            title: 'Paramètres',
            onTap: () => Navigator.pushNamed(context, R.settings),
          ),
        ],
      ),
    );
  }
}
