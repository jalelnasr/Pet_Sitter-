/// Widgets partagés du module Adoption.
library;

import 'package:flutter/material.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/illustrations.dart';
import 'package:pet_sitter/models/species.dart';

import 'adoption_models.dart';
import 'api/demo_session.dart';

class AdoptionStatusPill extends StatelessWidget {
  const AdoptionStatusPill(this.status, {super.key});
  final AdoptionStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      AdoptionStatus.pending => (
        LP.warningSoft,
        LP.warning,
        PhosphorIconsBold.hourglassMedium,
      ),
      AdoptionStatus.accepted => (
        LP.mint,
        LP.primaryDark,
        PhosphorIconsBold.checkCircle,
      ),
      AdoptionStatus.refused => (
        LP.errorSoft,
        LP.error,
        PhosphorIconsBold.xCircle,
      ),
      AdoptionStatus.cancelled => (
        LP.soft,
        LP.muted,
        PhosphorIconsRegular.xCircle,
      ),
    };
    return Pill(label: status.label, bg: bg, fg: fg, icon: icon);
  }
}

/// Pastille du cycle de vie d'une annonce (brouillon, publiée, adoptée…).
class AdoptionListingStatusPill extends StatelessWidget {
  const AdoptionListingStatusPill(this.status, {super.key});
  final AdoptionListingStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (status) {
      AdoptionListingStatus.draft => (
        LP.soft,
        LP.muted,
        PhosphorIconsRegular.notepad,
      ),
      AdoptionListingStatus.published => (
        LP.mint,
        LP.primaryDark,
        PhosphorIconsBold.checkCircle,
      ),
      AdoptionListingStatus.paused => (
        LP.warningSoft,
        LP.warning,
        PhosphorIconsRegular.hourglassMedium,
      ),
      AdoptionListingStatus.adopted => (
        LP.infoSoft,
        LP.info,
        PhosphorIconsRegular.handHeart,
      ),
      AdoptionListingStatus.archived => (
        LP.softDeep,
        LP.muted,
        PhosphorIconsRegular.doorOpen,
      ),
      AdoptionListingStatus.hidden => (
        LP.errorSoft,
        LP.error,
        PhosphorIconsRegular.eyeSlash,
      ),
    };
    return Pill(label: status.label, bg: bg, fg: fg, icon: icon);
  }
}

class AdoptionPetCard extends StatelessWidget {
  const AdoptionPetCard({super.key, required this.pet, required this.onOpen});

  final AdoptionPet pet;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${pet.name}, ${pet.breed}, ${pet.age}, ${pet.city}',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LPImage(pet.photo, width: 112, height: 132, radius: 18),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                pet.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LPText.title.copyWith(fontSize: 17),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Pill(label: pet.sex, bg: LP.soft, fg: LP.ink),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.species.label} · ${pet.breed}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.bodyS,
                        ),
                        const SizedBox(height: 2),
                        Text('${pet.age} · ${pet.city}', style: LPText.bodyS),
                        const SizedBox(height: 8),
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
                                pet.displayLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LPText.bodyS.copyWith(fontSize: 12.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
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
                            label: const Text('Voir le détail'),
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

class AdoptionPetMiniCard extends StatelessWidget {
  const AdoptionPetMiniCard({super.key, required this.pet});
  final AdoptionPet pet;

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
          LPImage(pet.photo, width: 62, height: 72, radius: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: LPText.title.copyWith(fontSize: 16.5)),
                const SizedBox(height: 2),
                Text(
                  '${pet.species.label} · ${pet.breed}',
                  style: LPText.bodyS,
                ),
                Text(
                  '${pet.age} · ${pet.city}',
                  style: LPText.bodyS.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
          const FictifBadge(),
        ],
      ),
    );
  }
}

class AdoptionSectionTitle extends StatelessWidget {
  const AdoptionSectionTitle(this.title, this.icon, {super.key});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30, bottom: 12),
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

class AdoptionFactRow extends StatelessWidget {
  const AdoptionFactRow({
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

class AdoptionHealthPanel extends StatelessWidget {
  const AdoptionHealthPanel({super.key, required this.pet});
  final AdoptionPet pet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: LP.soft,
        borderRadius: BorderRadius.circular(LP.r20),
      ),
      child: Column(
        children: [
          AdoptionFactRow(
            icon: PhosphorIconsRegular.stethoscope,
            label: 'État de santé',
            value: pet.health,
          ),
          const Divider(color: LP.softDeep),
          AdoptionFactRow(
            icon: PhosphorIconsRegular.shieldCheck,
            label: 'Vacciné',
            trailing: _YesNo(value: pet.vaccinated),
          ),
          const Divider(color: LP.softDeep),
          AdoptionFactRow(
            icon: PhosphorIconsRegular.firstAidKit,
            label: 'Stérilisé',
            trailing: _YesNo(value: pet.sterilized),
          ),
        ],
      ),
    );
  }
}

class _YesNo extends StatelessWidget {
  const _YesNo({required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: value ? 'Oui' : 'Non',
      bg: value ? LP.mint : LP.softDeep,
      fg: value ? LP.primaryDark : LP.muted,
      icon: value ? PhosphorIconsBold.checkCircle : PhosphorIconsBold.xCircle,
    );
  }
}

class AdoptionAiCard extends StatelessWidget {
  const AdoptionAiCard({
    super.key,
    this.advice,
    this.loading = false,
    this.unavailable = false,
  });

  final AdoptionAiAdvice? advice;
  final bool loading;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final a = advice;
    if (loading) {
      return DashedBox(
        color: LP.softDeep,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conseil IA', style: LPText.label),
                  const SizedBox(height: 3),
                  Text(
                    'Analyse de compatibilité en cours…',
                    style: LPText.bodyS,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (unavailable) {
      return DashedBox(
        color: LP.softDeep,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              size: 21,
              color: LP.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conseil IA', style: LPText.label),
                  const SizedBox(height: 3),
                  Text(
                    'Service IA indisponible. Vous pouvez tout de même envoyer votre demande.',
                    style: LPText.bodyS,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (a == null) {
      return DashedBox(
        color: LP.softDeep,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              PhosphorIconsRegular.sparkle,
              size: 21,
              color: LP.accentInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Conseil IA', style: LPText.label),
                  const SizedBox(height: 3),
                  Text(
                    'Remplissez votre expérience et votre motivation pour obtenir un score de compatibilité et des recommandations.',
                    style: LPText.bodyS,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LP.night,
        borderRadius: BorderRadius.circular(24),
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
              const Spacer(),
              Text(
                '${a.score} %',
                style: LPText.display(
                  size: 29,
                  color: LP.white,
                  w: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Compatibilité estimée',
            style: LPText.body(
              size: 11.5,
              w: FontWeight.w700,
              color: LP.onNightMuted,
            ).copyWith(letterSpacing: 0.7),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: a.score / 100,
              minHeight: 7,
              backgroundColor: LP.nightSoft,
              color: LP.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(a.summary, style: LPText.body(size: 14.5, color: LP.onNight)),
          const SizedBox(height: 16),
          Text(
            'Recommandations',
            style: LPText.label.copyWith(color: LP.onNight),
          ),
          const SizedBox(height: 8),
          for (final tip in a.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      PhosphorIconsBold.checkCircle,
                      size: 15,
                      color: LP.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: LPText.body(
                        size: 13.5,
                        color: LP.onNightMuted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class AdoptionEmptyState extends StatelessWidget {
  const AdoptionEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionIcon = PhosphorIconsFill.pawPrint,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
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
          const SizedBox(height: 20),
          PawButton(
            label: actionLabel,
            onPressed: onAction,
            mint: true,
            expand: false,
            icon: actionIcon,
          ),
        ],
      ),
    );
  }
}

/// Sélecteur d'espèce circulaire, variante locale du composant partagé.
///
/// La hauteur est légèrement plus généreuse pour éviter tout débordement
/// lorsque la police système est plus grande que prévu.
class AdoptionSpeciesPicker extends StatelessWidget {
  const AdoptionSpeciesPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<Species> selected;
  final ValueChanged<Species> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: Species.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final species = Species.values[index];
          final isSelected = selected.contains(species);
          return Semantics(
            selected: isSelected,
            button: true,
            label: species.plural,
            child: GestureDetector(
              onTap: () => onChanged(species),
              child: SizedBox(
                width: 64,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isSelected ? LP.primary : LP.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? LP.primary : LP.line,
                          width: 1.4,
                        ),
                      ),
                      child: Icon(
                        isSelected ? species.iconFill : species.icon,
                        size: 28,
                        color: isSelected ? LP.white : LP.primary,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      species.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: LPText.body(
                        size: 13,
                        w: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? LP.primaryDark : LP.ink,
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

/// Sélecteur temporaire de l'utilisateur de démonstration.
///
/// Il remplace la vraie authentification jusqu'à l'arrivée du module
/// Utilisateur et du JWT.
class AdoptionDemoUserSelector extends StatelessWidget {
  const AdoptionDemoUserSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final session = DemoSessionProvider.instance;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final user = session.currentUser;
        return PopupMenuButton<DemoUser>(
          tooltip: 'Changer d\'utilisateur de démonstration',
          onSelected: session.select,
          itemBuilder: (context) => [
            for (final candidate in DemoUsers.all)
              PopupMenuItem(
                value: candidate,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: candidate.id == user.id
                          ? LP.primary
                          : LP.soft,
                      child: Text(
                        candidate.initials,
                        style: LPText.body(
                          size: 13,
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
                            style: LPText.body(size: 14.5, w: FontWeight.w700),
                          ),
                          Text(
                            '${candidate.role.label} · ${candidate.id}',
                            style: LPText.bodyS.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: LP.soft,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: LP.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: LP.primary,
                  child: Text(
                    user.initials,
                    style: LPText.body(
                      size: 13,
                      w: FontWeight.w800,
                      color: LP.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.firstName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.body(size: 13.5, w: FontWeight.w800),
                      ),
                      Text(
                        user.role.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.bodyS.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  PhosphorIconsBold.caretDown,
                  size: 14,
                  color: LP.muted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Carte de gestion d'une annonce (mes annonces, modération Admin).
class AdoptionManageCard extends StatelessWidget {
  const AdoptionManageCard({
    super.key,
    required this.pet,
    required this.onOpen,
    this.onEdit,
    this.onPublish,
    this.onPause,
    this.onArchive,
    this.onHide,
    this.adminView = false,
  });

  final AdoptionPet pet;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onPublish;
  final VoidCallback? onPause;
  final VoidCallback? onArchive;
  final VoidCallback? onHide;
  final bool adminView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(LP.r20),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpen,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LPImage(pet.photo, width: 72, height: 84, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: LPText.title.copyWith(fontSize: 16.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          AdoptionListingStatusPill(pet.status),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${pet.species.label} · ${pet.age}',
                        style: LPText.bodyS,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pet.displayLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.bodyS.copyWith(fontSize: 12.5),
                      ),
                      if (adminView && pet.publisherName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Publiée par ${pet.publisherName} · ${pet.publisherId}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.bodyS.copyWith(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (onEdit != null)
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                  label: const Text('Modifier'),
                ),
              if (onPublish != null)
                TextButton.icon(
                  onPressed: onPublish,
                  icon: const Icon(PhosphorIconsRegular.play, size: 16),
                  label: const Text('Publier'),
                ),
              if (onPause != null)
                TextButton.icon(
                  onPressed: onPause,
                  icon: const Icon(
                    PhosphorIconsRegular.hourglassMedium,
                    size: 16,
                  ),
                  label: const Text('Pause'),
                ),
              if (onArchive != null)
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(PhosphorIconsRegular.doorOpen, size: 16),
                  label: const Text('Archiver'),
                ),
              if (onHide != null)
                TextButton.icon(
                  onPressed: onHide,
                  icon: const Icon(PhosphorIconsRegular.eyeSlash, size: 16),
                  label: const Text('Masquer'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Message d'erreur réseau/API avec action de réessai.
class AdoptionErrorNote extends StatelessWidget {
  const AdoptionErrorNote({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          InfoNote(
            message,
            icon: PhosphorIconsRegular.warningCircle,
            tone: InfoTone.error,
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(
              PhosphorIconsRegular.arrowCounterClockwise,
              size: 18,
            ),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

class AdoptionRequestCard extends StatelessWidget {
  const AdoptionRequestCard({
    super.key,
    required this.request,
    required this.onOpen,
    this.subtitle,
  });
  final AdoptionRequest request;
  final VoidCallback onOpen;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${request.pet.name}, ${request.status.label}',
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
                LPImage(request.pet.photo, width: 72, height: 84, radius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.pet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LPText.title.copyWith(fontSize: 16.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.pet.species.label} · ${request.pet.city}',
                        style: LPText.bodyS,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.bodyS.copyWith(
                            fontSize: 12.5,
                            color: LP.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                              'Demande envoyée le ${capitalize(frDate(request.date))}',
                              style: LPText.bodyS.copyWith(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AdoptionStatusPill(request.status),
                    if (request.aiScore != null) ...[
                      const SizedBox(height: 9),
                      Text(
                        '${request.aiScore} % IA',
                        style: LPText.body(
                          size: 12,
                          w: FontWeight.w700,
                          color: LP.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
