/// Écrans Flutter du module Adoption.
///
/// Les écrans ne font aucun appel HTTP : ils passent par les ViewModels,
/// eux-mêmes branchés sur [ApiAdoptionRepository].
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/models/species.dart';

import 'adoption_models.dart';
import 'adoption_repository.dart';
import 'adoption_view_models.dart';
import 'api/api_client.dart';
import 'adoption_widgets.dart';
import 'api/demo_session.dart';

// ————————————————————————————————————————————— LISTE DES ANNONCES

class AdoptionListScreen extends StatefulWidget {
  const AdoptionListScreen({
    super.key,
    this.forceEmpty = false,
    this.repository,
  });

  /// Aperçu de l'état vide (pour les captures ou une route de démonstration).
  final bool forceEmpty;

  /// Dépôt injectable pour les tests ; l'API est utilisée par défaut.
  final AdoptionRepository? repository;

  @override
  State<AdoptionListScreen> createState() => _AdoptionListScreenState();
}

class _AdoptionListScreenState extends State<AdoptionListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters(AdoptionListViewModel vm) {
    _search.clear();
    vm.clearFilters();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ViewModelBuilder<AdoptionListViewModel>(
        key: ValueKey(session.currentUserId),
        create: (context) => AdoptionListViewModel(
          widget.repository ?? ApiAdoptionRepository.shared,
          forceEmpty: widget.forceEmpty,
        ),
        builder: (context, vm) => _content(context, vm),
      ),
    );
  }

  Widget _content(BuildContext context, AdoptionListViewModel vm) {
    final results = vm.results;
    final session = DemoSessionProvider.instance;
    final hasData = results.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adoption'),
        actions: [
          IconButton(
            tooltip: 'Mes demandes',
            onPressed: () => _openMyRequests(context),
            icon: const Icon(PhosphorIconsRegular.notepad, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => vm.load(refresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
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
                            'Ils cherchent une famille',
                            style: LPText.h1.copyWith(fontSize: 31),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Rencontrez les animaux disponibles près de chez vous.',
                            style: LPText.bodyS.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ).from(y: -14, duration: 0.5),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mode démo : changez d\'utilisateur pour tester chaque rôle.',
                        style: LPText.bodyS.copyWith(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const AdoptionDemoUserSelector(),
                  ],
                ),
              ).from(y: 10, delay: 0.04),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (session.isAdmin)
                      _ActionPill(
                        label: 'Modération',
                        icon: PhosphorIconsRegular.shieldCheck,
                        onTap: () => _openAdmin(context),
                      )
                    else ...[
                      _ActionPill(
                        label: 'Publier',
                        icon: PhosphorIconsRegular.plus,
                        onTap: () => _openCreate(context),
                      ),
                      _ActionPill(
                        label: 'Mes annonces',
                        icon: PhosphorIconsRegular.notepad,
                        onTap: () => _openMyListings(context),
                      ),
                      _ActionPill(
                        label: 'Mes demandes',
                        icon: PhosphorIconsRegular.handHeart,
                        onTap: () => _openMyRequests(context),
                      ),
                      _ActionPill(
                        label: 'Reçues',
                        icon: PhosphorIconsRegular.listBullets,
                        onTap: () => _openReceivedRequests(context),
                      ),
                    ],
                  ],
                ),
              ).from(y: 12, delay: 0.05),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: TextField(
                  controller: _search,
                  onChanged: vm.setQuery,
                  decoration: InputDecoration(
                    hintText: 'Nom, race, ville…',
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
                      borderSide: const BorderSide(
                        color: LP.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ).from(y: 16, delay: 0.06),
              const SizedBox(height: 16),
              SpeciesChips(
                selected: vm.species,
                onChanged: vm.setSpecies,
              ).from(x: 40, delay: 0.1),
              if (vm.error != null)
                AdoptionErrorNote(message: vm.error!, onRetry: () => vm.load()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        results.isEmpty
                            ? 'Aucun compagnon'
                            : '${results.length} animal${results.length > 1 ? 'x' : ''} à adopter',
                        style: LPText.title,
                      ),
                    ),
                    Text(
                      'Données du backend',
                      style: LPText.bodyS.copyWith(fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              if (vm.loading && !hasData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (vm.error != null && results.isEmpty)
                const SizedBox.shrink()
              else if (results.isEmpty)
                AdoptionEmptyState(
                  title: 'Aucun animal trouvé',
                  message: vm.hasFilters
                      ? 'Essayez une autre espèce ou modifiez votre recherche.'
                      : 'Aucune annonce publiée pour le moment. Revenez bientôt ou publiez la première.',
                  actionLabel: vm.hasFilters
                      ? 'Réinitialiser les filtres'
                      : 'Publier une annonce',
                  actionIcon: vm.hasFilters
                      ? PhosphorIconsRegular.arrowCounterClockwise
                      : PhosphorIconsRegular.plus,
                  onAction: () =>
                      vm.hasFilters ? _clearFilters(vm) : _openCreate(context),
                )
              else
                for (var i = 0; i < results.length; i++)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, i == 0 ? 0 : 12, 20, 0),
                    child: AdoptionPetCard(
                      pet: results[i],
                      onOpen: () => _openDetails(context, results[i]),
                    ),
                  ).from(
                    key: ValueKey('${results[i].id}-${vm.query}-${vm.species}'),
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

// ————————————————————————————————————————————— FICHE D'UNE ANNONCE

class AdoptionDetailsScreen extends StatelessWidget {
  const AdoptionDetailsScreen({
    super.key,
    this.listingId,
    this.pet,
    this.repository,
  }) : assert(listingId != null || pet != null);

  final String? listingId;
  final AdoptionPet? pet;
  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdoptionDetailsViewModel>(
      create: (context) => AdoptionDetailsViewModel(
        repository ?? ApiAdoptionRepository.shared,
        listingId ?? pet!.id,
        initial: pet,
      ),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _DetailsView(vm: vm),
      ),
    );
  }
}

class _DetailsView extends StatelessWidget {
  const _DetailsView({required this.vm});
  final AdoptionDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final pet = vm.pet;
    if (pet == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Adoption'),
        ),
        body: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(top: 24),
                children: [
                  AdoptionErrorNote(
                    message: vm.error ?? 'Annonce introuvable.',
                    onRetry: vm.load,
                  ),
                ],
              ),
      );
    }

    final session = DemoSessionProvider.instance;
    final isPublisher = pet.isMine(session.currentUserId);
    final isAdmin = session.isAdmin;
    final extra = pet.extra.entries.toList();
    final facts = [pet.breed, pet.age, pet.sex];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
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
                          content: Text(
                            'Partage de la fiche de ${pet.name} simulé.',
                          ),
                        ),
                      );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: LPImage(
                pet.photo,
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
                        label: pet.species.label,
                        icon: pet.species.icon,
                        bg: LP.mintPale,
                        fg: LP.primary,
                      ),
                      AdoptionListingStatusPill(pet.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(pet.name, style: LPText.h1.copyWith(fontSize: 36)),
                  const SizedBox(height: 6),
                  Text(
                    facts.join(' · '),
                    style: LPText.bodyL.copyWith(color: LP.muted),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.mapPin,
                        size: 17,
                        color: LP.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pet.displayLocation,
                          style: LPText.bodyM.copyWith(color: LP.muted),
                        ),
                      ),
                    ],
                  ),
                  if (pet.publisherName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Publiée par ${pet.publisherName} (${pet.publisherId})',
                      style: LPText.bodyS.copyWith(fontSize: 12.5),
                    ),
                  ],
                  if (vm.error != null) ...[
                    const SizedBox(height: 14),
                    InfoNote(
                      vm.error!,
                      icon: PhosphorIconsRegular.warningCircle,
                      tone: InfoTone.error,
                    ),
                  ],
                  if (isPublisher) ...[
                    const SizedBox(height: 16),
                    const InfoNote(
                      'Vous avez publié cette annonce : vous pouvez la gérer mais pas y répondre.',
                      icon: PhosphorIconsRegular.shieldCheck,
                      tone: InfoTone.success,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (pet.status == AdoptionListingStatus.draft ||
                            pet.status == AdoptionListingStatus.paused)
                          TextButton.icon(
                            onPressed: vm.busy
                                ? null
                                : () => _run(
                                    context,
                                    vm,
                                    vm.publish,
                                    'Annonce publiée.',
                                  ),
                            icon: const Icon(
                              PhosphorIconsRegular.play,
                              size: 17,
                            ),
                            label: const Text('Publier'),
                          ),
                        if (pet.status == AdoptionListingStatus.published)
                          TextButton.icon(
                            onPressed: vm.busy
                                ? null
                                : () => _run(
                                    context,
                                    vm,
                                    vm.pause,
                                    'Annonce mise en pause.',
                                  ),
                            icon: const Icon(
                              PhosphorIconsRegular.hourglassMedium,
                              size: 17,
                            ),
                            label: const Text('Mettre en pause'),
                          ),
                        if (pet.status != AdoptionListingStatus.archived)
                          TextButton.icon(
                            onPressed: vm.busy
                                ? null
                                : () => _run(
                                    context,
                                    vm,
                                    vm.archive,
                                    'Annonce archivée.',
                                  ),
                            icon: const Icon(
                              PhosphorIconsRegular.doorOpen,
                              size: 17,
                            ),
                            label: const Text('Archiver'),
                          ),
                        TextButton.icon(
                          onPressed: () => _openReceivedRequests(context),
                          icon: const Icon(
                            PhosphorIconsRegular.listBullets,
                            size: 17,
                          ),
                          label: const Text('Demandes reçues'),
                        ),
                      ],
                    ),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    const InfoNote(
                      'Vue administrateur : actions de modération disponibles.',
                      icon: PhosphorIconsRegular.shieldCheck,
                      tone: InfoTone.warning,
                    ),
                  ],
                  const SizedBox(height: 18),
                  const InfoNote(
                    'Cet animal est proposé par une famille ou une association. Une rencontre est organisée avant toute adoption.',
                    icon: PhosphorIconsRegular.handHeart,
                    tone: InfoTone.apricot,
                  ),
                  const AdoptionSectionTitle(
                    'Son histoire',
                    PhosphorIconsRegular.notepad,
                  ),
                  Text(
                    pet.description.isEmpty
                        ? 'Aucune description fournie.'
                        : pet.description,
                    style: LPText.bodyM.copyWith(height: 1.55),
                  ),
                  const AdoptionSectionTitle(
                    'Sa santé',
                    PhosphorIconsRegular.stethoscope,
                  ),
                  AdoptionHealthPanel(pet: pet),
                  if (extra.isNotEmpty) ...[
                    const AdoptionSectionTitle(
                      'Informations complémentaires',
                      PhosphorIconsRegular.pawPrint,
                    ),
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
                          for (var i = 0; i < extra.length; i++) ...[
                            AdoptionFactRow(
                              icon: PhosphorIconsRegular.pawPrint,
                              label: extra[i].key,
                              value: extra[i].value,
                            ),
                            if (i < extra.length - 1)
                              const Divider(color: LP.softDeep),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  const InfoNote(
                    'Une demande ne vaut pas adoption : elle permet d\'organiser une rencontre et de vérifier que le courant passe.',
                    icon: PhosphorIconsRegular.info,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomActions(context, pet, session),
    );
  }

  Widget _bottomActions(
    BuildContext context,
    AdoptionPet pet,
    DemoSessionProvider session,
  ) {
    final isPublisher = pet.isMine(session.currentUserId);

    if (isPublisher) {
      return BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openReceivedRequests(context),
                icon: const Icon(PhosphorIconsRegular.listBullets, size: 18),
                label: const Text('Reçues'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PawButton(
                label: 'Modifier',
                icon: PhosphorIconsRegular.pencilSimple,
                onPressed: vm.busy
                    ? null
                    : () => _openEditListing(context, pet, onSaved: vm.load),
              ),
            ),
          ],
        ),
      );
    }

    if (session.isAdmin) {
      return BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.busy
                    ? null
                    : () => _run(
                        context,
                        vm,
                        vm.adminArchive,
                        'Annonce archivée par modération.',
                      ),
                icon: const Icon(PhosphorIconsRegular.doorOpen, size: 18),
                label: const Text('Archiver'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PawButton(
                label: 'Masquer',
                icon: PhosphorIconsRegular.eyeSlash,
                onPressed: vm.busy
                    ? null
                    : () => _run(
                        context,
                        vm,
                        vm.adminHide,
                        'Annonce masquée par modération.',
                      ),
              ),
            ),
          ],
        ),
      );
    }

    if (pet.isPublished && session.canAdopt) {
      return BottomActionBar(
        child: PawButton(
          label: 'Faire une demande d\'adoption',
          icon: PhosphorIconsRegular.handHeart,
          onPressed: () => _openRequest(context, pet, onSent: vm.load),
        ),
      );
    }

    return BottomActionBar(
      child: InfoNote(
        pet.isPublished
            ? 'Cette annonce n\'est pas disponible pour une nouvelle demande.'
            : 'Cette annonce est ${pet.status.label.toLowerCase()} : aucune demande possible.',
        icon: PhosphorIconsRegular.info,
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    AdoptionDetailsViewModel vm,
    Future<bool> Function() action,
    String successMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? successMessage : (vm.error ?? 'Action impossible.'),
          ),
        ),
      );
  }
}

// ————————————————————————————————————————————— FORMULAIRE DE DEMANDE

class AdoptionRequestScreen extends StatefulWidget {
  const AdoptionRequestScreen({super.key, required this.pet, this.repository});
  final AdoptionPet pet;
  final AdoptionRepository? repository;

  @override
  State<AdoptionRequestScreen> createState() => _AdoptionRequestScreenState();
}

class _AdoptionRequestScreenState extends State<AdoptionRequestScreen> {
  late final vm = AdoptionRequestFormViewModel(
    widget.repository ?? ApiAdoptionRepository.shared,
  );
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: DemoSessionProvider.instance.currentUser.firstName,
  );
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _experience = TextEditingController();
  final _motivation = TextEditingController();
  final _otherPets = TextEditingController();
  HousingType _housing = HousingType.apartment;
  bool _hasGarden = false;
  bool _hasOtherPets = false;

  void _scheduleAdvice() {
    vm.scheduleAdvice(
      listingId: widget.pet.id,
      housingType: _housing,
      hasGarden: _hasGarden,
      hasOtherPets: _hasOtherPets,
      otherPetsDetails: _hasOtherPets ? _otherPets.text.trim() : null,
      experience: _experience.text.trim(),
      motivation: _motivation.text.trim(),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _experience.dispose();
    _motivation.dispose();
    _otherPets.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (vm.sending) return;
    if (!(_form.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await vm.send(
      pet: widget.pet,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      experience: _experience.text.trim(),
      motivation: _motivation.text.trim(),
      housingType: _housing,
      hasGarden: _hasGarden,
      hasOtherPets: _hasOtherPets,
      otherPetsDetails: _hasOtherPets ? _otherPets.text.trim() : null,
    );
    if (!mounted) return;

    if (!ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Envoi impossible.')),
        );
      return;
    }

    Navigator.of(context).pop(true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Votre demande pour ${widget.pet.name} a bien été envoyée.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Demande d\'adoption'),
        ),
        body: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              AdoptionPetMiniCard(pet: widget.pet),
              const SizedBox(height: 22),
              Text('Présentez votre demande', style: LPText.h2),
              const SizedBox(height: 6),
              Text(
                'Ces informations seront transmises à la famille ou à l\'association qui propose ${widget.pet.name}.',
                style: LPText.bodyS.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Text('Vos coordonnées', style: LPText.h3),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) => setState(() {}),
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
                onChanged: (_) => setState(() {}),
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
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.streetAddressLine1],
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: 'Rue, quartier, ville',
                  prefixIcon: Icon(PhosphorIconsRegular.mapPin, size: 20),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 5) {
                    return 'Indiquez votre adresse.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),
              Text('Votre logement', style: LPText.h3),
              const SizedBox(height: 10),
              ChoiceGroup(
                options: [
                  for (final housing in HousingType.values) housing.label,
                ],
                selected: {_housing.label},
                onTap: (label) {
                  setState(() => _housing = HousingTypeX.fromLabel(label));
                  _scheduleAdvice();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('J\'ai un jardin'),
                value: _hasGarden,
                onChanged: (value) {
                  setState(() => _hasGarden = value);
                  _scheduleAdvice();
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('J\'ai d\'autres animaux'),
                value: _hasOtherPets,
                onChanged: (value) {
                  setState(() => _hasOtherPets = value);
                  _scheduleAdvice();
                },
              ),
              if (_hasOtherPets) ...[
                const SizedBox(height: 4),
                TextFormField(
                  controller: _otherPets,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  onChanged: (_) => _scheduleAdvice(),
                  decoration: const InputDecoration(
                    labelText: 'Lesquels ?',
                    hintText: 'Ex. : un chat de 3 ans, deux poissons',
                  ),
                ),
              ],
              const SizedBox(height: 26),
              Text('Votre expérience', style: LPText.h3),
              const SizedBox(height: 4),
              Text(
                'Animaux déjà gardés, adoption précédente, soins connus…',
                style: LPText.bodyS.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('adoption-experience'),
                controller: _experience,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                onChanged: (_) {
                  setState(() {});
                  _scheduleAdvice();
                },
                decoration: const InputDecoration(
                  hintText: 'Parlez-nous de votre expérience avec les animaux.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 58),
                    child: Icon(PhosphorIconsRegular.pawPrint, size: 20),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 10) {
                    return 'Décrivez votre expérience avec les animaux.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 26),
              Text('Votre motivation', style: LPText.h3),
              const SizedBox(height: 4),
              Text(
                'Pourquoi souhaitez-vous adopter ${widget.pet.name} ?',
                style: LPText.bodyS.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('adoption-motivation'),
                controller: _motivation,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 5,
                onChanged: (_) {
                  setState(() {});
                  _scheduleAdvice();
                },
                decoration: const InputDecoration(
                  hintText:
                      'Expliquez ce qui vous attire chez cet animal et le quotidien que vous lui offrirez.',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 74),
                    child: Icon(PhosphorIconsRegular.handHeart, size: 20),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 20) {
                    return 'Expliquez votre motivation en quelques mots.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutCubic,
                child: AdoptionAiCard(
                  key: ValueKey(
                    vm.adviceLoading
                        ? 'ai-loading'
                        : vm.adviceUnavailable
                        ? 'ai-unavailable'
                        : (vm.advice?.score ?? 'ai-teaser'),
                  ),
                  advice: vm.advice,
                  loading: vm.adviceLoading,
                  unavailable: vm.adviceUnavailable,
                ),
              ),
              const SizedBox(height: 20),
              const InfoNote(
                'Votre demande est envoyée au backend Adoption. Elle reste en attente jusqu\'à la décision du propriétaire.',
                icon: PhosphorIconsRegular.lockSimple,
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: LoadingButton(
            label: 'Envoyer ma demande',
            loading: vm.sending,
            onPressed: _send,
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— MES DEMANDES

class MyAdoptionRequestsScreen extends StatelessWidget {
  const MyAdoptionRequestsScreen({
    super.key,
    this.forceEmpty = false,
    this.repository,
  });
  final bool forceEmpty;
  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdoptionRequestsViewModel>(
      create: (context) => AdoptionRequestsViewModel(
        repository ?? ApiAdoptionRepository.shared,
        AdoptionRequestsScope.sent,
        forceEmpty: forceEmpty,
      ),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _RequestsView(
          vm: vm,
          title: 'Mes demandes',
          emptyTitle: 'Aucune demande envoyée',
          emptyMessage:
              'Lorsque vous ferez une demande d\'adoption, elle apparaîtra ici.',
          received: false,
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— DEMANDES REÇUES

class ReceivedAdoptionRequestsScreen extends StatelessWidget {
  const ReceivedAdoptionRequestsScreen({super.key, this.repository});

  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdoptionRequestsViewModel>(
      create: (context) => AdoptionRequestsViewModel(
        repository ?? ApiAdoptionRepository.shared,
        AdoptionRequestsScope.received,
      ),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _RequestsView(
          vm: vm,
          title: 'Demandes reçues',
          emptyTitle: 'Aucune demande reçue',
          emptyMessage:
              'Les personnes intéressées par vos annonces apparaîtront ici.',
          received: true,
        ),
      ),
    );
  }
}

class _RequestsView extends StatelessWidget {
  const _RequestsView({
    required this.vm,
    required this.title,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.received,
  });

  final AdoptionRequestsViewModel vm;
  final String title;
  final String emptyTitle;
  final String emptyMessage;
  final bool received;

  @override
  Widget build(BuildContext context) {
    final requests = vm.requests;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
        actions: [
          if (!received)
            TextButton(
              onPressed: () => _openList(context),
              child: const Text('Adopter'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            if (vm.loading && requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.error != null && requests.isEmpty)
              AdoptionErrorNote(message: vm.error!, onRetry: () => vm.load())
            else if (requests.isEmpty)
              AdoptionEmptyState(
                title: emptyTitle,
                message: emptyMessage,
                actionLabel: received
                    ? 'Voir les annonces'
                    : 'Découvrir les animaux',
                onAction: () => _openList(context),
              )
            else ...[
              if (vm.error != null)
                AdoptionErrorNote(message: vm.error!, onRetry: () => vm.load()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        received
                            ? '${requests.length} demande${requests.length > 1 ? 's' : ''} reçue${requests.length > 1 ? 's' : ''}'
                            : '${requests.length} demande${requests.length > 1 ? 's' : ''} envoyée${requests.length > 1 ? 's' : ''}',
                        style: LPText.title,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < requests.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child:
                      AdoptionRequestCard(
                        request: requests[i],
                        subtitle: received
                            ? 'De ${requests[i].applicantName.isEmpty ? requests[i].fullName : requests[i].applicantName}'
                            : null,
                        onOpen: () async {
                          await _openRequestDetails(context, requests[i].id);
                          if (context.mounted) vm.load(refresh: true);
                        },
                      ).from(
                        key: ValueKey(requests[i].id),
                        y: 24,
                        delay: stagger(i, start: 0.1, each: 0.08),
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— DÉTAIL D'UNE DEMANDE

class AdoptionRequestDetailsScreen extends StatelessWidget {
  const AdoptionRequestDetailsScreen({
    super.key,
    required this.requestId,
    this.repository,
  });
  final String requestId;
  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdoptionRequestDetailsViewModel>(
      create: (context) => AdoptionRequestDetailsViewModel(
        repository ?? ApiAdoptionRepository.shared,
        requestId,
      ),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _RequestDetailsView(vm: vm),
      ),
    );
  }
}

class _RequestDetailsView extends StatelessWidget {
  const _RequestDetailsView({required this.vm});
  final AdoptionRequestDetailsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final request = vm.request;
    if (request == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: const Text('Demande d\'adoption'),
        ),
        body: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.only(top: 24),
                children: [
                  AdoptionErrorNote(
                    message: vm.error ?? 'Demande introuvable.',
                    onRetry: vm.load,
                  ),
                ],
              ),
      );
    }

    final session = DemoSessionProvider.instance;
    final isPublisher = request.isPublisher(session.currentUserId);
    final isApplicant = request.isApplicant(session.currentUserId);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Demande d\'adoption'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          AdoptionPetMiniCard(pet: request.pet),
          const SizedBox(height: 16),
          Row(
            children: [
              AdoptionStatusPill(request.status),
              const Spacer(),
              if (request.aiScore != null)
                Pill(
                  label: '${request.aiScore} % IA',
                  bg: LP.accentSoft,
                  fg: LP.accentInk,
                  icon: PhosphorIconsRegular.sparkle,
                ),
            ],
          ),
          if (vm.error != null) ...[
            const SizedBox(height: 14),
            InfoNote(
              vm.error!,
              icon: PhosphorIconsRegular.warningCircle,
              tone: InfoTone.error,
            ),
          ],
          const AdoptionSectionTitle('Demandeur', PhosphorIconsRegular.user),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: LP.soft,
              borderRadius: BorderRadius.circular(LP.r20),
            ),
            child: Column(
              children: [
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.user,
                  label: 'Nom',
                  value: request.fullName,
                ),
                const Divider(color: LP.softDeep),
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.phone,
                  label: 'Téléphone',
                  value: request.phone,
                ),
                const Divider(color: LP.softDeep),
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.mapPin,
                  label: 'Adresse',
                  value: request.address,
                ),
                if (request.applicantId.isNotEmpty) ...[
                  const Divider(color: LP.softDeep),
                  AdoptionFactRow(
                    icon: PhosphorIconsRegular.userCircle,
                    label: 'Compte',
                    value: request.applicantId,
                  ),
                ],
              ],
            ),
          ),
          const AdoptionSectionTitle(
            'Message',
            PhosphorIconsRegular.chatCircleDots,
          ),
          Text(
            request.motivation.isEmpty ? 'Aucun message.' : request.motivation,
            style: LPText.bodyM.copyWith(height: 1.55),
          ),
          const AdoptionSectionTitle(
            'Logement',
            PhosphorIconsRegular.houseLine,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: LP.soft,
              borderRadius: BorderRadius.circular(LP.r20),
            ),
            child: Column(
              children: [
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.houseLine,
                  label: 'Type',
                  value: request.housingType.label,
                ),
                const Divider(color: LP.softDeep),
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.sun,
                  label: 'Jardin',
                  value: request.hasGarden ? 'Oui' : 'Non',
                ),
                const Divider(color: LP.softDeep),
                AdoptionFactRow(
                  icon: PhosphorIconsRegular.pawPrint,
                  label: 'Autres animaux',
                  value: request.hasOtherPets ? 'Oui' : 'Non',
                ),
                if (request.otherPetsDetails != null &&
                    request.otherPetsDetails!.isNotEmpty) ...[
                  const Divider(color: LP.softDeep),
                  AdoptionFactRow(
                    icon: PhosphorIconsRegular.info,
                    label: 'Détails',
                    value: request.otherPetsDetails,
                  ),
                ],
              ],
            ),
          ),
          if (request.experience.isNotEmpty) ...[
            const AdoptionSectionTitle(
              'Expérience',
              PhosphorIconsRegular.pawPrint,
            ),
            Text(
              request.experience,
              style: LPText.bodyM.copyWith(height: 1.55),
            ),
          ],
          if (request.responseMessage != null &&
              request.responseMessage!.isNotEmpty) ...[
            const AdoptionSectionTitle(
              'Réponse du propriétaire',
              PhosphorIconsRegular.handHeart,
            ),
            InfoNote(
              request.responseMessage!,
              icon: PhosphorIconsRegular.handHeart,
              tone: request.status == AdoptionStatus.accepted
                  ? InfoTone.success
                  : InfoTone.warning,
            ),
          ],
          const SizedBox(height: 18),
          InfoNote(
            'Demande créée le ${capitalize(frDate(request.date))}'
            '${request.processedAt == null ? '' : ' · traitée le ${capitalize(frDate(request.processedAt!))}'}',
            icon: PhosphorIconsRegular.calendarBlank,
          ),
        ],
      ),
      bottomNavigationBar: _bottomActions(
        context,
        request,
        isPublisher,
        isApplicant,
      ),
    );
  }

  Widget _bottomActions(
    BuildContext context,
    AdoptionRequest request,
    bool isPublisher,
    bool isApplicant,
  ) {
    if (!request.isPending) {
      return BottomActionBar(
        child: InfoNote(
          'Cette demande est ${request.status.label.toLowerCase()}.',
          icon: PhosphorIconsRegular.info,
        ),
      );
    }

    if (isPublisher) {
      return BottomActionBar(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: vm.busy
                    ? null
                    : () => _process(context, accept: false),
                icon: const Icon(PhosphorIconsRegular.x, size: 18),
                label: const Text('Refuser'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PawButton(
                label: 'Accepter',
                icon: PhosphorIconsBold.check,
                onPressed: vm.busy
                    ? null
                    : () => _process(context, accept: true),
              ),
            ),
          ],
        ),
      );
    }

    if (isApplicant) {
      return BottomActionBar(
        child: LoadingButton(
          label: 'Annuler ma demande',
          icon: PhosphorIconsRegular.xCircle,
          loading: vm.busy,
          onPressed: () => _process(context, accept: false, cancel: true),
        ),
      );
    }

    return BottomActionBar(
      child: InfoNote(
        'Seul le propriétaire de l\'annonce peut traiter cette demande.',
        icon: PhosphorIconsRegular.lockSimple,
      ),
    );
  }

  Future<void> _process(
    BuildContext context, {
    required bool accept,
    bool cancel = false,
  }) async {
    final action = cancel ? 'annuler' : (accept ? 'accepter' : 'refuser');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer : $action cette demande ?'),
        content: Text(
          cancel
              ? 'Votre demande sera annulée et ne pourra plus être traitée.'
              : accept
              ? 'La demande sera acceptée, l\'annonce deviendra « Adopté » et les autres demandes seront refusées.'
              : 'La demande sera refusée définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              cancel ? 'Confirmer' : (accept ? 'Accepter' : 'Refuser'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = cancel
        ? await vm.cancel(message: 'Annulée par le demandeur.')
        : accept
        ? await vm.accept(message: 'Votre demande a été acceptée.')
        : await vm.reject(message: 'Votre demande a été refusée.');
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (cancel
                      ? 'Demande annulée.'
                      : accept
                      ? 'Demande acceptée, annonce adoptée.'
                      : 'Demande refusée.')
                : (vm.error ?? 'Action impossible.'),
          ),
        ),
      );
  }
}

// ————————————————————————————————————————————— MES ANNONCES

class MyAdoptionListingsScreen extends StatelessWidget {
  const MyAdoptionListingsScreen({super.key, this.repository});

  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyAdoptionListingsViewModel>(
      create: (context) => MyAdoptionListingsViewModel(
        repository ?? ApiAdoptionRepository.shared,
      ),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _MyListingsView(vm: vm),
      ),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView({required this.vm});
  final MyAdoptionListingsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final listings = vm.listings;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Mes annonces'),
        actions: [
          IconButton(
            tooltip: 'Publier une annonce',
            onPressed: () => _openCreate(context),
            icon: const Icon(PhosphorIconsRegular.plus, size: 22),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
          children: [
            if (vm.loading && listings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.error != null && listings.isEmpty)
              AdoptionErrorNote(message: vm.error!, onRetry: () => vm.load())
            else if (listings.isEmpty)
              AdoptionEmptyState(
                title: 'Aucune annonce publiée',
                message:
                    'Publiez un animal à adopter : vous pourrez ensuite gérer les demandes reçues.',
                actionLabel: 'Publier une annonce',
                actionIcon: PhosphorIconsRegular.plus,
                onAction: () => _openCreate(context),
              )
            else ...[
              if (vm.error != null)
                AdoptionErrorNote(message: vm.error!, onRetry: () => vm.load()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${listings.length} annonce${listings.length > 1 ? 's' : ''}',
                        style: LPText.title,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < listings.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child:
                      AdoptionManageCard(
                        pet: listings[i],
                        onOpen: () => _openDetails(context, listings[i]),
                        onEdit: () => _openEditListing(
                          context,
                          listings[i],
                          onSaved: () => vm.load(refresh: true),
                        ),
                        onPublish:
                            listings[i].status == AdoptionListingStatus.draft ||
                                listings[i].status ==
                                    AdoptionListingStatus.paused
                            ? () => _run(
                                context,
                                vm,
                                () => vm.publish(listings[i].id),
                                'Annonce publiée.',
                              )
                            : null,
                        onPause: listings[i].isPublished
                            ? () => _run(
                                context,
                                vm,
                                () => vm.pause(listings[i].id),
                                'Annonce mise en pause.',
                              )
                            : null,
                        onArchive:
                            listings[i].status != AdoptionListingStatus.archived
                            ? () => _run(
                                context,
                                vm,
                                () => vm.archive(listings[i].id),
                                'Annonce archivée.',
                              )
                            : null,
                      ).from(
                        key: ValueKey(listings[i].id),
                        y: 24,
                        delay: stagger(i, start: 0.1, each: 0.08),
                      ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    MyAdoptionListingsViewModel vm,
    Future<bool> Function() action,
    String success,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? success : (vm.error ?? 'Action impossible.')),
        ),
      );
  }
}

// ————————————————————————————————————————————— CRÉATION / ÉDITION

class AdoptionListingFormScreen extends StatefulWidget {
  const AdoptionListingFormScreen({super.key, this.pet, this.repository});
  final AdoptionPet? pet;
  final AdoptionRepository? repository;

  @override
  State<AdoptionListingFormScreen> createState() =>
      _AdoptionListingFormScreenState();
}

class _AdoptionListingFormScreenState extends State<AdoptionListingFormScreen> {
  late final vm = CreateListingViewModel(
    widget.repository ?? ApiAdoptionRepository.shared,
  );
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.pet?.name ?? '');
  late final _breed = TextEditingController(
    text: widget.pet?.breed == 'Race non précisée'
        ? ''
        : widget.pet?.breed ?? '',
  );
  late final _age = TextEditingController(
    text: widget.pet?.ageYears?.toString() ?? '',
  );
  late final _location = TextEditingController(
    text: widget.pet?.displayLocation ?? '',
  );
  late final _description = TextEditingController(
    text: widget.pet?.description ?? '',
  );
  late final _health = TextEditingController(
    text: widget.pet?.health == 'Non précisé' ? '' : widget.pet?.health ?? '',
  );
  late List<String> _imageUrls = [...?widget.pet?.imageUrls];
  final List<String> _localImagePaths = [];
  bool _uploadingImage = false;

  late Species _species = widget.pet?.species ?? Species.chat;
  late PetGender _gender = widget.pet?.gender ?? PetGender.unknown;
  late bool _vaccinated = widget.pet?.vaccinated ?? false;
  late bool _sterilized = widget.pet?.sterilized ?? false;

  bool get _editing => widget.pet != null;

  @override
  void dispose() {
    vm.dispose();
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _location.dispose();
    _description.dispose();
    _health.dispose();
    super.dispose();
  }

  AdoptionDraft _draft() => AdoptionDraft(
    petName: _name.text,
    species: _species,
    breed: _breed.text,
    age: _age.text.trim().isEmpty ? null : int.tryParse(_age.text.trim()),
    gender: _gender,
    description: _description.text,
    healthInformation: _health.text,
    vaccinated: _vaccinated,
    sterilized: _sterilized,
    location: _location.text,
    imageUrls: _imageUrls,
  );

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    setState(() {
      _localImagePaths.add(picked.path);
      _uploadingImage = true;
    });
    try {
      final url = await (widget.repository ?? ApiAdoptionRepository.shared)
          .uploadImage(File(picked.path), contentType: picked.mimeType);
      if (!mounted) return;
      setState(() {
        _localImagePaths.remove(picked.path);
        _imageUrls = [..._imageUrls, url];
      });
    } catch (error) {
      if (mounted) {
        setState(() => _localImagePaths.remove(picked.path));
      }
      if (!mounted) return;
      final message = error is ApiException && error.code == 'INVALID_IMAGE_TYPE'
          ? 'Format non pris en charge. Choisissez une image JPEG, PNG ou WebP.'
          : adoptionErrorMessage(error);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message)),
        );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save({bool asDraft = false}) async {
    if (vm.saving) return;
    if (!(_form.currentState?.validate() ?? false)) return;

    final messenger = ScaffoldMessenger.of(context);
    final saved = await vm.save(
      _draft(),
      listingId: widget.pet?.id,
      asDraft: asDraft,
    );
    if (!mounted) return;

    if (saved == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(vm.error ?? 'Enregistrement impossible.')),
        );
      return;
    }

    Navigator.of(context).pop(true);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _editing
                ? 'Annonce mise à jour.'
                : asDraft
                ? 'Brouillon enregistré.'
                : 'Annonce publiée.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(_editing ? 'Modifier l\'annonce' : 'Nouvelle annonce'),
        ),
        body: Form(
          key: _form,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing
                      ? 'Mettez à jour les informations de l\'animal.'
                      : 'Présentez l\'animal que vous souhaitez faire adopter.',
                  style: LPText.bodyS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (vm.error != null) ...[
                  InfoNote(
                    vm.error!,
                    icon: PhosphorIconsRegular.warningCircle,
                    tone: InfoTone.error,
                  ),
                  const SizedBox(height: 16),
                ],
                Text('L\'animal', style: LPText.h3),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'animal',
                    hintText: 'Ex. : Milo',
                    prefixIcon: Icon(PhosphorIconsRegular.pawPrint, size: 20),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 2) {
                      return 'Indiquez le nom de l\'animal.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Text('Espèce', style: LPText.label),
                const SizedBox(height: 4),
                AdoptionSpeciesPicker(
                  selected: {_species},
                  onChanged: (species) => setState(() => _species = species),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _breed,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Race (facultatif)',
                    hintText: 'Ex. : Européen, Berger allemand…',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _age,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Âge (années)',
                          hintText: 'Ex. : 2',
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) return null;
                          final age = int.tryParse(text);
                          if (age == null || age < 0) {
                            return 'Âge invalide.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _location,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ville / quartier',
                          hintText: 'Ex. : La Marsa, Tunis',
                          prefixIcon: Icon(
                            PhosphorIconsRegular.mapPin,
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 2) {
                            return 'Indiquez la localisation.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Sexe', style: LPText.label),
                const SizedBox(height: 8),
                ChoiceGroup(
                  options: [
                    for (final gender in PetGender.values) gender.label,
                  ],
                  selected: {_gender.label},
                  onTap: (label) {
                    for (final gender in PetGender.values) {
                      if (gender.label == label) {
                        setState(() => _gender = gender);
                        return;
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Son caractère, son quotidien, ce qu\'il aime…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length < 10) {
                      return 'Décrivez l\'animal en quelques mots.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _health,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Informations de santé (facultatif)',
                    hintText: 'Vaccins, soins particuliers, stérilisation…',
                    alignLabelWithHint: true,
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vacciné'),
                  value: _vaccinated,
                  onChanged: (value) => setState(() => _vaccinated = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Stérilisé'),
                  value: _sterilized,
                  onChanged: (value) => setState(() => _sterilized = value),
                ),
                const SizedBox(height: 16),
                Text('Photo', style: LPText.h3),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez une ou plusieurs photos depuis votre galerie.',
                  style: LPText.bodyS.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final path in _localImagePaths)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(LP.r16),
                        child: Image.file(
                          File(path),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                        ),
                      ),
                    for (final url in _imageUrls)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(LP.r16),
                        child: LPImage(url, width: 96, height: 96, radius: LP.r16),
                      ),
                    OutlinedButton.icon(
                      onPressed: _uploadingImage ? null : _pickImage,
                      icon: _uploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(PhosphorIconsRegular.image, size: 18),
                      label: Text(
                        _uploadingImage ? 'Envoi...' : 'Ajouter une photo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoadingButton(
                label: _editing
                    ? 'Enregistrer les modifications'
                    : 'Publier l\'annonce',
                loading: vm.saving,
                onPressed: () => _save(),
              ),
              if (!_editing) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: vm.saving ? null : () => _save(asDraft: true),
                  child: const Text('Enregistrer en brouillon'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— MODÉRATION ADMIN

class AdminAdoptionScreen extends StatelessWidget {
  const AdminAdoptionScreen({super.key, this.repository});

  final AdoptionRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminAdoptionViewModel>(
      create: (context) =>
          AdminAdoptionViewModel(repository ?? ApiAdoptionRepository.shared),
      builder: (context, vm) => ListenableBuilder(
        listenable: DemoSessionProvider.instance,
        builder: (context, _) => _AdminView(vm: vm),
      ),
    );
  }
}

class _AdminView extends StatelessWidget {
  const _AdminView({required this.vm});
  final AdminAdoptionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    final listings = vm.listings;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Modération'),
      ),
      body: !session.isAdmin
          ? const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: InfoNote(
                'Cette interface est réservée à l\'administrateur. Changez d\'utilisateur de démonstration pour tester la modération.',
                icon: PhosphorIconsRegular.lockSimple,
                tone: InfoTone.warning,
              ),
            )
          : RefreshIndicator(
              onRefresh: () => vm.load(refresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
                children: [
                  if (vm.loading && listings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (vm.error != null && listings.isEmpty)
                    AdoptionErrorNote(
                      message: vm.error!,
                      onRetry: () => vm.load(),
                    )
                  else if (listings.isEmpty)
                    const AdoptionEmptyState(
                      title: 'Aucune annonce à modérer',
                      message:
                          'Les annonces créées par les utilisateurs apparaîtront ici.',
                      actionLabel: 'Actualiser',
                      onAction: _noop,
                    )
                  else ...[
                    if (vm.error != null)
                      AdoptionErrorNote(
                        message: vm.error!,
                        onRetry: () => vm.load(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${listings.length} annonce${listings.length > 1 ? 's' : ''}',
                              style: LPText.title,
                            ),
                          ),
                          const Pill(
                            label: 'Admin',
                            bg: LP.mint,
                            fg: LP.primaryDark,
                            icon: PhosphorIconsRegular.shieldCheck,
                          ),
                        ],
                      ),
                    ),
                    for (var i = 0; i < listings.length; i++)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child:
                            AdoptionManageCard(
                              pet: listings[i],
                              adminView: true,
                              onOpen: () => _openDetails(context, listings[i]),
                              onHide:
                                  listings[i].status !=
                                          AdoptionListingStatus.hidden &&
                                      listings[i].status !=
                                          AdoptionListingStatus.archived
                                  ? () => _run(
                                      context,
                                      () => vm.hide(listings[i].id),
                                      'Annonce masquée.',
                                      () => vm.error,
                                    )
                                  : null,
                              onArchive:
                                  listings[i].status !=
                                      AdoptionListingStatus.archived
                                  ? () => _run(
                                      context,
                                      () => vm.archive(listings[i].id),
                                      'Annonce archivée.',
                                      () => vm.error,
                                    )
                                  : null,
                            ).from(
                              key: ValueKey(listings[i].id),
                              y: 24,
                              delay: stagger(i, start: 0.1, each: 0.06),
                            ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  static void _noop() {}

  Future<void> _run(
    BuildContext context,
    Future<bool> Function() action,
    String success,
    String? Function() error,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await action();
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(ok ? success : (error() ?? 'Action impossible.')),
        ),
      );
  }
}

// ————————————————————————————————————————————— PETITS COMPOSANTS

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LP.white,
      shape: StadiumBorder(
        side: const BorderSide(color: LP.softDeep, width: 1.2),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: LP.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: LPText.body(
                  size: 13.5,
                  w: FontWeight.w700,
                  color: LP.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— Navigation interne

void _openList(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdoptionListScreen()));
}

void _openDetails(BuildContext context, AdoptionPet pet) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdoptionDetailsScreen(listingId: pet.id, pet: pet),
    ),
  );
}

void _openRequest(
  BuildContext context,
  AdoptionPet pet, {
  Future<void> Function()? onSent,
}) async {
  final sent = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => AdoptionRequestScreen(pet: pet)),
  );
  if (sent == true && onSent != null) {
    await onSent();
  }
}

void _openMyRequests(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MyAdoptionRequestsScreen()));
}

void _openReceivedRequests(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ReceivedAdoptionRequestsScreen()),
  );
}

Future<void> _openRequestDetails(BuildContext context, String requestId) async {
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AdoptionRequestDetailsScreen(requestId: requestId),
    ),
  );
}

void _openMyListings(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MyAdoptionListingsScreen()));
}

void _openCreate(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdoptionListingFormScreen()));
}

void _openEditListing(
  BuildContext context,
  AdoptionPet pet, {
  Future<void> Function()? onSaved,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => AdoptionListingFormScreen(pet: pet)),
  );
  if (saved == true && onSaved != null) {
    await onSaved();
  }
}

void _openAdmin(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const AdminAdoptionScreen()));
}
