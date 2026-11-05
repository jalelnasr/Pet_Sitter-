/// Écrans Flutter du module Événements.
library;

import 'package:flutter/material.dart';
import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/data/sources/mock_data.dart' show Mock;

import 'event_mock.dart';
import 'event_models.dart';
import 'event_repository.dart';
import 'event_view_models.dart';
import 'event_widgets.dart';

// ————————————————————————————————————————————— LISTE DES ÉVÉNEMENTS

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({
    super.key,
    this.forceEmpty = false,
    this.repository,
  });

  /// Aperçu de l'état vide (pour les captures ou une route de démonstration).
  final bool forceEmpty;

  /// Dépôt utilisé : API réelle par défaut, ou Mock pour les tests.
  final EventRepository? repository;

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters(EventListViewModel vm) {
    _search.clear();
    vm.clearFilters();
    FocusScope.of(context).unfocus();
  }

  Future<void> _openDetails(EventListViewModel vm, PetEvent event) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailsScreen(
          event: event,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) return;
    vm.refresh();
  }

  Future<void> _openCreate(EventListViewModel vm) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(repository: widget.repository),
      ),
    );
    if (!mounted || created != true) return;
    vm.refresh();
    _toast('Votre événement a été enregistré.');
  }

  Future<void> _openCreateProposal(EventListViewModel vm) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          isProposal: true,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted || created != true) return;
    _toast('Votre proposition a été soumise avec succès.');
  }

  Future<void> _openProposals() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProposalsScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _openMyProposals() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyProposalsScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _openMyEvents(EventListViewModel vm) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyEventsScreen(repository: widget.repository),
      ),
    );
    if (!mounted) return;
    vm.refresh();
  }

  void _openMyReservations() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyEventReservationsScreen(repository: widget.repository),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<EventListViewModel>(
        key: ValueKey('${session.currentUserId}-${widget.forceEmpty}'),
        create: (context) => EventListViewModel(
          widget.repository ?? ApiEventRepository.shared,
          forceEmpty: widget.forceEmpty,
        ),
        builder: (context, vm) => _content(context, vm),
      ),
    );
  }

  Widget _content(BuildContext context, EventListViewModel vm) {
    final results = vm.results;
    final session = DemoSessionProvider.instance;

    final actions = <Widget>[
      const EventDemoUserSelector(),
    ];

    if (session.isAdmin) {
      actions.addAll([
        IconButton(
          tooltip: 'Nouvel événement',
          onPressed: () => _openCreate(vm),
          icon: const Icon(PhosphorIconsRegular.plus, size: 22),
        ),
        IconButton(
          tooltip: 'Propositions',
          onPressed: _openProposals,
          icon: const Icon(PhosphorIconsRegular.listBullets, size: 22),
        ),
        IconButton(
          tooltip: 'Mes événements',
          onPressed: () => _openMyEvents(vm),
          icon: const Icon(PhosphorIconsRegular.notepad, size: 22),
        ),
        IconButton(
          tooltip: 'Mes réservations',
          onPressed: _openMyReservations,
          icon: const Icon(PhosphorIconsRegular.calendarCheck, size: 22),
        ),
      ]);
    } else if (session.isPetsitter) {
      actions.addAll([
        IconButton(
          tooltip: 'Proposer un événement',
          onPressed: () => _openCreateProposal(vm),
          icon: const Icon(PhosphorIconsRegular.plus, size: 22),
        ),
        IconButton(
          tooltip: 'Mes propositions',
          onPressed: _openMyProposals,
          icon: const Icon(PhosphorIconsRegular.listBullets, size: 22),
        ),
        IconButton(
          tooltip: 'Mes réservations',
          onPressed: _openMyReservations,
          icon: const Icon(PhosphorIconsRegular.calendarCheck, size: 22),
        ),
      ]);
    } else {
      // Owner Amira: no create, propose or edit buttons!
      actions.addAll([
        IconButton(
          tooltip: 'Mes réservations',
          onPressed: _openMyReservations,
          icon: const Icon(PhosphorIconsRegular.calendarCheck, size: 22),
        ),
      ]);
    }
    actions.add(const SizedBox(width: 4));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: actions,
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Autour de vous',
                            style: LPText.h1.copyWith(fontSize: 31),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rencontres, ateliers et sorties entre voisins et animaux.',
                            style: LPText.bodyS.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const FictifBadge(),
                  ],
                ),
              ).from(y: -14, duration: 0.5),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: TextField(
                  controller: _search,
                  onChanged: vm.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Titre, lieu, catégorie…',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: 20,
                    ),
                    fillColor: LP.soft,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(99),
                      borderSide: const BorderSide(color: LP.primary, width: 1.6),
                    ),
                  ),
                ),
              ).from(y: 16, delay: 0.06),
              const SizedBox(height: 16),
              EventCategoryChips(
                selected: vm.category,
                onChanged: vm.setCategory,
              ).from(x: 40, delay: 0.1),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    children: [
                      InfoNote(
                        vm.error!,
                        icon: PhosphorIconsRegular.warningCircle,
                        tone: InfoTone.error,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => vm.load(refresh: true),
                        icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise, size: 16),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        results.isEmpty
                            ? 'Aucun événement'
                            : '${results.length} événement${results.length > 1 ? 's' : ''}',
                        style: LPText.title,
                      ),
                    ),
                    Text(
                      'Événements fictifs',
                      style: LPText.bodyS.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (vm.loading && results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (results.isEmpty)
                EventEmptyState(
                  title: 'Aucun événement trouvé',
                  message:
                      'Essayez une autre catégorie ou modifiez votre recherche.',
                  actionLabel: 'Réinitialiser les filtres',
                  actionIcon: PhosphorIconsRegular.arrowCounterClockwise,
                  onAction: () => _clearFilters(vm),
                )
              else
                for (var i = 0; i < results.length; i++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, i == 0 ? 0 : 12, 20, 0),
                    child: EventCard(
                      event: results[i],
                      onOpen: () => _openDetails(vm, results[i]),
                    ),
                  ).from(
                    key: ValueKey('${results[i].id}-${vm.query}-${vm.category}'),
                    y: 24,
                    delay: stagger(i, start: 0.12, each: 0.07),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— FICHE D'UN ÉVÉNEMENT

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({
    super.key,
    required this.event,
    this.repository,
  });

  final PetEvent event;
  final EventRepository? repository;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final vm = EventDetailsViewModel(
    widget.repository ?? ApiEventRepository.shared,
    widget.event.id,
    initial: widget.event,
  );

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _reserve(PetEvent event) async {
    final reserved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventReservationScreen(
          event: event,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted || reserved != true) return;
    vm.refresh();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Votre réservation pour ${event.title} est confirmée.'),
        ),
      );
  }

  Future<void> _edit(PetEvent event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(
          event: event,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted || updated != true) return;
    vm.refresh();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Événement mis à jour.')));
  }

  void _openParticipants(PetEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventParticipantsScreen(
          eventId: event.id,
          eventTitle: event.title,
          repository: widget.repository,
        ),
      ),
    );
  }

  Future<void> _confirmCancel(PetEvent event) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => _CancelEventSheet(event: event),
    );
    if (ok != true) return;
    try {
      await vm.cancelEvent();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${event.title} est annulé.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  Future<void> _confirmDelete(PetEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Voulez-vous vraiment supprimer définitivement « ${event.title} » ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LP.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.deleteEvent();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Événement supprimé.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = vm.event ?? widget.event;
    final canReserve = vm.canReserve;
    final isAdmin = DemoSessionProvider.instance.isAdmin;
    final label = canReserve
        ? 'Réserver ma place'
        : event.isFull
        ? 'Complet'
        : event.status == EventStatus.completed
        ? 'Événement terminé'
        : event.status == EventStatus.cancelled
        ? 'Événement annulé'
        : 'Réservations fermées';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            backgroundColor: LP.bg,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: RoundIconButton(
                PhosphorIconsRegular.arrowLeft,
                onTap: () => Navigator.maybePop(context),
                tooltip: 'Retour',
              ),
            ),
            actions: [
              if (isAdmin) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: RoundIconButton(
                    PhosphorIconsRegular.pencilSimple,
                    tooltip: 'Modifier',
                    onTap: () => _edit(event),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: RoundIconButton(
                    PhosphorIconsRegular.userCircle,
                    tooltip: 'Participants',
                    onTap: () => _openParticipants(event),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(PhosphorIconsRegular.dotsThreeVertical, color: LP.ink),
                  onSelected: (val) {
                    if (val == 'cancel') _confirmCancel(event);
                    if (val == 'delete') _confirmDelete(event);
                  },
                  itemBuilder: (_) => [
                    if (event.status != EventStatus.cancelled)
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Annuler l\'événement'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer l\'événement', style: TextStyle(color: LP.error)),
                    ),
                  ],
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: RoundIconButton(
                  PhosphorIconsRegular.shareNetwork,
                  tooltip: 'Partager',
                  onTap: () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text('Partage de ${event.title} simulé.'),
                        ),
                      );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: LPImage(
                event.imageUrl,
                radius: 0,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Pill(
                        label: event.category.label,
                        icon: event.category.icon,
                        bg: LP.mintPale,
                        fg: LP.primary,
                      ),
                      EventStatusPill(event.status),
                      const FictifBadge(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.title, style: LPText.h1.copyWith(fontSize: 33)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LP.soft,
                      borderRadius: BorderRadius.circular(LP.r20),
                    ),
                    child: Column(
                      children: [
                        EventFactRow(
                          icon: PhosphorIconsRegular.calendarBlank,
                          label: 'Quand',
                          value: event.dateLabel,
                        ),
                        const Divider(color: LP.softDeep),
                        EventFactRow(
                          icon: PhosphorIconsRegular.mapPin,
                          label: 'Où',
                          value: event.location,
                        ),
                        const Divider(color: LP.softDeep),
                        EventFactRow(
                          icon: PhosphorIconsRegular.user,
                          label: 'Organisateur',
                          value: event.organizerName,
                        ),
                      ],
                    ),
                  ),
                  const EventSectionTitle(
                    'À propos',
                    PhosphorIconsRegular.notepad,
                  ),
                  Text(
                    event.description,
                    style: LPText.bodyM.copyWith(height: 1.55),
                  ),
                  const EventSectionTitle(
                    'Places',
                    PhosphorIconsRegular.userCircle,
                  ),
                  EventSeatsPanel(event: event),
                  const SizedBox(height: 22),
                  const InfoNote(
                    'La réservation est gratuite et sans engagement : elle permet à l\'organisateur de préparer l\'accueil.',
                    icon: PhosphorIconsRegular.info,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: PawButton(
          label: label,
          icon: PhosphorIconsRegular.calendarPlus,
          onPressed: canReserve ? () => _reserve(event) : null,
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— FORMULAIRE DE RÉSERVATION

class EventReservationScreen extends StatefulWidget {
  const EventReservationScreen({
    super.key,
    required this.event,
    this.repository,
  });

  final PetEvent event;
  final EventRepository? repository;

  @override
  State<EventReservationScreen> createState() => _EventReservationScreenState();
}

class _EventReservationScreenState extends State<EventReservationScreen> {
  late final vm = EventReservationViewModel(
    widget.repository ?? ApiEventRepository.shared,
  );
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _participants = TextEditingController(text: '1');
  final _comment = TextEditingController();

  @override
  void dispose() {
    vm.dispose();
    _name.dispose();
    _phone.dispose();
    _participants.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (vm.sending) return;
    if (!(_form.currentState?.validate() ?? false)) return;

    final event = widget.event;
    try {
      await vm.reserve(
        event: event,
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        participants: int.tryParse(_participants.text.trim()) ?? 1,
        comment: _comment.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Réservation'),
        ),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventMiniCard(event: event),
                const SizedBox(height: 22),
                Text('Vos informations', style: LPText.h2),
                const SizedBox(height: 6),
                Text(
                  'Elles servent uniquement à préparer votre accueil le jour de l\'événement.',
                  style: LPText.bodyS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    hintText: 'Ex. : Leïla Ben Salah',
                    prefixIcon: Icon(PhosphorIconsRegular.user, size: 20),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Indiquez votre nom complet.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex. : 22 345 678',
                    prefixIcon: Icon(PhosphorIconsRegular.phone, size: 20),
                  ),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (digits.length < 8) {
                      return 'Indiquez un numéro de téléphone valide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _participants,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Nombre de participants',
                    hintText: '1',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.userCircle,
                      size: 20,
                    ),
                    helperText:
                        'Maximum 5 places par réservation (${event.remainingSeats} disponible${event.remainingSeats > 1 ? 's' : ''})',
                  ),
                  validator: (value) {
                    final count = int.tryParse((value ?? '').trim());
                    if (count == null || count < 1) {
                      return 'Indiquez au moins 1 participant.';
                    }
                    if (count > 5) {
                      return 'Maximum 5 places par réservation.';
                    }
                    if (count > event.remainingSeats) {
                      return 'Il ne reste que ${event.remainingSeats} place${event.remainingSeats > 1 ? 's' : ''}.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _comment,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (facultatif)',
                    hintText: 'Une question, un besoin particulier…',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 58),
                      child: Icon(
                        PhosphorIconsRegular.chatCircleDots,
                        size: 20,
                      ),
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 26),
                const InfoNote(
                  'Aucun paiement n\'est demandé dans cette démonstration.',
                  icon: PhosphorIconsRegular.lockSimple,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: LoadingButton(
            label: 'Confirmer ma réservation',
            loading: vm.sending,
            onPressed: _send,
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— MES RÉSERVATIONS

class MyEventReservationsScreen extends StatelessWidget {
  const MyEventReservationsScreen({
    super.key,
    this.forceEmpty = false,
    this.repository,
  });

  final bool forceEmpty;
  final EventRepository? repository;

  void _browse(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const EventsListScreen()));
    }
  }

  Future<void> _handleCardTap(
    BuildContext context,
    MyEventReservationsViewModel vm,
    EventReservationItem item,
  ) async {
    if (item.reservation.status == ReservationStatus.cancelled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(
            event: item.event,
            repository: repository,
          ),
        ),
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(PhosphorIconsRegular.info, color: LP.primary),
                title: const Text('Voir l\'événement'),
                onTap: () => Navigator.pop(ctx, 'details'),
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.xCircle, color: LP.error),
                title: const Text('Annuler la réservation', style: TextStyle(color: LP.error)),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'details') {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(
            event: item.event,
            repository: repository,
          ),
        ),
      );
    } else if (action == 'cancel') {
      if (!context.mounted) return;
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        builder: (_) => _CancelReservationSheet(item: item),
      );
      if (confirm == true) {
        await vm.cancel(item.reservation.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Réservation annulée.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<MyEventReservationsViewModel>(
        key: ValueKey('${session.currentUserId}-$forceEmpty'),
        create: (context) => MyEventReservationsViewModel(
          repository: repository ?? ApiEventRepository.shared,
          forceEmpty: forceEmpty,
        ),
        builder: (context, vm) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Mes réservations'),
            actions: const [
              EventDemoUserSelector(),
              SizedBox(width: 8),
            ],
          ),
        body: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: vm.loading && vm.items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(top: 28, bottom: 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        EventEmptyState(
                          title: 'Aucune réservation',
                          message:
                              'Lorsque vous réserverez une place à un événement, elle apparaîtra ici.',
                          actionLabel: 'Découvrir les événements',
                          onAction: () => _browse(context),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${vm.items.length} réservation${vm.items.length > 1 ? 's' : ''}',
                                  style: LPText.title,
                                ),
                              ),
                              const FictifBadge(),
                            ],
                          ),
                        ),
                        for (var i = 0; i < vm.items.length; i++)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: EventReservationCard(
                              item: vm.items[i],
                              onOpen: () => _handleCardTap(context, vm, vm.items[i]),
                            ),
                          ).from(
                            key: ValueKey(vm.items[i].reservation.id),
                            y: 24,
                            delay: stagger(i, start: 0.1, each: 0.08),
                          ),
                      ],
                    ),
        ),
      ),
    ),
  );
}
}

class _CancelReservationSheet extends StatelessWidget {
  const _CancelReservationSheet({required this.item});
  final EventReservationItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Annuler la réservation', style: LPText.h2),
          const SizedBox(height: 6),
          Text(
            'Voulez-vous annuler votre réservation de ${item.reservation.participants} place(s) pour « ${item.event.title} » ? Les places seront remises à disposition.',
            style: LPText.bodyS,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: LP.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer l\'annulation'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Garder ma réservation'),
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— MES ÉVÉNEMENTS

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({
    super.key,
    this.forceEmpty = false,
    this.repository,
  });

  final bool forceEmpty;
  final EventRepository? repository;

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<MyEventsViewModel>(
        key: ValueKey('${session.currentUserId}-$forceEmpty'),
        create: (context) => MyEventsViewModel(
          repository: repository ?? ApiEventRepository.shared,
          forceEmpty: forceEmpty,
        ),
        builder: (context, vm) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Mes événements'),
            actions: [
              const EventDemoUserSelector(),
              IconButton(
                tooltip: 'Créer un événement',
                onPressed: () => _openCreate(context, vm),
                icon: const Icon(PhosphorIconsRegular.plus, size: 22),
              ),
              const SizedBox(width: 4),
            ],
          ),
        body: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: vm.loading && vm.events.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.events.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(top: 28, bottom: 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        EventEmptyState(
                          title: 'Aucun événement créé',
                          message:
                              'Créez une rencontre ou un atelier : vous pourrez le publier quand tout sera prêt.',
                          actionLabel: 'Créer un événement',
                          actionIcon: PhosphorIconsRegular.plus,
                          onAction: () => _openCreate(context, vm),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${vm.events.length} événement${vm.events.length > 1 ? 's' : ''}',
                                  style: LPText.title,
                                ),
                              ),
                              const FictifBadge(),
                            ],
                          ),
                        ),
                        for (var i = 0; i < vm.events.length; i++)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _myCard(context, vm, vm.events[i]),
                          ).from(
                            key: ValueKey(vm.events[i].id),
                            y: 24,
                            delay: stagger(i, start: 0.1, each: 0.08),
                          ),
                      ],
                    ),
        ),
      ),
    ),
  );
}

  Widget _myCard(BuildContext context, MyEventsViewModel vm, PetEvent event) {
    final cancelled =
        event.status == EventStatus.cancelled ||
        event.status == EventStatus.completed;
    return MyEventCard(
      event: event,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventDetailsScreen(
            event: event,
            repository: repository,
          ),
        ),
      ),
      onEdit: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => CreateEventScreen(
              event: event,
              repository: repository,
            ),
          ),
        );
        if (saved == true) vm.refresh();
      },
      onCancel: cancelled ? null : () => _cancel(context, vm, event),
    );
  }

  Future<void> _cancel(
    BuildContext context,
    MyEventsViewModel vm,
    PetEvent event,
  ) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => _CancelEventSheet(event: event),
    );
    if (ok != true) return;
    await vm.cancel(event.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${event.title} est annulé.')));
  }

  Future<void> _openCreate(BuildContext context, MyEventsViewModel vm) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateEventScreen(repository: repository),
      ),
    );
    if (created == true) vm.refresh();
  }
}

class _CancelEventSheet extends StatelessWidget {
  const _CancelEventSheet({required this.event});
  final PetEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Annuler l\'événement', style: LPText.h2),
          const SizedBox(height: 6),
          Text(
            '« ${event.title} » ne sera plus visible dans la liste et les réservations déjà confirmées resteront dans l\'historique.',
            style: LPText.bodyS,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: LP.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer l\'annulation'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Garder l\'événement'),
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— CRÉATION / MODIFICATION

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({
    super.key,
    this.event,
    this.isProposal = false,
    this.repository,
  });

  /// Événement existant : l'écran passe en modification.
  final PetEvent? event;

  /// Si vrai, le formulaire sert de proposition pour un pet sitter.
  final bool isProposal;

  final EventRepository? repository;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final vm = CreateEventViewModel(
    widget.repository ?? ApiEventRepository.shared,
  );
  late final proposalVm = ProposalFormViewModel(
    widget.repository ?? ApiEventRepository.shared,
  );
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.event?.title ?? '');
  late final _description = TextEditingController(
    text: widget.event?.description ?? '',
  );
  late final _location = TextEditingController(
    text: widget.event?.location ?? '',
  );
  late final _max = TextEditingController(
    text: '${widget.event?.maxParticipants ?? 20}',
  );

  late EventCategory _category =
      widget.event?.category ?? EventCategory.adoption;
  late DateTime _start = widget.event?.startDate ?? DateTime(2026, 11, 7, 10);
  late DateTime _end = widget.event?.endDate ?? DateTime(2026, 11, 7, 17);
  late String _image = widget.event?.imageUrl ?? EventMock.images.first;

  bool get _isEditing => widget.event != null;

  bool get _aiReady =>
      _title.text.trim().length >= 6 || _description.text.trim().length >= 20;

  bool get _datesValid => !_end.isBefore(_start);

  bool _aiLoading = false;
  EventAiSuggestion? _aiSuggestion;

  EventAiSuggestion get _suggestion =>
      _aiSuggestion ??
      EventAiAssistant.suggest(
        title: _title.text,
        description: _description.text,
        category: _category,
        location: _location.text,
      );

  Future<void> _fetchAndShowAiSuggestions({bool forceRefresh = false}) async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner un titre pour obtenir des suggestions IA.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_aiSuggestion != null && !forceRefresh) {
      _showAiBottomSheet(_aiSuggestion!);
      return;
    }

    setState(() => _aiLoading = true);

    try {
      final repo = widget.repository ?? ApiEventRepository.shared;
      final suggestion = await repo.getAiSuggestion(
        title: title,
        category: _category.label,
        location: _location.text.trim().isNotEmpty ? _location.text.trim() : null,
        description: _description.text.trim().isNotEmpty ? _description.text.trim() : null,
      );

      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiSuggestion = suggestion;
      });

      _showAiBottomSheet(suggestion);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Impossible de récupérer les suggestions IA : ${eventErrorMessage(e)}',
          ),
          backgroundColor: LP.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAiBottomSheet(EventAiSuggestion suggestion) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: EventAiSuggestionSheet(
            suggestion: suggestion,
            onApplyTitle: (newTitle) {
              setState(() {
                _title.text = newTitle;
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Titre appliqué');
            },
            onApplyDescription: (newDesc) {
              setState(() {
                _description.text = newDesc;
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Description appliquée');
            },
            onApplySummary: (newSummary) {
              setState(() {
                if (_description.text.trim().isEmpty) {
                  _description.text = newSummary;
                } else {
                  _description.text = '$newSummary\n\n${_description.text}'.trim();
                }
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Résumé ajouté à la description');
            },
            onApplyTags: (tags) {
              setState(() {
                final tagsFormatted = tags.map((t) => t.startsWith('#') ? t : '#$t').join(' ');
                if (_description.text.trim().isEmpty) {
                  _description.text = tagsFormatted;
                } else {
                  _description.text = '${_description.text}\n\n$tagsFormatted'.trim();
                }
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Tags ajoutés à la description');
            },
            onApplyChecklist: (checklist) {
              setState(() {
                final listFormatted = 'Matériel à prévoir :\n${checklist.map((c) => '• $c').join('\n')}';
                if (_description.text.trim().isEmpty) {
                  _description.text = listFormatted;
                } else {
                  _description.text = '${_description.text}\n\n$listFormatted'.trim();
                }
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Matériel ajouté à la description');
            },
            onApplyTip: (tip) {
              setState(() {
                if (_description.text.trim().isEmpty) {
                  _description.text = 'Conseil d\'organisation : $tip';
                } else {
                  _description.text = '${_description.text}\n\nConseil : $tip'.trim();
                }
              });
              Navigator.of(ctx).pop();
              _notifyApplied('Conseil ajouté à la description');
            },
            onApplyCategory: (catName) {
              for (final c in EventCategory.values) {
                if (c.label.toLowerCase() == catName.toLowerCase()) {
                  setState(() {
                    _category = c;
                  });
                  Navigator.of(ctx).pop();
                  _notifyApplied('Catégorie mise à jour : ${c.label}');
                  break;
                }
              }

            },
          ),
        );
      },
    );
  }

  void _notifyApplied(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    proposalVm.dispose();
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = start ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
      helpText: start ? 'Date de début' : 'Date de fin',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _start.hour,
          _start.minute,
        );
        if (_end.isBefore(_start)) {
          _end = DateTime(picked.year, picked.month, picked.day, 18);
        }
      } else {
        _end = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _end.hour,
          _end.minute,
        );
      }
    });
  }

  Future<void> _submit({required bool publish}) async {
    if (vm.saving) return;

    if (publish) {
      if (!(_form.currentState?.validate() ?? false)) return;
      if (!_datesValid) {
        setState(() {});
        return;
      }
    } else if (_title.text.trim().length < 4) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Ajoutez un titre pour enregistrer le brouillon.'),
          ),
        );
      return;
    }

    final seats = int.tryParse(_max.text.trim()) ?? 20;
    final event = PetEvent(
      id: widget.event?.id ?? 'event-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      imageUrl: _image,
      organizerName: widget.event?.organizerName ?? Mock.ownerFullName,
      location: _location.text.trim(),
      startDate: _start,
      endDate: _end,
      maxParticipants: seats,
      currentParticipants: widget.event?.currentParticipants ?? 0,
      status: publish ? EventStatus.published : EventStatus.draft,
      isMine: true,
    );

    try {
      await vm.save(event, isNew: widget.event == null);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  Future<void> _submitProposal() async {
    if (proposalVm.saving) return;

    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_datesValid) {
      setState(() {});
      return;
    }

    final seats = int.tryParse(_max.text.trim()) ?? 20;
    final event = PetEvent(
      id: widget.event?.id ?? 'proposal-${DateTime.now().microsecondsSinceEpoch}',
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
      imageUrl: _image,
      organizerName: widget.event?.organizerName ?? DemoSessionProvider.instance.currentUser.firstName,
      location: _location.text.trim(),
      startDate: _start,
      endDate: _end,
      maxParticipants: seats,
      currentParticipants: widget.event?.currentParticipants ?? 0,
      status: EventStatus.pending,
      isMine: true,
    );

    try {
      await proposalVm.submit(event, isNew: widget.event == null);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([vm, proposalVm]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            widget.isProposal
                ? (_isEditing ? 'Modifier la proposition' : 'Proposer un événement')
                : (_isEditing ? 'Modifier l\'événement' : 'Nouvel événement'),
          ),
        ),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isProposal && widget.event?.rejectionReason != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LP.errorSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: LP.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          PhosphorIconsRegular.warningCircle,
                          color: LP.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Motif du refus précédent :',
                                style: LPText.label.copyWith(color: LP.error),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.event!.rejectionReason!,
                                style: LPText.bodyS.copyWith(color: LP.ink),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'En modifiant et soumettant à nouveau, votre proposition sera renvoyée à l\'administrateur en attente de validation.',
                                style: LPText.bodyS.copyWith(fontSize: 12, color: LP.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.isProposal
                      ? (_isEditing ? 'Ajustez votre proposition' : 'Proposez un nouvel événement')
                      : (_isEditing ? 'Ajustez votre événement' : 'Créons votre événement'),
                  style: LPText.h2,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isProposal
                      ? 'Votre proposition sera examinée par un administrateur avant d\'être publiée.'
                      : 'Vous pourrez l\'enregistrer en brouillon puis le publier quand tout sera prêt.',
                  style: LPText.bodyS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {
                    _aiSuggestion = null;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    hintText: 'Ex. : Adoption Day à La Marsa',
                    prefixIcon: Icon(PhosphorIconsRegular.notepad, size: 20),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 4) {
                      return 'Donnez un titre à votre événement.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  onChanged: (_) => setState(() {
                    _aiSuggestion = null;
                  }),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Déroulé, public visé, matériel à prévoir, consignes pour les animaux…',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 74),
                      child: Icon(PhosphorIconsRegular.notepad, size: 20),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 20) {
                      return 'Décrivez votre événement en quelques mots.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                Text('Catégorie', style: LPText.h3),
                const SizedBox(height: 10),
                EventCategoryChips(
                  selected: _category,
                  withAll: false,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _category = value!);
                  },
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  child: EventAiCard(
                    key: ValueKey(
                      'ai-${_title.text.trim().isNotEmpty ? "ready" : "disabled"}-${_aiLoading ? "loading" : "idle"}',
                    ),
                    suggestion: _suggestion,
                    disabled: _title.text.trim().isEmpty,
                    loading: _aiLoading,
                    onTap: _title.text.trim().isEmpty ? null : _fetchAndShowAiSuggestions,
                  ),
                ),
                const EventSectionTitle(
                  'Lieu et dates',
                  PhosphorIconsRegular.mapPin,
                ),
                TextFormField(
                  controller: _location,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Lieu',
                    hintText: 'Ex. : Parc du Belvédère, Tunis',
                    prefixIcon: Icon(PhosphorIconsRegular.mapPin, size: 20),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 4) {
                      return 'Indiquez le lieu de l\'événement.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Début',
                        value: frDate(_start, weekday: false),
                        onTap: () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateField(
                        label: 'Fin',
                        value: frDate(_end, weekday: false),
                        onTap: () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
                if (!_datesValid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      'La date de fin doit être postérieure à la date de début.',
                      style: LPText.bodyS.copyWith(color: LP.error),
                    ),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Participants maximum',
                    hintText: '20',
                    prefixIcon: Icon(PhosphorIconsRegular.userCircle, size: 20),
                  ),
                  validator: (value) {
                    final count = int.tryParse((value ?? '').trim());
                    if (count == null || count < 2) {
                      return 'Indiquez au moins 2 participants.';
                    }
                    if (count > 200) {
                      return 'Limitez l\'événement à 200 participants.';
                    }
                    final current = widget.event?.currentParticipants ?? 0;
                    if (count < current) {
                      return 'Déjà $current inscrits : augmentez la capacité.';
                    }
                    return null;
                  },
                ),
                const EventSectionTitle(
                  'Image de l\'événement',
                  PhosphorIconsRegular.image,
                ),
                EventImagePicker(
                  images: EventMock.images,
                  selected: _image,
                  onChanged: (url) => setState(() => _image = url),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sélection locale : aucun téléversement réel dans cette démonstration.',
                  style: LPText.bodyS.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 22),
                const InfoNote(
                  'Un brouillon reste privé. La publication rend l\'événement visible et ouvre les réservations.',
                  icon: PhosphorIconsRegular.info,
                  tone: InfoTone.apricot,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: widget.isProposal
              ? PawButton(
                  label: _isEditing ? 'Soumettre à nouveau' : 'Envoyer la proposition',
                  icon: PhosphorIconsBold.paperPlaneRight,
                  loading: proposalVm.saving,
                  onPressed: _submitProposal,
                )
              : Row(
                  children: [
                    Expanded(
                      child: PawButton(
                        label: 'Brouillon',
                        dark: false,
                        icon: PhosphorIconsRegular.notepad,
                        loading: vm.saving,
                        onPressed: () => _submit(publish: false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PawButton(
                        label: 'Publier',
                        icon: PhosphorIconsRegular.sealCheck,
                        loading: vm.saving,
                        onPressed: () => _submit(publish: true),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label : $value',
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: LP.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LP.line, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.calendarBlank,
                  size: 19,
                  color: LP.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: LPText.bodyS.copyWith(fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.label.copyWith(fontSize: 14.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— PROPOSITIONS (ADMIN)

class ProposalsScreen extends StatelessWidget {
  const ProposalsScreen({super.key, this.repository});
  final EventRepository? repository;

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<ProposalsViewModel>(
        key: ValueKey('proposals-${session.currentUserId}'),
        create: (context) => ProposalsViewModel(
          repository: repository ?? ApiEventRepository.shared,
        ),
        builder: (context, vm) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Propositions'),
            actions: const [
              EventDemoUserSelector(),
              SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.load(refresh: true),
            child: vm.loading && vm.proposals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.proposals.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(top: 28, bottom: 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (vm.error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: InfoNote(
                                vm.error!,
                                icon: PhosphorIconsRegular.warningCircle,
                                tone: InfoTone.error,
                              ),
                            ),
                          const EventEmptyState(
                            title: 'Aucune proposition',
                            message: 'Les propositions d\'événements soumises par les pet sitters apparaîtront ici pour validation.',
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (vm.error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: InfoNote(
                                vm.error!,
                                icon: PhosphorIconsRegular.warningCircle,
                                tone: InfoTone.error,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${vm.proposals.length} proposition${vm.proposals.length > 1 ? 's' : ''}',
                                    style: LPText.title,
                                  ),
                                ),
                                const FictifBadge(),
                              ],
                            ),
                          ),
                          for (var i = 0; i < vm.proposals.length; i++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _proposalCard(context, vm, vm.proposals[i]),
                            ).from(
                              key: ValueKey(vm.proposals[i].id),
                              y: 24,
                              delay: stagger(i, start: 0.1, each: 0.08),
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _proposalCard(BuildContext context, ProposalsViewModel vm, PetEvent proposal) {
    final isPending = proposal.status == EventStatus.pending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(
                label: proposal.category.label,
                icon: proposal.category.icon,
                bg: LP.mintPale,
                fg: LP.primary,
              ),
              const Spacer(),
              EventStatusPill(proposal.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(proposal.title, style: LPText.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.user, size: 15, color: LP.muted),
              const SizedBox(width: 4),
              Text('Proposé par ${proposal.organizerName}', style: LPText.bodyS),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.calendarBlank, size: 15, color: LP.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(proposal.dateLabel, style: LPText.bodyS, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, size: 15, color: LP.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(proposal.location, style: LPText.bodyS, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (proposal.status == EventStatus.rejected && proposal.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LP.errorSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.warningCircle, size: 18, color: LP.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Motif du refus : ${proposal.rejectionReason}', style: LPText.bodyS.copyWith(color: LP.error)),
                  ),
                ],
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: LP.primary,
                      foregroundColor: LP.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(PhosphorIconsRegular.checkCircle, size: 18),
                    label: const Text('Approuver'),
                    onPressed: () => _confirmApprove(context, vm, proposal),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LP.error,
                      side: const BorderSide(color: LP.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(PhosphorIconsRegular.xCircle, size: 18),
                    label: const Text('Refuser'),
                    onPressed: () => _showRejectDialog(context, vm, proposal),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Modifier avant d\'approuver',
                  icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: LP.ink),
                  onPressed: () async {
                    final saved = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CreateEventScreen(
                          event: proposal,
                          repository: repository,
                        ),
                      ),
                    );
                    if (saved == true) vm.refresh();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmApprove(BuildContext context, ProposalsViewModel vm, PetEvent proposal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approuver la proposition'),
        content: Text('Voulez-vous approuver « ${proposal.title} » ? L\'événement sera immédiatement publié et ouvert aux réservations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LP.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approuver et publier'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.approve(proposal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('« ${proposal.title} » a été approuvé et publié !')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }

  Future<void> _showRejectDialog(BuildContext context, ProposalsViewModel vm, PetEvent proposal) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la proposition'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Veuillez indiquer le motif du refus pour « ${proposal.title} » :', style: LPText.bodyS),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ex. : Le lieu proposé n\'est pas accessible aux animaux...',
                  labelText: 'Motif du refus',
                ),
                validator: (val) {
                  if ((val ?? '').trim().isEmpty) {
                    return 'Le motif de refus est obligatoire.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LP.error),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await vm.reject(proposal.id, reasonController.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Proposition « ${proposal.title} » refusée.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }
}

// ————————————————————————————————————————————— MES PROPOSITIONS (PETSITTER)

class MyProposalsScreen extends StatelessWidget {
  const MyProposalsScreen({super.key, this.repository});
  final EventRepository? repository;

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<MyProposalsViewModel>(
        key: ValueKey('my-proposals-${session.currentUserId}'),
        create: (context) => MyProposalsViewModel(
          repository: repository ?? ApiEventRepository.shared,
        ),
        builder: (context, vm) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('Mes propositions'),
            actions: [
              const EventDemoUserSelector(),
              IconButton(
                tooltip: 'Proposer un événement',
                icon: const Icon(PhosphorIconsRegular.plus, size: 22),
                onPressed: () async {
                  final created = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CreateEventScreen(
                        isProposal: true,
                        repository: repository,
                      ),
                    ),
                  );
                  if (created == true) vm.refresh();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => vm.load(refresh: true),
            child: vm.loading && vm.proposals.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : vm.proposals.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.only(top: 28, bottom: 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (vm.error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: InfoNote(
                                vm.error!,
                                icon: PhosphorIconsRegular.warningCircle,
                                tone: InfoTone.error,
                              ),
                            ),
                          EventEmptyState(
                            title: 'Aucune proposition',
                            message: 'Vous n\'avez pas encore proposé d\'événement. Partagez vos idées de balades ou ateliers avec la communauté !',
                            actionLabel: 'Proposer un événement',
                            actionIcon: PhosphorIconsRegular.plus,
                            onAction: () async {
                              final created = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CreateEventScreen(
                                    isProposal: true,
                                    repository: repository,
                                  ),
                                ),
                              );
                              if (created == true) vm.refresh();
                            },
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          if (vm.error != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: InfoNote(
                                vm.error!,
                                icon: PhosphorIconsRegular.warningCircle,
                                tone: InfoTone.error,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${vm.proposals.length} proposition${vm.proposals.length > 1 ? 's' : ''}',
                                    style: LPText.title,
                                  ),
                                ),
                                const FictifBadge(),
                              ],
                            ),
                          ),
                          for (var i = 0; i < vm.proposals.length; i++)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: _myProposalCard(context, vm, vm.proposals[i]),
                            ).from(
                              key: ValueKey(vm.proposals[i].id),
                              y: 24,
                              delay: stagger(i, start: 0.1, each: 0.08),
                            ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }

  Widget _myProposalCard(BuildContext context, MyProposalsViewModel vm, PetEvent proposal) {
    final canEdit = proposal.status == EventStatus.pending || proposal.status == EventStatus.rejected;
    final isRejected = proposal.status == EventStatus.rejected;
    final isPublished = proposal.status == EventStatus.published;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(
                label: proposal.category.label,
                icon: proposal.category.icon,
                bg: LP.mintPale,
                fg: LP.primary,
              ),
              const Spacer(),
              EventStatusPill(proposal.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(proposal.title, style: LPText.title.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.calendarBlank, size: 15, color: LP.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(proposal.dateLabel, style: LPText.bodyS, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.mapPin, size: 15, color: LP.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(proposal.location, style: LPText.bodyS, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (isRejected && proposal.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LP.errorSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LP.error.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.warningCircle, size: 18, color: LP.error),
                      const SizedBox(width: 6),
                      Text('Motif du refus :', style: LPText.label.copyWith(color: LP.error)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(proposal.rejectionReason!, style: LPText.bodyS.copyWith(color: LP.ink)),
                  const SizedBox(height: 4),
                  Text(
                    'Vous pouvez modifier cette proposition pour la soumettre à nouveau.',
                    style: LPText.bodyS.copyWith(fontSize: 12, color: LP.muted),
                  ),
                ],
              ),
            ),
          ],
          if (isPublished) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: LP.mintPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.checkCircle, size: 16, color: LP.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Événement approuvé et publié ! Seul un administrateur peut désormais le modifier.',
                      style: LPText.bodyS.copyWith(fontSize: 12, color: LP.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: LP.primary,
                      foregroundColor: LP.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 17),
                    label: Text(isRejected ? 'Corriger & Renvoyer' : 'Modifier'),
                    onPressed: () async {
                      final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => CreateEventScreen(
                            event: proposal,
                            isProposal: true,
                            repository: repository,
                          ),
                        ),
                      );
                      if (updated == true) vm.refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LP.error,
                      side: const BorderSide(color: LP.error),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(PhosphorIconsRegular.trash, size: 17),
                    label: const Text('Retirer'),
                    onPressed: () => _confirmWithdraw(context, vm, proposal),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmWithdraw(BuildContext context, MyProposalsViewModel vm, PetEvent proposal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer la proposition'),
        content: Text('Voulez-vous retirer définitivement la proposition « ${proposal.title} » ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: LP.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.withdraw(proposal.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Proposition « ${proposal.title} » retirée.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(eventErrorMessage(e))));
    }
  }
}

// ————————————————————————————————————————————— PARTICIPANTS D'UN ÉVÉNEMENT (ADMIN)

class EventParticipantsScreen extends StatelessWidget {
  const EventParticipantsScreen({
    super.key,
    required this.eventId,
    required this.eventTitle,
    this.repository,
  });

  final String eventId;
  final String eventTitle;
  final EventRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EventParticipantsViewModel>(
      create: (context) => EventParticipantsViewModel(
        eventId,
        repository ?? ApiEventRepository.shared,
      ),
      builder: (context, vm) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text('Participants · $eventTitle'),
          actions: const [
            EventDemoUserSelector(),
            SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => vm.load(),
          child: vm.loading && vm.reservations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : vm.reservations.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.only(top: 28, bottom: 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        const EventEmptyState(
                          title: 'Aucune réservation',
                          message: 'Aucun participant n\'a encore réservé de place pour cet événement.',
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (vm.error != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            child: InfoNote(
                              vm.error!,
                              icon: PhosphorIconsRegular.warningCircle,
                              tone: InfoTone.error,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${vm.totalPlaces} place${vm.totalPlaces > 1 ? 's' : ''} réservée${vm.totalPlaces > 1 ? 's' : ''} (${vm.reservations.length} réservation${vm.reservations.length > 1 ? 's' : ''})',
                                  style: LPText.title,
                                ),
                              ),
                              const FictifBadge(),
                            ],
                          ),
                        ),
                        for (var i = 0; i < vm.reservations.length; i++)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: _participantCard(context, vm, vm.reservations[i]),
                          ).from(
                            key: ValueKey(vm.reservations[i].id),
                            y: 24,
                            delay: stagger(i, start: 0.1, each: 0.08),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _participantCard(BuildContext context, EventParticipantsViewModel vm, EventReservation res) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                res.participantName,
                style: LPText.title.copyWith(fontSize: 17),
              ),
              const Spacer(),
              EventReservationStatusPill(res.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.phone, size: 15, color: LP.muted),
              const SizedBox(width: 6),
              Text(res.phone.isNotEmpty ? res.phone : 'Non renseigné', style: LPText.bodyS),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.userCircle, size: 15, color: LP.muted),
              const SizedBox(width: 6),
              Text('${res.participants} place${res.participants > 1 ? 's' : ''}', style: LPText.bodyS),
            ],
          ),
          if (res.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LP.soft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.chatCircleDots, size: 16, color: LP.muted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(res.comment, style: LPText.bodyS.copyWith(fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

