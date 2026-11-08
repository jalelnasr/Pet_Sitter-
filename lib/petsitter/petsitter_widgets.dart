import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/petsitter/petsitter_models.dart';

// ==========================================
// 0. CARTE BASE BIGCARD DU MODULE
// ==========================================

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = LP.white,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: LP.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

// ==========================================
// 1. CARTE DU PET SITTER
// ==========================================

class SitterCard extends StatelessWidget {
  const SitterCard({
    super.key,
    required this.sitter,
    required this.onTap,
  });

  final PetSitter sitter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BigCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo de profil
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: sitter.resolvedPhotoUrl.isNotEmpty
                      ? Image.network(
                          sitter.resolvedPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            sitter.fullName,
                            style: LPText.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (sitter.verified) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            PhosphorIconsFill.sealCheck,
                            size: 18,
                            color: LP.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsRegular.mapPin,
                          size: 14,
                          color: LP.muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          sitter.locationLabel,
                          style: LPText.bodyS.copyWith(color: LP.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          PhosphorIconsFill.star,
                          size: 15,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          sitter.averageRating > 0
                              ? sitter.averageRating.toStringAsFixed(1)
                              : 'Nouveau',
                          style: LPText.body(size: 13.5, w: FontWeight.w700),
                        ),
                        if (sitter.reviewsCount > 0) ...[
                          const SizedBox(width: 3),
                          Text(
                            '(${sitter.reviewsCount})',
                            style: LPText.bodyS.copyWith(fontSize: 12),
                          ),
                        ],
                        const Spacer(),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${sitter.pricePerDay.toInt()} DT',
                                style: LPText.body(
                                  size: 16,
                                  w: FontWeight.w800,
                                  color: LP.primary,
                                ),
                              ),
                              TextSpan(
                                text: ' / jour',
                                style: LPText.bodyS.copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (sitter.services.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final s in sitter.services.take(3))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: LP.soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon, size: 12, color: LP.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.label,
                          style: LPText.bodyS.copyWith(
                            fontSize: 11.5,
                            color: LP.ink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (sitter.services.length > 3)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: LP.soft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${sitter.services.length - 3}',
                      style: LPText.bodyS.copyWith(
                        fontSize: 11,
                        color: LP.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: LP.soft,
      alignment: Alignment.center,
      child: const Icon(PhosphorIconsRegular.user, size: 32, color: LP.muted),
    );
  }
}

// ==========================================
// 2. BADGE DE STATUT
// ==========================================

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. CARTE DE RÉSERVATION
// ==========================================

class ReservationCard extends StatelessWidget {
  const ReservationCard({
    super.key,
    required this.reservation,
    this.onTap,
    this.onCancel,
    this.onReview,
    this.onAccept,
    this.onReject,
    this.onComplete,
    this.isSitterView = false,
  });

  final SitterReservation reservation;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onReview;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;
  final bool isSitterView;

  @override
  Widget build(BuildContext context) {
    final startStr =
        '${reservation.startDate.day}/${reservation.startDate.month}/${reservation.startDate.year}';
    final endStr =
        '${reservation.endDate.day}/${reservation.endDate.month}/${reservation.endDate.year}';

    return BigCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut et prix
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusBadge(status: reservation.status),
              Text(
                '${reservation.totalPrice.toInt()} DT',
                style: LPText.h3.copyWith(color: LP.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Cible (Sitter ou Propriétaire)
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: LP.soft,
                backgroundImage: reservation.resolvedSitterPhoto != null
                    ? NetworkImage(reservation.resolvedSitterPhoto!)
                    : null,
                child: reservation.resolvedSitterPhoto == null
                    ? const Icon(PhosphorIconsRegular.user, size: 18, color: LP.muted)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSitterView
                          ? (reservation.ownerName ?? 'Client')
                          : (reservation.sitterName ?? 'Pet Sitter'),
                      style: LPText.body(size: 15, w: FontWeight.w700),
                    ),
                    Text(
                      '${reservation.service.label} · ${reservation.petName} (${reservation.petType.label})',
                      style: LPText.bodyS.copyWith(color: LP.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: LP.line),
          const SizedBox(height: 12),
          // Dates
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.calendarCheck,
                size: 16,
                color: LP.muted,
              ),
              const SizedBox(width: 6),
              Text(
                '$startStr → $endStr (${reservation.daysCount} jours)',
                style: LPText.body(size: 13, w: FontWeight.w600),
              ),
            ],
          ),
          if (reservation.rejectionReason != null &&
              reservation.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.info,
                    size: 14,
                    color: Color(0xFFD32F2F),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Motif du refus : ${reservation.rejectionReason}',
                      style: LPText.bodyS.copyWith(
                        color: const Color(0xFFD32F2F),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Boutons d'actions
          if (_hasActions()) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSitterView &&
                    reservation.status == ReservationStatus.pending &&
                    onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(PhosphorIconsRegular.x, size: 14),
                    label: const Text('Annuler'),
                  ),
                if (!isSitterView &&
                    reservation.status == ReservationStatus.completed &&
                    !reservation.hasReview &&
                    onReview != null)
                  FilledButton.icon(
                    onPressed: onReview,
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(PhosphorIconsRegular.star, size: 14),
                    label: const Text('Laisser un avis'),
                  ),
                if (isSitterView &&
                    reservation.status == ReservationStatus.pending) ...[
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD32F2F),
                        side: const BorderSide(color: Color(0xFFD32F2F)),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Refuser'),
                    ),
                  const SizedBox(width: 8),
                  if (onAccept != null)
                    FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      child: const Text('Accepter'),
                    ),
                ],
                if (isSitterView &&
                    reservation.status == ReservationStatus.accepted &&
                    onComplete != null)
                  FilledButton.icon(
                    onPressed: onComplete,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(PhosphorIconsBold.check, size: 14),
                    label: const Text('Terminer la garde'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActions() {
    if (!isSitterView) {
      return (reservation.status == ReservationStatus.pending && onCancel != null) ||
          (reservation.status == ReservationStatus.completed &&
              !reservation.hasReview &&
              onReview != null);
    } else {
      return reservation.status == ReservationStatus.pending ||
          reservation.status == ReservationStatus.accepted;
    }
  }
}

// ==========================================
// 4. BOTTOM SHEET DE FILTRES
// ==========================================

class SitterFilterSheet extends StatefulWidget {
  const SitterFilterSheet({
    super.key,
    this.initialGovernorate,
    this.initialService,
    this.initialPetType,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinRating,
    this.initialVerifiedOnly = false,
    this.initialSortBy = 'rating',
    required this.onApply,
    required this.onReset,
  });

  final String? initialGovernorate;
  final SitterServiceType? initialService;
  final PetSpeciesType? initialPetType;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final double? initialMinRating;
  final bool initialVerifiedOnly;
  final String initialSortBy;

  final void Function({
    String? governorate,
    SitterServiceType? service,
    PetSpeciesType? petType,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? verifiedOnly,
    String? sortBy,
  }) onApply;

  final VoidCallback onReset;

  @override
  State<SitterFilterSheet> createState() => _SitterFilterSheetState();
}

class _SitterFilterSheetState extends State<SitterFilterSheet> {
  static const _governorates = [
    'Toutes les régions',
    'Tunis',
    'Ariana',
    'Ben Arous',
    'Manouba',
    'Nabeul',
    'Bizerte',
    'Sousse',
    'Monastir',
    'Sfax',
  ];

  late String _selectedGov = widget.initialGovernorate ?? _governorates.first;
  late SitterServiceType? _selectedService = widget.initialService;
  late PetSpeciesType? _selectedPetType = widget.initialPetType;
  late RangeValues _priceRange = RangeValues(
    widget.initialMinPrice ?? 10.0,
    widget.initialMaxPrice ?? 80.0,
  );
  late final double? _minRating = widget.initialMinRating;
  late bool _verifiedOnly = widget.initialVerifiedOnly;
  late String _sortBy = widget.initialSortBy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtres de recherche', style: LPText.h2),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(PhosphorIconsRegular.x),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Région
            Text('Gouvernorat', style: LPText.body(w: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: LP.soft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LP.line),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedGov,
                  items: _governorates
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedGov = val ?? _governorates.first),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Service
            Text('Type de prestation', style: LPText.body(w: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in SitterServiceType.values)
                  ChoiceChip(
                    label: Text(s.label),
                    avatar: Icon(s.icon, size: 14),
                    selected: _selectedService == s,
                    onSelected: (sel) =>
                        setState(() => _selectedService = sel ? s : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Espèce
            Text('Animal gardé', style: LPText.body(w: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in PetSpeciesType.values)
                  ChoiceChip(
                    label: Text(p.label),
                    avatar: Icon(p.icon, size: 14),
                    selected: _selectedPetType == p,
                    onSelected: (sel) =>
                        setState(() => _selectedPetType = sel ? p : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Fourchette de prix par jour
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tarif journalier', style: LPText.body(w: FontWeight.w700)),
                Text(
                  '${_priceRange.start.toInt()} DT - ${_priceRange.end.toInt()} DT',
                  style: LPText.body(color: LP.primary, w: FontWeight.w700),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 10,
              max: 100,
              divisions: 18,
              activeColor: LP.primary,
              onChanged: (val) => setState(() => _priceRange = val),
            ),
            const SizedBox(height: 10),
            // Tri
            Text('Trier par', style: LPText.body(w: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Meilleures notes'),
                  selected: _sortBy == 'rating',
                  onSelected: (_) => setState(() => _sortBy = 'rating'),
                ),
                ChoiceChip(
                  label: const Text('Prix croissant'),
                  selected: _sortBy == 'price_asc',
                  onSelected: (_) => setState(() => _sortBy = 'price_asc'),
                ),
                ChoiceChip(
                  label: const Text('Prix décroissant'),
                  selected: _sortBy == 'price_desc',
                  onSelected: (_) => setState(() => _sortBy = 'price_desc'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Switch vérifié
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Sitters vérifiés uniquement',
                style: LPText.body(w: FontWeight.w600),
              ),
              subtitle: Text(
                'Profil validé par l\'équipe Pet Sitter',
                style: LPText.bodyS.copyWith(color: LP.muted),
              ),
              value: _verifiedOnly,
              activeThumbColor: LP.primary,
              onChanged: (v) => setState(() => _verifiedOnly = v),
            ),
            const SizedBox(height: 24),
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    child: const Text('Réinitialiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        governorate: _selectedGov == _governorates.first
                            ? null
                            : _selectedGov,
                        service: _selectedService,
                        petType: _selectedPetType,
                        minPrice: _priceRange.start,
                        maxPrice: _priceRange.end,
                        minRating: _minRating,
                        verifiedOnly: _verifiedOnly,
                        sortBy: _sortBy,
                      );
                      Navigator.pop(context);
                    },
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 5. ÉTATS VIDE ET ERREUR
// ==========================================

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.onAction,
    this.icon = PhosphorIconsRegular.pawPrint,
  });

  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: LP.soft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: LP.primary),
            ),
            const SizedBox(height: 18),
            Text(title, style: LPText.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: LPText.body(color: LP.muted),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              size: 48,
              color: Color(0xFFD32F2F),
            ),
            const SizedBox(height: 16),
            Text('Une erreur est survenue', style: LPText.h3),
            const SizedBox(height: 8),
            Text(
              message,
              style: LPText.bodyS.copyWith(color: LP.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowCounterClockwise),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
