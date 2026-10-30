import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/views/owner/owner_shell.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/view_models/booking_view_model.dart';

// ————————————————————————————————————————————— DEMANDE DE RÉSERVATION

class BookingRequestScreen extends StatefulWidget {
  const BookingRequestScreen({super.key, required this.sitter, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;
  final Sitter sitter;

  @override
  State<BookingRequestScreen> createState() => _BookingRequestScreenState();
}

class _BookingRequestScreenState extends State<BookingRequestScreen> {
  late final vm = BookingRequestViewModel(
    sitter: widget.sitter,
    bookings: Deps.of(context).bookings,
    pets: Deps.of(context).pets,
  );

  late final _notes = TextEditingController(text: vm.notes);

  Sitter get s => vm.sitter;

  @override
  void dispose() {
    vm.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preview == 'dates') _pickDates();
      if (widget.preview == 'visits') vm.setService(s.services.firstWhere((o) => o.type == ServiceType.visite));
    });
  }

  Future<void> _pickDates() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 10, 16),
      lastDate: DateTime(2027, 6, 30),
      initialDateRange: vm.dates,
      saveText: 'Valider',
    );
    if (r != null) vm.setDates(r);
  }

  Future<void> _send() async {
    vm.notes = _notes.text;
    await vm.send();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, R.status, arguments: BookingStatus.envoyee);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: const Text('Demande de réservation')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Row(
            children: [
              LPAvatar(s.photo, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avec ${s.firstName} ${s.lastInitial}', style: LPText.title),
                    Text('${s.area}, ${s.city}', style: LPText.bodyS),
                  ],
                ),
              ),
              const FictifBadge(),
            ],
          ),

          _step(1, 'Pour qui ?'),
          for (final p in vm.pets) _petRow(p),

          _step(2, 'Quel service ?'),
          for (final o in s.services) _serviceRow(o),
          if (vm.service.type == ServiceType.visite)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(child: Text('Visites par jour', style: LPText.label)),
                  Counter(value: vm.visitsPerDay, min: 1, max: 3, onChanged: vm.setVisitsPerDay),
                ],
              ),
            ),

          _step(3, 'Quelles dates ?'),
          Material(
            color: LP.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LP.r16),
              side: const BorderSide(color: LP.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(LP.r16),
              onTap: _pickDates,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _dateCol(
                        vm.service.type == ServiceType.accueil ? 'Dépôt' : 'Début',
                        vm.dates.start,
                        '18:00',
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.arrowRight, color: LP.muted, size: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _dateCol(vm.service.type == ServiceType.accueil ? 'Retour' : 'Fin', vm.dates.end, '10:00'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Disponible sur toutes ces dates',
            style: LPText.body(size: 13.5, color: LP.primary, w: FontWeight.w600),
          ),

          _step(4, 'Instructions pour ${s.firstName}'),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Habitudes, horaires, objets fournis, où trouver les clés…'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ['Croquettes fournies', 'Clés chez le gardien', 'Arrosez les plantes', 'Photos le soir'])
                ActionChip(
                  avatar: const Icon(PhosphorIconsRegular.plus, size: 15, color: LP.primary),
                  label: Text(c),
                  onPressed: () => _notes.text = '${_notes.text.trim()} $c.'.trim(),
                ),
            ],
          ),

          // Récapitulatif
          const SizedBox(height: 34),
          Text('Récapitulatif', style: LPText.h3),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r20)),
            child: Column(
              children: [
                _line('${vm.service.name}\n${vm.service.price} DT × ${vm.unitsLabel}', '${vm.quote.base} DT'),
                if (vm.quote.extra > 0)
                  _line(
                    'Animal supplémentaire\n${vm.quote.extraPetFee} DT × ${vm.selectedPets.length - 1} × ${vm.unitsLabel}',
                    '${vm.quote.extra} DT',
                  ),
                _line(
                  'Frais de service Pet Sitter',
                  '${vm.quote.serviceFee} DT',
                  info: 'Assistance 7j/7 et suivi de la garde',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: LP.softDeep),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: LPText.title),
                          Text(
                            'Durée : ${vm.unitsLabel} · ${vm.selectedPets.length} animal${vm.selectedPets.length > 1 ? 'aux' : ''}',
                            style: LPText.bodyS,
                          ),
                        ],
                      ),
                    ),
                    CountUp(vm.quote.total, suffix: ' DT', style: LPText.display(size: 28)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoNote(
            'Aucun paiement maintenant : vous ne payez qu\'une fois la demande acceptée. Annulation gratuite jusqu\'à 48 h avant.',
            icon: PhosphorIconsRegular.shieldCheck,
            tone: InfoTone.success,
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: LoadingButton(
          label: !vm.canSend ? 'Choisissez au moins un animal' : 'Envoyer la demande · ${vm.quote.total} DT',
          loading: vm.sending,
          onPressed: !vm.canSend ? null : _send,
        ),
      ),
    );
  }

  Widget _step(int n, String t) => Padding(
    padding: const EdgeInsets.only(top: 30, bottom: 12),
    child: Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: LP.primary, shape: BoxShape.circle),
          child: Text(
            '$n',
            style: LPText.body(size: 13, w: FontWeight.w700, color: LP.white, height: 1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(t, style: LPText.h3)),
      ],
    ),
  );

  Widget _petRow(Pet p) {
    final accepted = s.species.contains(p.species);
    final on = vm.isSelected(p);
    return Opacity(
      opacity: accepted ? 1 : 0.55,
      child: InkWell(
        borderRadius: BorderRadius.circular(LP.r16),
        onTap: accepted ? () => vm.togglePet(p) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              LPAvatar(p.photo, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: LPText.title.copyWith(fontSize: 16)),
                    Text(
                      accepted
                          ? '${p.species.label} · ${p.age}'
                          : '${s.firstName} ne garde pas les ${p.species.plural.toLowerCase()}',
                      style: LPText.bodyS,
                    ),
                  ],
                ),
              ),
              Checkbox(value: on, onChanged: accepted ? (_) => vm.togglePet(p) : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceRow(SitterService o) {
    final on = vm.service == o;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(LP.r16),
        onTap: () => vm.setService(o),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? LP.mintPale : LP.white,
            borderRadius: BorderRadius.circular(LP.r16),
            border: Border.all(color: on ? LP.primary : LP.line, width: on ? 1.8 : 1.2),
          ),
          child: Row(
            children: [
              Icon(o.type.icon, color: LP.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o.name, style: LPText.label.copyWith(fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(o.detail, style: LPText.bodyS.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PriceTag(o.price, o.unit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateCol(String label, DateTime d, String hour) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: LPText.bodyS.copyWith(fontSize: 12.5)),
      Text(capitalize(frDate(d)), style: LPText.title.copyWith(fontSize: 16)),
      Text('vers $hour', style: LPText.bodyS.copyWith(fontSize: 12.5)),
    ],
  );

  Widget _line(String l, String v, {String? info}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l, style: LPText.bodyM),
              if (info != null) Text(info, style: LPText.bodyS.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        Text(v, style: LPText.label.copyWith(fontSize: 15)),
      ],
    ),
  );
}

// ————————————————————————————————————————————— SUIVI DE LA DEMANDE

class BookingStatusScreen extends StatefulWidget {
  const BookingStatusScreen({super.key, this.status = BookingStatus.envoyee});
  final BookingStatus status;

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late final vm = BookingStatusViewModel(Deps.of(context).bookings, status: widget.status);

  Sitter get s => vm.sitter;

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final confirmed = vm.status == BookingStatus.confirmee;
    final sent = vm.status == BookingStatus.envoyee;
    final (icon, iconBg, iconFg, title, body) = switch (vm.status) {
      BookingStatus.envoyee => (
        PhosphorIconsBold.paperPlaneRight,
        LP.accentSoft,
        LP.accentInk,
        'Demande envoyée',
        '${s.firstName} a bien reçu votre demande pour Simba et Kiwi. Nous vous prévenons dès sa réponse.',
      ),
      BookingStatus.confirmee => (
        PhosphorIconsBold.check,
        LP.primary,
        LP.white,
        'Réservation confirmée',
        '${s.firstName} a accepté. Simba et Kiwi sont attendus le vendredi 23 octobre vers 18 h.',
      ),
      _ => (
        PhosphorIconsBold.hourglassMedium,
        LP.warningSoft,
        LP.warning,
        'En attente de réponse',
        '${s.firstName} consulte votre demande. ${s.responseTime.replaceFirst('Répond', 'Elle répond')}.',
      ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Fermer',
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Suivi de la demande'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 36, color: iconFg),
            ).from(key: ValueKey(vm.status), scale: 0.2, rotation: -30, duration: 1.1, ease: Ease.elasticOut),
          ),
          const SizedBox(height: 20),
          Text(title, style: LPText.h1).from(key: ValueKey('t${vm.status}'), y: 24, delay: 0.15),
          const SizedBox(height: 10),
          Text(body, style: LPText.bodyL.copyWith(color: LP.muted)),
          const SizedBox(height: 28),

          // Étapes
          _Timeline(status: vm.status),
          const SizedBox(height: 26),

          // Récapitulatif compact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r20)),
            child: Column(
              children: [
                Row(
                  children: [
                    LPAvatar(s.photo, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Accueil chez ${s.firstName}', style: LPText.label.copyWith(fontSize: 15)),
                          Text('Ven. 23 → lun. 26 oct. · 3 nuits', style: LPText.bodyS),
                        ],
                      ),
                    ),
                    const FictifBadge(),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final p in vm.pets) ...[
                      LPAvatar(p.photo, size: 30),
                      const SizedBox(width: 6),
                      Text(p.name, style: LPText.label.copyWith(fontSize: 13.5)),
                      const SizedBox(width: 14),
                    ],
                    const Spacer(),
                    Text('${vm.total} DT', style: LPText.price),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (confirmed)
            const InfoNote(
              'L\'adresse exacte et le numéro d\'Amira sont maintenant visibles dans la conversation.',
              icon: PhosphorIconsRegular.lockKeyOpen,
              tone: InfoTone.success,
            )
          else
            const InfoNote(
              'Sans réponse sous 24 h, la demande expire automatiquement. Aucun montant n\'est prélevé.',
              icon: PhosphorIconsRegular.clockCountdown,
            ),
          const SizedBox(height: 26),

          if (confirmed) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, R.chat),
                icon: const Icon(PhosphorIconsRegular.chatCircleDots, size: 20),
                label: Text('Écrire à ${s.firstName}'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(PhosphorIconsRegular.calendarPlus, size: 20),
                label: const Text('Ajouter à mon calendrier'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: sent ? vm.markPending : () => Navigator.pushNamed(context, R.chat),
                child: Text(sent ? 'Suivre ma demande' : 'Écrire à ${s.firstName}'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  R.owner,
                  (r) => r.settings.name == R.catalog,
                  arguments: OwnerTab.bookings,
                ),
                child: const Text('Voir mes réservations'),
              ),
            ),
            if (!sent) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: LP.error),
                  onPressed: () {},
                  child: const Text('Annuler la demande'),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: LP.muted),
                  onPressed: vm.simulateAcceptance,
                  icon: const Icon(PhosphorIconsRegular.play, size: 16),
                  label: Text('Aperçu : simuler l\'acceptation', style: LPText.bodyS),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status});
  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final idx = switch (status) {
      BookingStatus.envoyee => 0,
      BookingStatus.attente => 1,
      _ => 2,
    };
    final steps = [
      ('Demande envoyée', 'Aujourd\'hui, 14:32'),
      ('En attente de réponse', idx >= 1 ? 'Vue par Amira à 14:40' : 'Amira est notifiée'),
      ('Réservation confirmée', idx == 2 ? 'Aujourd\'hui, 15:05' : 'Après acceptation et paiement'),
    ];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          GsapFrom(
            key: ValueKey('$status$i'),
            vars: GsapVars.fadeLeft,
            delay: stagger(i, start: 0.3, each: 0.12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: i < idx || (i == idx && idx == 2)
                              ? LP.primary
                              : i == idx
                              ? LP.accent
                              : LP.bg,
                          shape: BoxShape.circle,
                          border: Border.all(color: i <= idx ? Colors.transparent : LP.softDeep, width: 2),
                        ),
                        child: i < idx || (i == idx && idx == 2)
                            ? const Icon(PhosphorIconsBold.check, size: 14, color: LP.white)
                            : i == idx
                            ? const Icon(PhosphorIconsBold.dotsThree, size: 14, color: LP.primaryDark)
                            : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: i < idx ? LP.primary : LP.softDeep,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 22, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: LPText.body(
                              size: 15.5,
                              w: i <= idx ? FontWeight.w700 : FontWeight.w500,
                              color: i <= idx ? LP.ink : LP.muted,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(steps[i].$2, style: LPText.bodyS),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
