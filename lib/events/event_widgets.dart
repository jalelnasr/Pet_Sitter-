/// Widgets partagés du module Événements.
library;

import 'package:flutter/material.dart';
import 'package:pet_sitter/core/session/auth_session.dart';
import 'package:pet_sitter/adoption/api/demo_session.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/illustrations.dart';

import 'event_models.dart';
import 'event_view_models.dart';

class EventStatusPill extends StatelessWidget {
  const EventStatusPill(this.status, {super.key});
  final EventStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      EventStatus.draft => (LP.soft, LP.muted, PhosphorIconsBold.dotsThree),
      EventStatus.pending => (
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
        PhosphorIconsRegular.clock,
      ),
      EventStatus.rejected => (
        LP.errorSoft,
        LP.error,
        PhosphorIconsBold.xCircle,
      ),
      EventStatus.published => (
        LP.mint,
        LP.primaryDark,
        PhosphorIconsBold.checkCircle,
      ),
      EventStatus.cancelled => (
        LP.errorSoft,
        LP.error,
        PhosphorIconsBold.xCircle,
      ),
      EventStatus.completed => (LP.soft, LP.muted, PhosphorIconsBold.check),
    };
    return Pill(label: status.label, bg: bg, fg: fg, icon: icon);
  }
}

class EventReservationStatusPill extends StatelessWidget {
  const EventReservationStatusPill(this.status, {super.key});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      ReservationStatus.confirmed => (
        LP.mint,
        LP.primaryDark,
        PhosphorIconsBold.checkCircle,
      ),
      ReservationStatus.cancelled || ReservationStatus.cancelledByAdmin => (
        LP.errorSoft,
        LP.error,
        PhosphorIconsBold.xCircle,
      ),
    };
    return Pill(label: status.label, bg: bg, fg: fg, icon: icon);
  }
}

/// Puces de catégorie horizontales, sur le modèle de `SpeciesChips`.
class EventCategoryChips extends StatelessWidget {
  const EventCategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
    this.withAll = true,
  });

  final EventCategory? selected;
  final ValueChanged<EventCategory?> onChanged;
  final bool withAll;

  @override
  Widget build(BuildContext context) {
    final items = <(EventCategory?, String, IconData)>[
      if (withAll) (null, 'Toutes', PhosphorIconsRegular.pawPrint),
      for (final c in EventCategory.values) (c, c.label, c.icon),
    ];
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: LP.pagePadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (category, label, icon) = items[i];
          final on = category == selected;
          return Semantics(
            selected: on,
            button: true,
            label: label,
            child: PressScale(
              child: GestureDetector(
                onTap: () => onChanged(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? LP.primary : LP.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: on ? LP.primary : LP.softDeep,
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 17, color: on ? LP.white : LP.ink),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: LPText.body(
                          size: 14.5,
                          w: FontWeight.w700,
                          color: on ? LP.white : LP.ink,
                        ),
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

class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, required this.onOpen});

  final PetEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${event.title}, ${event.category.label}, ${event.dateLabel}',
      child: PressScale(
        scale: 0.98,
        child: Material(
          color: LP.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: LP.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      LPImage(
                        event.imageUrl,
                        width: double.infinity,
                        height: 152,
                        radius: 18,
                      ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Pill(
                          label: event.category.label,
                          icon: event.category.icon,
                          bg: LP.white,
                          fg: LP.primary,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Pill(
                          label: event.seatsLabel,
                          icon: PhosphorIconsRegular.userCircle,
                          bg: event.isFull ? LP.errorSoft : LP.mint,
                          fg: event.isFull ? LP.error : LP.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: LPText.title.copyWith(fontSize: 17.5),
                              ),
                            ),
                            if (event.status != EventStatus.published) ...[
                              const SizedBox(width: 8),
                              EventStatusPill(event.status),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.calendarBlank,
                              size: 15,
                              color: LP.muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.dateLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LPText.bodyS.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              PhosphorIconsRegular.mapPin,
                              size: 15,
                              color: LP.muted,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LPText.bodyS.copyWith(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: onOpen,
                            icon: const Icon(
                              PhosphorIconsRegular.arrowRight,
                              size: 16,
                            ),
                            label: const Text('Voir l\'événement'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EventMiniCard extends StatelessWidget {
  const EventMiniCard({super.key, required this.event});
  final PetEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LP.soft,
        borderRadius: BorderRadius.circular(LP.r20),
      ),
      child: Row(
        children: [
          LPImage(event.imageUrl, width: 72, height: 78, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LPText.title.copyWith(fontSize: 16.5),
                ),
                const SizedBox(height: 3),
                Text(event.dateLabel, style: LPText.bodyS),
                Text(
                  event.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LPText.bodyS.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(fit: BoxFit.scaleDown, child: const FictifBadge()),
          ),
        ],
      ),
    );
  }
}

class EventSectionTitle extends StatelessWidget {
  const EventSectionTitle(this.title, this.icon, {super.key});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: LP.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: LPText.h3)),
        ],
      ),
    );
  }
}

class EventFactRow extends StatelessWidget {
  const EventFactRow({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.trailing,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: LP.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: LP.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: LPText.body(size: 14.5, w: FontWeight.w600, height: 1.3),
            ),
          ),
          if (value != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: LPText.label.copyWith(fontSize: 13.5),
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Détail des places : inscrits, restantes et jauge de remplissage.
class EventSeatsPanel extends StatelessWidget {
  const EventSeatsPanel({super.key, required this.event});
  final PetEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LP.soft,
        borderRadius: BorderRadius.circular(LP.r20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.userCircle,
                size: 20,
                color: LP.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${event.currentParticipants} inscrit${event.currentParticipants > 1 ? 's' : ''} sur ${event.maxParticipants}',
                  style: LPText.label.copyWith(fontSize: 14.5),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Pill(
                    label: event.seatsLabel,
                    bg: event.isFull ? LP.errorSoft : LP.mint,
                    fg: event.isFull ? LP.error : LP.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: event.fillRatio,
              minHeight: 7,
              backgroundColor: LP.softDeep,
              color: event.isFull ? LP.error : LP.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            event.isFull
                ? 'Toutes les places sont prises pour cet événement.'
                : 'Les places restantes sont attribuées à la confirmation de la réservation.',
            style: LPText.bodyS.copyWith(fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Conseil et assistant IA affiché pendant la création d'un événement.
class EventAiCard extends StatelessWidget {
  const EventAiCard({
    super.key,
    this.suggestion,
    this.onTap,
    this.loading = false,
    this.disabled = false,
  });

  final EventAiSuggestion? suggestion;
  final VoidCallback? onTap;
  final bool loading;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    if (disabled) {
      return DashedBox(
        color: LP.softDeep,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              PhosphorIconsRegular.sparkle,
              size: 21,
              color: LP.faint,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conseil IA', style: LPText.label.copyWith(color: LP.muted)),
                  const SizedBox(height: 3),
                  Text(
                    'Renseignez le titre pour activer l\'aide de l\'assistant IA.',
                    style: LPText.bodyS.copyWith(color: LP.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LP.night,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: LP.brandYellow,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Génération par l\'assistant IA...',
                    style: LPText.label.copyWith(color: LP.onNight),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Élaboration des titres, de la description et de la checklist.',
                    style: LPText.bodyS.copyWith(color: LP.onNightMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final a = suggestion;
    final isLlm = a?.isFromLlm ?? false;
    final badgeLabel = isLlm ? 'IA' : 'Suggestion locale';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LP.night,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: LP.nightLine.withOpacity(0.5),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Pill(
                    label: 'Conseil IA',
                    bg: LP.accent,
                    fg: LP.primaryDark,
                    icon: PhosphorIconsBold.sparkle,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLlm ? LP.accentSoft : LP.nightSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(
                        color: isLlm ? LP.accentInk : LP.onNightMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    PhosphorIconsRegular.caretRight,
                    color: LP.onNightMuted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (a != null && a.summary.isNotEmpty) ...[
                Text(
                  a.summary,
                  style: LPText.body(size: 14.5, color: LP.onNight),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ] else ...[
                Text(
                  'Obtenez 3 titres percutants, une description soignée, des tags et une checklist.',
                  style: LPText.body(size: 14, color: LP.onNight),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.sparkle,
                    size: 14,
                    color: LP.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Touchez pour ouvrir et utiliser les suggestions',
                    style: LPText.body(
                      size: 12.5,
                      color: LP.accent,
                      w: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom Sheet affichant les suggestions complètes avec boutons « Utiliser »
class EventAiSuggestionSheet extends StatelessWidget {
  const EventAiSuggestionSheet({
    super.key,
    required this.suggestion,
    required this.onApplyTitle,
    required this.onApplyDescription,
    required this.onApplySummary,
    required this.onApplyTags,
    required this.onApplyChecklist,
    required this.onApplyTip,
    this.onApplyCategory,
  });

  final EventAiSuggestion suggestion;
  final ValueChanged<String> onApplyTitle;
  final ValueChanged<String> onApplyDescription;
  final ValueChanged<String> onApplySummary;
  final ValueChanged<List<String>> onApplyTags;
  final ValueChanged<List<String>> onApplyChecklist;
  final ValueChanged<String> onApplyTip;
  final ValueChanged<String>? onApplyCategory;

  @override
  Widget build(BuildContext context) {
    final isLlm = suggestion.isFromLlm;
    final badgeText = isLlm ? 'IA' : 'Suggestion locale';

    return Container(
      decoration: const BoxDecoration(
        color: LP.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: LP.softDeep,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            // En-tête
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.sparkle, color: LP.accentInk, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suggestions de l\'assistant',
                      style: LPText.display(size: 19, w: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLlm ? LP.accentSoft : LP.softDeep,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: isLlm ? LP.accentInk : LP.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: LP.line),
            // Contenu scrollable
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  // 1. Titres
                  if (suggestion.titles.isNotEmpty) ...[
                    _buildSectionHeader('Titres accrocheurs', PhosphorIconsRegular.notepad),
                    const SizedBox(height: 8),
                    for (final title in suggestion.titles)
                      _buildSuggestionRow(
                        context: context,
                        content: Text(
                          title,
                          style: LPText.body(size: 14.5, w: FontWeight.w600),
                        ),
                        onUse: () => onApplyTitle(title),
                      ),
                    const SizedBox(height: 18),
                  ],

                  // 2. Description
                  if (suggestion.description.isNotEmpty) ...[
                    _buildSectionHeader('Description rédigée', PhosphorIconsRegular.listBullets),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Text(
                        suggestion.description,
                        style: LPText.body(size: 14, height: 1.45),
                      ),
                      onUse: () => onApplyDescription(suggestion.description),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 3. Résumé
                  if (suggestion.summary.isNotEmpty) ...[
                    _buildSectionHeader('Résumé en 1 ligne', PhosphorIconsRegular.chatCircleDots),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Text(
                        suggestion.summary,
                        style: LPText.body(size: 13.5, w: FontWeight.w500),
                      ),
                      onUse: () => onApplySummary(suggestion.summary),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 4. Tags
                  if (suggestion.tags.isNotEmpty) ...[
                    _buildSectionHeader('Tags recommandés', PhosphorIconsRegular.tag),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in suggestion.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: LP.mint,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                tag.startsWith('#') ? tag : '#$tag',
                                style: LPText.body(size: 12, w: FontWeight.w700, color: LP.brandGreen),
                              ),
                            ),
                        ],
                      ),
                      onUse: () => onApplyTags(suggestion.tags),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 5. Checklist
                  if (suggestion.checklist.isNotEmpty) ...[
                    _buildSectionHeader('Matériel à prévoir', PhosphorIconsRegular.checkCircle),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in suggestion.checklist)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(
                                      PhosphorIconsRegular.checkCircle,
                                      size: 15,
                                      color: LP.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: LPText.body(size: 13.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      onUse: () => onApplyChecklist(suggestion.checklist),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 6. Conseil / Tip
                  if (suggestion.tip.isNotEmpty) ...[
                    _buildSectionHeader('Conseil d\'organisation', PhosphorIconsRegular.info),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(PhosphorIconsBold.sparkle, size: 18, color: LP.accentInk),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              suggestion.tip,
                              style: LPText.body(size: 13.5, color: LP.accentInk, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                      cardColor: LP.warningSoft,
                      onUse: () => onApplyTip(suggestion.tip),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 7. Catégorie suggérée
                  if (suggestion.suggestedCategory.isNotEmpty && onApplyCategory != null) ...[
                    _buildSectionHeader('Catégorie suggérée', PhosphorIconsRegular.squaresFour),
                    const SizedBox(height: 8),
                    _buildSuggestionCard(
                      context: context,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: LP.mint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(PhosphorIconsRegular.pawPrint, size: 18, color: LP.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion.suggestedCategory,
                              style: LPText.label.copyWith(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                      onUse: () => onApplyCategory!(suggestion.suggestedCategory),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: LP.primary),
        const SizedBox(width: 6),
        Text(title, style: LPText.label.copyWith(fontSize: 13.5, color: LP.primaryDark)),
      ],
    );
  }

  Widget _buildSuggestionRow({
    required BuildContext context,
    required Widget content,
    required VoidCallback onUse,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LP.soft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LP.line),
      ),
      child: Row(
        children: [
          Expanded(child: content),
          const SizedBox(width: 10),
          _buildUseButton(onUse),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required BuildContext context,
    required Widget child,
    required VoidCallback onUse,
    Color cardColor = LP.soft,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          child,
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _buildUseButton(onUse),
          ),
        ],
      ),
    );
  }

  Widget _buildUseButton(VoidCallback onUse) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: LP.primary,
        foregroundColor: LP.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onUse,
      icon: const Icon(PhosphorIconsBold.check, size: 14),
      label: const Text(
        'Utiliser',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EventEmptyState extends StatelessWidget {
  const EventEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = PhosphorIconsFill.pawPrint,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
      child: Column(
        children: [
          const EmptyIllustration(size: 132),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: LPText.h2),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: LPText.bodyM.copyWith(color: LP.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            PawButton(
              label: actionLabel!,
              onPressed: onAction,
              mint: true,
              expand: false,
              icon: actionIcon,
            ),
          ],
        ],
      ),
    );
  }
}

class EventReservationCard extends StatelessWidget {
  const EventReservationCard({
    super.key,
    required this.item,
    required this.onOpen,
  });

  final EventReservationItem item;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final r = item.reservation;
    final e = item.event;
    return Semantics(
      button: true,
      label: '${e.title}, ${r.status.label}',
      child: Material(
        color: LP.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LP.r20),
          side: const BorderSide(color: LP.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(LP.r20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LPImage(e.imageUrl, width: 72, height: 84, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.title.copyWith(fontSize: 16.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${r.participants} place${r.participants > 1 ? 's' : ''} · ${e.category.label}',
                        style: LPText.bodyS,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            PhosphorIconsRegular.calendarBlank,
                            size: 14,
                            color: LP.muted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Réservé le ${capitalize(frDate(r.reservationDate))}',
                              style: LPText.bodyS.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: EventReservationStatusPill(r.status),
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

class MyEventCard extends StatelessWidget {
  const MyEventCard({
    super.key,
    required this.event,
    required this.onOpen,
    required this.onEdit,
    required this.onCancel,
  });

  final PetEvent event;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LP.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LP.r20),
        side: const BorderSide(color: LP.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LPImage(event.imageUrl, width: 84, height: 84, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.title.copyWith(fontSize: 16.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            PhosphorIconsRegular.userCircle,
                            size: 15,
                            color: LP.muted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${event.currentParticipants} / ${event.maxParticipants} participants',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LPText.bodyS.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      EventStatusPill(event.status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 2,
              children: [
                _CardAction(
                  icon: PhosphorIconsRegular.arrowRight,
                  label: 'Voir',
                  onPressed: onOpen,
                ),
                _CardAction(
                  icon: PhosphorIconsRegular.pencilSimple,
                  label: 'Modifier',
                  onPressed: onEdit,
                ),
                _CardAction(
                  icon: PhosphorIconsRegular.xCircle,
                  label: 'Annuler',
                  color: LP.error,
                  onPressed: onCancel,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Action compacte de carte (Voir, Modifier, Annuler).
class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: LPText.body(
          size: 13.5,
          w: FontWeight.w700,
          color: onPressed == null ? LP.faint : color ?? LP.primary,
        ),
      ),
    );
  }
}

/// Carte compacte pour les mises en avant de l'accueil.
class EventHighlightCard extends StatelessWidget {
  const EventHighlightCard({
    super.key,
    required this.event,
    required this.onOpen,
  });

  final PetEvent event;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${event.title}, ${event.dateLabel}, ${event.seatsLabel}',
      child: PressScale(
        scale: 0.97,
        child: Material(
          color: LP.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: LP.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onOpen,
            child: SizedBox(
              width: 236,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        LPImage(
                          event.imageUrl,
                          width: 220,
                          height: 118,
                          radius: 18,
                        ),
                        Positioned(
                          left: 8,
                          top: 8,
                          child: Pill(
                            label: event.category.label,
                            icon: event.category.icon,
                            bg: LP.white,
                            fg: LP.primary,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 10, 6, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LPText.title.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                PhosphorIconsRegular.calendarBlank,
                                size: 14,
                                color: LP.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.dateLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LPText.bodyS.copyWith(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                PhosphorIconsRegular.mapPin,
                                size: 14,
                                color: LP.muted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LPText.bodyS.copyWith(fontSize: 12.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Pill(
                                label: event.seatsLabel,
                                icon: PhosphorIconsRegular.userCircle,
                                bg: event.isFull ? LP.errorSoft : LP.mint,
                                fg: event.isFull ? LP.error : LP.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Choix d'une image parmi une sélection locale (aucun téléversement réel).
class EventImagePicker extends StatelessWidget {
  const EventImagePicker({
    super.key,
    required this.images,
    required this.selected,
    required this.onChanged,
  });

  final List<String> images;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final url = images[i];
          final on = url == selected;
          return Semantics(
            selected: on,
            button: true,
            label: 'Image ${i + 1}',
            child: GestureDetector(
              onTap: () => onChanged(url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: on ? LP.primary : LP.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: on ? LP.primary : LP.line,
                    width: 1.4,
                  ),
                ),
                child: Stack(
                  children: [
                    LPImage(url, width: 72, height: 72, radius: 14),
                    if (on)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: LP.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsBold.check,
                            size: 13,
                            color: LP.white,
                          ),
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

/// Sélecteur de profil démo (Amira / Sami / Admin) pour tester les différents rôles.
class EventDemoUserSelector extends StatelessWidget {
  const EventDemoUserSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Un vrai compte est connecté : le serveur utilise ce compte, le sélecteur de test n'a plus d'effet.
    if (AuthSession.instance.isAuthenticated) return const SizedBox.shrink();
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.currentUser;
        return PopupMenuButton<DemoUser>(
          tooltip: 'Changer de profil démo (Rôle)',
          onSelected: session.select,
          itemBuilder: (context) => [
            for (final candidate in DemoUsers.all)
              PopupMenuItem(
                value: candidate,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          candidate.id == user.id ? LP.primary : LP.soft,
                      child: Text(
                        candidate.initials,
                        style: LPText.body(
                          size: 12,
                          w: FontWeight.w800,
                          color: candidate.id == user.id ? LP.white : LP.muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.firstName,
                            style: LPText.body(size: 14, w: FontWeight.w700),
                          ),
                          Text(
                            '${candidate.role.label} · ${candidate.id}',
                            style: LPText.bodyS.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    if (candidate.id == user.id)
                      const Icon(
                        PhosphorIconsBold.check,
                        size: 16,
                        color: LP.primary,
                      ),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: LP.mintPale,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: LP.primary.withOpacity(0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: LP.primary,
                    child: Text(
                      user.initials,
                      style: LPText.body(
                        size: 10,
                        w: FontWeight.w800,
                        color: LP.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.firstName,
                    style: LPText.body(
                      size: 12.5,
                      w: FontWeight.w700,
                      color: LP.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    PhosphorIconsBold.caretDown,
                    size: 13,
                    color: LP.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

