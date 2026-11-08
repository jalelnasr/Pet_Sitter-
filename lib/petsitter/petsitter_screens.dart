import 'package:flutter/material.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
// import common
import 'package:pet_sitter/petsitter/petsitter_models.dart';
import 'package:pet_sitter/petsitter/petsitter_routes.dart';
import 'package:pet_sitter/petsitter/petsitter_session.dart';
import 'package:pet_sitter/petsitter/petsitter_view_models.dart';
import 'package:pet_sitter/petsitter/petsitter_widgets.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/views/catalog/catalog_screen.dart';
import 'package:pet_sitter/views/owner/owner_shell.dart';
import 'package:pet_sitter/petsitter/petsitter_ai.dart';

// ============================================================================
// 1. ÉCRAN LISTE DES PET SITTERS (PROPRIÉTAIRE)
// ============================================================================

class SitterListScreen extends StatelessWidget {
  const SitterListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SitterListViewModel>(
      create: (_) => SitterListViewModel(),
      builder: (context, vm) {
        return Scaffold(
          backgroundColor: LP.bg,
          appBar: AppBar(
            backgroundColor: LP.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(PhosphorIconsRegular.squaresFour, color: LP.ink),
              tooltip: 'Tous les modules (Sommaire)',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CatalogScreen()),
              ),
            ),
            title: const Text('Trouver un Pet Sitter'),
            actions: const [
              PetSitterUserSwitcher(),
              SizedBox(width: 12),
            ],
          ),
          body: Column(
            children: [
              // Barre de recherche et bouton filtre
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: LP.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: LP.soft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          onChanged: vm.setSearch,
                          decoration: const InputDecoration(
                            hintText: 'Rechercher ville, nom, mot-clé...',
                            prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20, color: LP.muted),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Badge(
                      isLabelVisible: vm.activeFiltersCount > 0,
                      label: Text('${vm.activeFiltersCount}'),
                      backgroundColor: LP.primary,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => SitterFilterSheet(
                              initialGovernorate: vm.governorate,
                              initialService: vm.service,
                              initialPetType: vm.petType,
                              initialMinPrice: vm.minPrice,
                              initialMaxPrice: vm.maxPrice,
                              initialMinRating: vm.minRating,
                              initialVerifiedOnly: vm.verifiedOnly,
                              initialSortBy: vm.sortBy,
                              onApply: vm.setFilters,
                              onReset: vm.resetFilters,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: vm.activeFiltersCount > 0 ? LP.primary : LP.soft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            PhosphorIconsRegular.slidersHorizontal,
                            color: vm.activeFiltersCount > 0 ? Colors.white : LP.ink,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Raccourcis de navigation pour tester facilement tous les rôles
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: LP.soft.withValues(alpha: 0.5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Bouton IA Matchmaking — mis en avant
                      ActionChip(
                        avatar: const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                        label: const Text(
                          'IA Matchmaking',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: LP.primary,
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(PhosphorIconsRegular.squaresFour, size: 14),
                        label: const Text('Tous les modules'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CatalogScreen()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(PhosphorIconsRegular.house, size: 14),
                        label: const Text('Accueil général'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OwnerShell()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(PhosphorIconsRegular.calendarBlank, size: 14),
                        label: const Text('Mes réservations'),
                        onPressed: () => Navigator.pushNamed(context, PetsitterRoutes.myReservations),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(PhosphorIconsRegular.userCircle, size: 14),
                        label: const Text('Espace Sitter'),
                        onPressed: () => Navigator.pushNamed(context, PetsitterRoutes.sitterDashboard),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        avatar: const Icon(PhosphorIconsRegular.shieldCheck, size: 14),
                        label: const Text('Admin Sitters'),
                        onPressed: () => Navigator.pushNamed(context, PetsitterRoutes.adminSitters),
                      ),
                    ],
                  ),
                ),
              ),

              // Contenu principal
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.errorMessage != null
                        ? ErrorStateView(message: vm.errorMessage!, onRetry: vm.load)
                        : vm.sitters.isEmpty
                            ? EmptyStateView(
                                title: 'Aucun pet sitter trouvé',
                                subtitle: 'Essayez d\'ajuster vos filtres ou de modifier votre recherche.',
                                buttonText: 'Réinitialiser les filtres',
                                onAction: vm.resetFilters,
                              )
                            : RefreshIndicator(
                                onRefresh: vm.load,
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: vm.sitters.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final sitter = vm.sitters[index];
                                    return SitterCard(
                                      sitter: sitter,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          PetsitterRoutes.sitterDetails,
                                          arguments: sitter.id,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// 2. ÉCRAN DÉTAILS D'UN PET SITTER
// ============================================================================

class SitterDetailsScreen extends StatelessWidget {
  const SitterDetailsScreen({super.key, required this.sitterId});

  final String sitterId;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SitterDetailsViewModel>(
      create: (_) => SitterDetailsViewModel(sitterId: sitterId),
      builder: (context, vm) {
        if (vm.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (vm.errorMessage != null || vm.sitter == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorStateView(
              message: vm.errorMessage ?? 'Sitter introuvable',
              onRetry: vm.load,
            ),
          );
        }

        final sitter = vm.sitter!;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Photo Header
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: sitter.resolvedPhotoUrl.isNotEmpty
                      ? Image.network(
                          sitter.resolvedPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: LP.soft),
                        )
                      : Container(color: LP.soft),
                ),
              ),

              // Contenu détaillé
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom + Vérification
                      Row(
                        children: [
                          Expanded(
                            child: Text(sitter.fullName, style: LPText.h1),
                          ),
                          if (sitter.verified) ...[
                            const SizedBox(width: 6),
                            const Icon(PhosphorIconsFill.sealCheck, size: 24, color: LP.primary),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Lieu & Étoiles
                      Row(
                        children: [
                          const Icon(PhosphorIconsRegular.mapPin, size: 16, color: LP.muted),
                          const SizedBox(width: 4),
                          Text(sitter.locationLabel, style: LPText.body(color: LP.muted)),
                          const SizedBox(width: 16),
                          const Icon(PhosphorIconsFill.star, size: 16, color: Color(0xFFFFB800)),
                          const SizedBox(width: 4),
                          Text(
                            sitter.averageRating > 0 ? sitter.averageRating.toStringAsFixed(1) : 'Nouveau',
                            style: LPText.body(w: FontWeight.w700),
                          ),
                          if (sitter.reviewsCount > 0) ...[
                            const SizedBox(width: 4),
                            Text('(${sitter.reviewsCount} avis)', style: LPText.bodyS),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: LP.line),
                      const SizedBox(height: 16),

                      // Présentation / Bio
                      Text('À propos', style: LPText.h3),
                      const SizedBox(height: 8),
                      Text(
                        sitter.bio.isNotEmpty ? sitter.bio : 'Aucune description renseignée.',
                        style: LPText.body(height: 1.5),
                      ),
                      const SizedBox(height: 20),

                      // Galerie photos additionnelle
                      if (sitter.resolvedGallery.isNotEmpty) ...[
                        Text('Galerie photos', style: LPText.h3),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: sitter.resolvedGallery.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  sitter.resolvedGallery[i],
                                  width: 120,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Services proposés
                      Text('Services & Prestations', style: LPText.h3),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in sitter.services)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: LP.soft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(s.icon, size: 16, color: LP.primary),
                                  const SizedBox(width: 6),
                                  Text(s.label, style: LPText.body(size: 13.5, w: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Animaux acceptés
                      Text('Animaux acceptés', style: LPText.h3),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in sitter.acceptedPetTypes)
                            Chip(
                              avatar: Icon(p.icon, size: 14),
                              label: Text(p.label),
                              backgroundColor: LP.soft,
                              side: BorderSide.none,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Caractéristiques d'hébergement
                      Text('Conditions d\'accueil', style: LPText.h3),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            sitter.hasGarden ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.xCircle,
                            size: 18,
                            color: sitter.hasGarden ? const Color(0xFF2E7D32) : LP.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(sitter.hasGarden ? 'Maison avec jardin clos' : 'Pas de jardin'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            sitter.hasOwnPets ? PhosphorIconsRegular.pawPrint : Icons.block,
                            size: 18,
                            color: LP.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(sitter.hasOwnPets ? 'Possède d\'autres animaux' : 'Aucun autre animal sur place'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section Avis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Avis des clients (${vm.reviews.length})', style: LPText.h3),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (vm.reviews.isEmpty)
                        Text('Aucun avis pour le moment.', style: LPText.body(color: LP.muted))
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vm.reviews.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final rev = vm.reviews[i];
                            return BigCard(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: LP.primary,
                                        child: Text(
                                          rev.ownerName.isNotEmpty ? rev.ownerName[0] : '?',
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(rev.ownerName, style: LPText.body(w: FontWeight.w700)),
                                      const Spacer(),
                                      for (int star = 1; star <= 5; star++)
                                        Icon(
                                          star <= rev.rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                                          size: 14,
                                          color: const Color(0xFFFFB800),
                                        ),
                                    ],
                                  ),
                                  if (rev.comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(rev.comment, style: LPText.bodyS.copyWith(fontSize: 13)),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: LP.white,
              border: Border(top: BorderSide(color: LP.line)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarif journalier', style: LPText.bodyS.copyWith(color: LP.muted)),
                    Text(
                      '${sitter.pricePerDay.toInt()} DT',
                      style: LPText.h2.copyWith(color: LP.primary),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        PetsitterRoutes.sitterBook,
                        arguments: sitter,
                      );
                    },
                    child: const Text('Réserver maintenant'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 3. ÉCRAN FORMULAIRE DE RÉSERVATION (PROPRIÉTAIRE)
// ============================================================================

class ReservationFormScreen extends StatefulWidget {
  const ReservationFormScreen({super.key, required this.sitter});

  final PetSitter sitter;

  @override
  State<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  final _petNameCtrl = TextEditingController(text: 'Simba');
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _petNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ReservationFormViewModel>(
      create: (_) => ReservationFormViewModel(sitter: widget.sitter),
      builder: (context, vm) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Demande de garde'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête Sitter
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: widget.sitter.resolvedPhotoUrl.isNotEmpty
                          ? NetworkImage(widget.sitter.resolvedPhotoUrl)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.sitter.fullName, style: LPText.h3),
                        Text(widget.sitter.locationLabel, style: LPText.bodyS.copyWith(color: LP.muted)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: LP.line),
                const SizedBox(height: 20),

                // 1. Choix du service
                Text('Prestation souhaitée', style: LPText.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in widget.sitter.services)
                      ChoiceChip(
                        avatar: Icon(s.icon, size: 14),
                        label: Text(s.label),
                        selected: vm.service == s,
                        onSelected: (sel) {
                          if (sel) vm.setService(s);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Dates de la garde
                Text('Période de garde', style: LPText.h3),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 180)),
                      initialDateRange: DateTimeRange(start: vm.startDate, end: vm.endDate),
                      saveText: 'Valider',
                    );
                    if (picked != null) {
                      vm.setDates(picked.start, picked.end);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: LP.soft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LP.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.calendarBlank, color: LP.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${vm.startDate.day}/${vm.startDate.month}/${vm.startDate.year} ? ${vm.endDate.day}/${vm.endDate.month}/${vm.endDate.year}',
                          style: LPText.body(w: FontWeight.w600),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: LP.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${vm.daysCount} jour(s)',
                            style: LPText.bodyS.copyWith(color: LP.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Animal concerné
                Text('Votre animal', style: LPText.h3),
                const SizedBox(height: 10),
                TextField(
                  controller: _petNameCtrl,
                  onChanged: vm.setPetName,
                  decoration: const InputDecoration(
                    labelText: 'Nom de l\'animal *',
                    hintText: 'Ex: Simba, Rocky...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Espèce :', style: LPText.body(w: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in widget.sitter.acceptedPetTypes)
                      ChoiceChip(
                        avatar: Icon(p.icon, size: 14),
                        label: Text(p.label),
                        selected: vm.petType == p,
                        onSelected: (sel) {
                          if (sel) vm.setPetType(p);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Gabarit :', style: LPText.body(w: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final sz in widget.sitter.acceptedSizes)
                      ChoiceChip(
                        label: Text(sz.label),
                        selected: vm.petSize == sz,
                        onSelected: (sel) {
                          if (sel) vm.setPetSize(sz);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Remarques / Instructions
                Text('Instructions particulières', style: LPText.h3),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesCtrl,
                  onChanged: vm.setNotes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Habitudes alimentaires, comportement, prises de médicaments...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Aperçu du prix total en direct
                BigCard(
                  padding: const EdgeInsets.all(16),
                  color: LP.soft,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Durée de la garde', style: LPText.body()),
                          Text('${vm.daysCount} jour(s)', style: LPText.body(w: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tarif journalier', style: LPText.body()),
                          Text('${widget.sitter.pricePerDay.toInt()} DT / jour', style: LPText.body(w: FontWeight.w600)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: LP.line),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total estimé', style: LPText.h3),
                          Text(
                            '${vm.calculatedTotalPrice.toInt()} DT',
                            style: LPText.h2.copyWith(color: LP.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (vm.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFD32F2F))),
                ],
                const SizedBox(height: 24),

                // Bouton de confirmation
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: vm.isSubmitting
                        ? null
                        : () async {
                            vm.setPetName(_petNameCtrl.text);
                            final res = await vm.submit();
                            if (res != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Votre demande de réservation a été envoyée avec succès !'),
                                  backgroundColor: Color(0xFF2E7D32),
                                ),
                              );
                              Navigator.pushReplacementNamed(context, PetsitterRoutes.myReservations);
                            }
                          },
                    child: vm.isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Envoyer la demande de réservation'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 4. ÉCRAN MES RÉSERVATIONS (PROPRIÉTAIRE)
// ============================================================================

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyReservationsViewModel>(
      create: (_) => MyReservationsViewModel(),
      builder: (context, vm) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Mes Réservations'),
              actions: const [
                PetSitterUserSwitcher(),
                SizedBox(width: 12),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Toutes'),
                  Tab(text: 'En attente'),
                  Tab(text: 'Confirmées'),
                  Tab(text: 'Terminées'),
                ],
              ),
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.errorMessage != null
                    ? ErrorStateView(message: vm.errorMessage!, onRetry: vm.load)
                    : TabBarView(
                        children: [
                          _buildList(context, vm, vm.reservations),
                          _buildList(context, vm, vm.pending),
                          _buildList(context, vm, vm.accepted),
                          _buildList(context, vm, vm.completed),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, MyReservationsViewModel vm, List<SitterReservation> list) {
    if (list.isEmpty) {
      return const EmptyStateView(
        title: 'Aucune réservation',
        subtitle: 'Vous n\'avez aucune réservation dans cet onglet.',
      );
    }

    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final res = list[index];
          return ReservationCard(
            reservation: res,
            onCancel: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Annuler la réservation ?'),
                  content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, annuler')),
                  ],
                ),
              );
              if (ok == true) {
                await vm.cancel(res.id);
              }
            },
            onReview: () => _openReviewDialog(context, vm, res),
          );
        },
      ),
    );
  }

  void _openReviewDialog(BuildContext context, MyReservationsViewModel vm, SitterReservation res) {
    int rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Avis pour ${res.sitterName ?? 'le sitter'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                        color: const Color(0xFFFFB800),
                        size: 28,
                      ),
                      onPressed: () => setState(() => rating = i),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Racontez comment s\'est passée la garde...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await vm.addReview(res.sitterId, res.id, rating, commentCtrl.text.trim());
              },
              child: const Text('Publier l\'avis'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 5. ÉCRAN ESPACE PET SITTER (DASHBOARD SITTER)
// ============================================================================

class SitterSpaceScreen extends StatelessWidget {
  const SitterSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SitterSpaceViewModel>(
      create: (_) => SitterSpaceViewModel(),
      builder: (context, vm) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Espace Pet Sitter'),
            actions: const [
              PetSitterUserSwitcher(),
              SizedBox(width: 12),
            ],
          ),
          body: vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : vm.errorMessage != null
                  ? ErrorStateView(message: vm.errorMessage!, onRetry: vm.load)
                  : RefreshIndicator(
                      onRefresh: vm.load,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Carte profil Sitter
                            if (vm.profile != null) ...[
                              BigCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 26,
                                          backgroundImage: vm.profile!.resolvedPhotoUrl.isNotEmpty
                                              ? NetworkImage(vm.profile!.resolvedPhotoUrl)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(vm.profile!.fullName, style: LPText.h3),
                                                  if (vm.profile!.verified) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(PhosphorIconsFill.sealCheck, size: 18, color: LP.primary),
                                                  ],
                                                ],
                                              ),
                                              Text(vm.profile!.locationLabel, style: LPText.bodyS.copyWith(color: LP.muted)),
                                            ],
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              PetsitterRoutes.sitterProfileEdit,
                                              arguments: vm.profile,
                                            ).then((_) => vm.load());
                                          },
                                          child: const Text('Modifier'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Divider(color: LP.line),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Visibilité du profil', style: LPText.body(w: FontWeight.w600)),
                                        Switch(
                                          value: vm.profile!.active,
                                          activeThumbColor: LP.primary,
                                          onChanged: (_) => vm.toggleVisibility(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              BigCard(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text('Vous n\'avez pas encore créé votre profil pet sitter.'),
                                    const SizedBox(height: 10),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, PetsitterRoutes.sitterProfileEdit)
                                            .then((_) => vm.load());
                                      },
                                      child: const Text('Créer mon profil Sitter'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),

                            // Statistiques clés
                            Row(
                              children: [
                                Expanded(
                                  child: _statCard('En attente', '${vm.pendingCount}', PhosphorIconsRegular.clock, const Color(0xFFE5A000)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard('À venir', '${vm.upcomingCount}', PhosphorIconsRegular.calendarCheck, const Color(0xFF2E7D32)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _statCard(
                                    'Note',
                                    vm.profile != null && vm.profile!.averageRating > 0
                                        ? vm.profile!.averageRating.toStringAsFixed(1)
                                        : '-',
                                    PhosphorIconsFill.star,
                                    const Color(0xFFFFB800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Réservations entrantes
                            Text('Demandes reçues (${vm.incoming.length})', style: LPText.h2),
                            const SizedBox(height: 12),
                            if (vm.incoming.isEmpty)
                              const EmptyStateView(
                                title: 'Aucune demande reçue',
                                subtitle: 'Les demandes de garde envoyées par les propriétaires apparaîtront ici.',
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: vm.incoming.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 12),
                                itemBuilder: (context, i) {
                                  final res = vm.incoming[i];
                                  return ReservationCard(
                                    reservation: res,
                                    isSitterView: true,
                                    onAccept: () => vm.accept(res.id),
                                    onReject: () => _openRejectDialog(context, vm, res),
                                    onComplete: () => vm.complete(res.id),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return BigCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: LPText.h2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: LPText.bodyS.copyWith(fontSize: 11.5, color: LP.muted)),
        ],
      ),
    );
  }

  void _openRejectDialog(BuildContext context, SitterSpaceViewModel vm, SitterReservation res) {
    final reasonCtrl = TextEditingController(text: 'Non disponible sur ces dates');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer un motif de refus pour le propriétaire :'),
            const SizedBox(height: 10),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              vm.reject(res.id, reasonCtrl.text.trim());
            },
            child: const Text('Confirmer le refus'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. ÉCRAN ÉDITION / CRÉATION PROFIL PET SITTER
// ============================================================================

class SitterProfileFormScreen extends StatefulWidget {
  const SitterProfileFormScreen({super.key, this.profile});

  final PetSitter? profile;

  @override
  State<SitterProfileFormScreen> createState() => _SitterProfileFormScreenState();
}

class _SitterProfileFormScreenState extends State<SitterProfileFormScreen> {
  late final _nameCtrl = TextEditingController(text: widget.profile?.fullName ?? 'Samira Ben Salem');
  late final _bioCtrl = TextEditingController(text: widget.profile?.bio ?? '');
  late final _cityCtrl = TextEditingController(text: widget.profile?.city ?? 'La Marsa');
  late final _phoneCtrl = TextEditingController(text: widget.profile?.phone ?? '+216 22 111 222');
  late final _priceDayCtrl = TextEditingController(text: (widget.profile?.pricePerDay ?? 35.0).toInt().toString());
  late final _priceHourCtrl = TextEditingController(text: (widget.profile?.pricePerHour ?? 12.0).toInt().toString());

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();
    _priceDayCtrl.dispose();
    _priceHourCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SitterProfileFormViewModel>(
      create: (_) => SitterProfileFormViewModel(initialProfile: widget.profile),
      builder: (context, vm) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.profile != null ? 'Modifier mon profil' : 'Créer mon profil Sitter'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo de profil
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: LP.soft,
                        backgroundImage: vm.photoUrl.isNotEmpty ? NetworkImage(vm.photoUrl) : null,
                        child: vm.photoUrl.isEmpty
                            ? const Icon(PhosphorIconsRegular.user, size: 40, color: LP.muted)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: vm.isUploading ? null : vm.pickAndUploadImage,
                        icon: const Icon(PhosphorIconsRegular.camera, size: 16),
                        label: Text(vm.isUploading ? 'Téléversement...' : 'Changer la photo'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Informations générales
                Text('Coordonnées', style: LPText.h3),
                const SizedBox(height: 10),
                TextField(
                  controller: _nameCtrl,
                  onChanged: (v) => vm.fullName = v,
                  decoration: const InputDecoration(labelText: 'Nom complet *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  onChanged: (v) => vm.phone = v,
                  decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: vm.governorate,
                        decoration: const InputDecoration(labelText: 'Gouvernorat', border: OutlineInputBorder()),
                        items: ['Tunis', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul', 'Bizerte', 'Sousse', 'Sfax']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => vm.governorate = v ?? 'Tunis',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _cityCtrl,
                        onChanged: (v) => vm.city = v,
                        decoration: const InputDecoration(labelText: 'Ville / Quartier', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bio avec bouton IA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Présentation', style: LPText.h3),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: LP.primary,
                        backgroundColor: LP.mintBg,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 15),
                      label: const Text(
                        'Rédiger avec l\'IA',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BioGeneratorSheet(
                            name: _nameCtrl.text.trim(),
                            city: _cityCtrl.text.trim(),
                            experienceYears: vm.experienceYears,
                            hasGarden: vm.hasGarden,
                            hasOwnPets: vm.hasOwnPets,
                            services: vm.services,
                            acceptedPetTypes: vm.acceptedPetTypes,
                            onBioSelected: (generatedText) {
                              setState(() {
                                _bioCtrl.text = generatedText;
                                vm.bio = generatedText;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bioCtrl,
                  onChanged: (v) => vm.bio = v,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Décrivez votre expérience, votre logement et votre amour pour les animaux...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Tarifs
                Text('Tarifs (en Dinars Tunisiens)', style: LPText.h3),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceDayCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vm.pricePerDay = double.tryParse(v) ?? 35.0,
                        decoration: const InputDecoration(labelText: 'Prix / jour (DT) *', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _priceHourCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (v) => vm.pricePerHour = double.tryParse(v) ?? 12.0,
                        decoration: const InputDecoration(labelText: 'Prix / heure (DT) *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Prestations proposées
                Text('Services proposés', style: LPText.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in SitterServiceType.values)
                      FilterChip(
                        avatar: Icon(s.icon, size: 14),
                        label: Text(s.label),
                        selected: vm.services.contains(s),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              vm.services.add(s);
                            } else {
                              vm.services.remove(s);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Espèces acceptées
                Text('Espèces acceptées', style: LPText.h3),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in PetSpeciesType.values)
                      FilterChip(
                        avatar: Icon(p.icon, size: 14),
                        label: Text(p.label),
                        selected: vm.acceptedPetTypes.contains(p),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              vm.acceptedPetTypes.add(p);
                            } else {
                              vm.acceptedPetTypes.remove(p);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Conditions d'hébergement
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dispose d\'un jardin clos'),
                  value: vm.hasGarden,
                  onChanged: (v) => setState(() => vm.hasGarden = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Présence d\'autres animaux'),
                  value: vm.hasOwnPets,
                  onChanged: (v) => setState(() => vm.hasOwnPets = v),
                ),
                const SizedBox(height: 24),

                if (vm.errorMessage != null) ...[
                  Text(vm.errorMessage!, style: const TextStyle(color: Color(0xFFD32F2F))),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: vm.isSaving
                        ? null
                        : () async {
                            vm.fullName = _nameCtrl.text;
                            vm.bio = _bioCtrl.text;
                            vm.city = _cityCtrl.text;
                            vm.phone = _phoneCtrl.text;
                            final saved = await vm.save();
                            if (saved != null && context.mounted) {
                              Navigator.pop(context, saved);
                            }
                          },
                    child: vm.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Enregistrer le profil'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// 7. ÉCRAN D'ADMINISTRATION DES SITTERS & RÉSERVATIONS
// ============================================================================

class AdminSittersScreen extends StatelessWidget {
  const AdminSittersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminSittersViewModel>(
      create: (_) => AdminSittersViewModel(),
      builder: (context, vm) {
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Administration Sitters'),
              actions: const [
                PetSitterUserSwitcher(),
                SizedBox(width: 12),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Sitters'),
                  Tab(text: 'Réservations'),
                  Tab(text: 'Statistiques'),
                ],
              ),
            ),
            body: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.errorMessage != null
                    ? ErrorStateView(message: vm.errorMessage!, onRetry: vm.load)
                    : TabBarView(
                        children: [
                          // Tab 1 : Sitters
                          _buildSittersList(context, vm),
                          // Tab 2 : Réservations
                          _buildReservationsList(context, vm),
                          // Tab 3 : Statistiques
                          _buildStatsView(vm),
                        ],
                      ),
          ),
        );
      },
    );
  }

  Widget _buildSittersList(BuildContext context, AdminSittersViewModel vm) {
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.sitters.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final s = vm.sitters[i];
          return BigCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: s.resolvedPhotoUrl.isNotEmpty ? NetworkImage(s.resolvedPhotoUrl) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(s.fullName, style: LPText.h3),
                              if (s.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(PhosphorIconsFill.sealCheck, size: 16, color: LP.primary),
                              ],
                            ],
                          ),
                          Text('${s.locationLabel} · ${s.pricePerDay.toInt()} DT/j', style: LPText.bodyS),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash, color: Color(0xFFD32F2F)),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Supprimer ce sitter ?'),
                            content: Text('Voulez-vous supprimer définitivement ${s.fullName} ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui, supprimer')),
                            ],
                          ),
                        );
                        if (ok == true) vm.deleteSitter(s.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(color: LP.line),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Vérifié par admin', style: LPText.bodyS.copyWith(fontWeight: FontWeight.w600)),
                    Switch(
                      value: s.verified,
                      activeThumbColor: LP.primary,
                      onChanged: (v) => vm.setVerification(s.id, v),
                    ),
                    const SizedBox(width: 12),
                    Text('Actif', style: LPText.bodyS.copyWith(fontWeight: FontWeight.w600)),
                    Switch(
                      value: s.active,
                      activeThumbColor: const Color(0xFF2E7D32),
                      onChanged: (v) => vm.setActive(s.id, v),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservationsList(BuildContext context, AdminSittersViewModel vm) {
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: vm.reservations.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final r = vm.reservations[i];
          return BigCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(status: r.status),
                          Text('${r.totalPrice.toInt()} DT', style: LPText.h3.copyWith(color: LP.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Sitter : ${r.sitterName ?? r.sitterId}', style: LPText.body(w: FontWeight.w700)),
                      Text('Client : ${r.ownerName ?? r.ownerId} · Animal : ${r.petName}', style: LPText.bodyS),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(PhosphorIconsRegular.trash, color: Color(0xFFD32F2F)),
                  onPressed: () => vm.deleteReservation(r.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsView(AdminSittersViewModel vm) {
    final s = vm.stats;
    if (s == null) return const Center(child: Text('Aucune statistique disponible'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vue d\'ensemble', style: LPText.h2),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _bigMetric('Total Sitters', '${s['totalSitters'] ?? 0}', LP.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigMetric('Vérifiés', '${s['verifiedSitters'] ?? 0}', const Color(0xFF2E7D32)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _bigMetric('Sitters Actifs', '${s['activeSitters'] ?? 0}', const Color(0xFF1976D2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigMetric('Réservations', '${s['totalReservations'] ?? 0}', const Color(0xFFE5A000)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigMetric(String label, String value, Color color) {
    return BigCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LPText.bodyS.copyWith(color: LP.muted)),
          const SizedBox(height: 4),
          Text(value, style: LPText.h1.copyWith(color: color)),
        ],
      ),
    );
  }
}
