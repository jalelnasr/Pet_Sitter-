/// Écrans Flutter du module Événements.
library;

import 'package:flutter/material.dart';
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
  const EventsListScreen({super.key, this.forceEmpty = false});

  /// Aperçu de l'état vide (pour les captures ou une route de démonstration).
  final bool forceEmpty;

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
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)));
    if (!mounted) return;
    vm.refresh();
  }

  Future<void> _openCreate(EventListViewModel vm) async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateEventScreen()));
    if (!mounted || created != true) return;
    vm.refresh();
    _toast('Votre événement a été enregistré.');
  }

  Future<void> _openMyEvents(EventListViewModel vm) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyEventsScreen()));
    if (!mounted) return;
    vm.refresh();
  }

  void _openMyReservations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyEventReservationsScreen()),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<EventListViewModel>(
      create: (context) => EventListViewModel(
        MockEventRepository.shared,
        forceEmpty: widget.forceEmpty,
      ),
      builder: (context, vm) => _content(context, vm),
    );
  }

  Widget _content(BuildContext context, EventListViewModel vm) {
    final results = vm.results;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          IconButton(
            tooltip: 'Créer un événement',
            onPressed: () => _openCreate(vm),
            icon: const Icon(PhosphorIconsRegular.plus, size: 22),
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
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
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
            if (results.isEmpty)
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
    );
  }
}

// ————————————————————————————————————————————— FICHE D'UN ÉVÉNEMENT

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.event});
  final PetEvent event;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final vm = EventDetailsViewModel(
    MockEventRepository.shared,
    widget.event.id,
  );

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _reserve(PetEvent event) async {
    final reserved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EventReservationScreen(event: event)),
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

  @override
  Widget build(BuildContext context) {
    final event = vm.event ?? widget.event;
    final canReserve = vm.canReserve;
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
  const EventReservationScreen({super.key, required this.event});
  final PetEvent event;

  @override
  State<EventReservationScreen> createState() => _EventReservationScreenState();
}

class _EventReservationScreenState extends State<EventReservationScreen> {
  late final vm = EventReservationViewModel();
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
    await vm.reserve(
      event: event,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      participants: int.tryParse(_participants.text.trim()) ?? 1,
      comment: _comment.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
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
                        '${event.remainingSeats} place${event.remainingSeats > 1 ? 's' : ''} disponible${event.remainingSeats > 1 ? 's' : ''}',
                  ),
                  validator: (value) {
                    final count = int.tryParse((value ?? '').trim());
                    if (count == null || count < 1) {
                      return 'Indiquez au moins 1 participant.';
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
  const MyEventReservationsScreen({super.key, this.forceEmpty = false});
  final bool forceEmpty;

  void _browse(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.push(MaterialPageRoute(builder: (_) => const EventsListScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyEventReservationsViewModel>(
      create: (context) => MyEventReservationsViewModel(forceEmpty: forceEmpty),
      builder: (context, vm) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Mes réservations'),
        ),
        body: vm.items.isEmpty
            ? ListView(
                padding: const EdgeInsets.only(top: 28, bottom: 32),
                children: [
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
                children: [
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
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                EventDetailsScreen(event: vm.items[i].event),
                          ),
                        ),
                      ),
                    ).from(
                      key: ValueKey(vm.items[i].reservation.id),
                      y: 24,
                      delay: stagger(i, start: 0.1, each: 0.08),
                    ),
                ],
              ),
      ),
    );
  }
}

// ————————————————————————————————————————————— MES ÉVÉNEMENTS

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key, this.forceEmpty = false});
  final bool forceEmpty;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyEventsViewModel>(
      create: (context) => MyEventsViewModel(forceEmpty: forceEmpty),
      builder: (context, vm) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Mes événements'),
          actions: [
            IconButton(
              tooltip: 'Créer un événement',
              onPressed: () => _openCreate(context, vm),
              icon: const Icon(PhosphorIconsRegular.plus, size: 22),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: vm.events.isEmpty
            ? ListView(
                padding: const EdgeInsets.only(top: 28, bottom: 32),
                children: [
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
                children: [
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
    );
  }

  Widget _myCard(BuildContext context, MyEventsViewModel vm, PetEvent event) {
    final cancelled =
        event.status == EventStatus.cancelled ||
        event.status == EventStatus.completed;
    return MyEventCard(
      event: event,
      onOpen: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
      ),
      onEdit: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => CreateEventScreen(event: event)),
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
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateEventScreen()));
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
  const CreateEventScreen({super.key, this.event});

  /// Événement existant : l'écran passe en modification.
  final PetEvent? event;

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  late final vm = CreateEventViewModel();
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

  EventAiSuggestion get _suggestion => EventAiAssistant.suggest(
    title: _title.text,
    description: _description.text,
    category: _category,
  );

  @override
  void dispose() {
    vm.dispose();
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

    await vm.save(event, isNew: widget.event == null);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(
            _isEditing ? 'Modifier l\'événement' : 'Nouvel événement',
          ),
        ),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Ajustez votre événement'
                      : 'Créons votre événement',
                  style: LPText.h2,
                ),
                const SizedBox(height: 6),
                Text(
                  'Vous pourrez l\'enregistrer en brouillon puis le publier quand tout sera prêt.',
                  style: LPText.bodyS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
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
                  onChanged: (_) => setState(() {}),
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
                    setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 22),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  child: EventAiCard(
                    key: ValueKey('ai-${_aiReady ? _category : 'teaser'}'),
                    suggestion: _aiReady ? _suggestion : null,
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
          child: Row(
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
