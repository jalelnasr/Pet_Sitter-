import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/member_avatar.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/events/event_models.dart';
import 'package:pet_sitter/events/event_repository.dart';
import 'package:pet_sitter/events/event_screens.dart';
import 'package:pet_sitter/events/event_widgets.dart';
import 'package:pet_sitter/view_models/home_view_model.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';

const _howItWorks = [
  ('Présentez votre animal', 'Habitudes, repas, soins : son profil suit chaque demande.'),
  ('Choisissez votre sitter', 'Onglet Garde : comparez les pet sitters inscrits et envoyez votre demande.'),
  ('Recevez des nouvelles', 'Messages, photos et journal de garde au quotidien.'),
];

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key, this.onOpenShop, this.onOpenGarde, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  /// Bascule vers l'onglet Boutique de la navigation.
  final VoidCallback? onOpenShop;

  /// Bascule vers l'onglet Garde (pet sitters inscrits, demandes réelles).
  final VoidCallback? onOpenGarde;

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  late final vm = HomeViewModel(
    pets: Deps.of(context).pets,
    shop: Deps.of(context).shop,
    cart: Deps.of(context).cart,
    session: Deps.of(context).session,
    events: ApiEventRepository.shared,
  );

  void _openGarde() {
    final open = widget.onOpenGarde;
    if (open != null) {
      open();
    } else {
      Navigator.pushNamed(context, R.owner);
    }
  }

  void _openEvent(PetEvent event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final highlights = vm.highlights;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Barre du haut : notifications + avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                const Spacer(),
                RoundIconButton(
                  PhosphorIconsRegular.bell,
                  tooltip: 'Notifications',
                  onTap: () => Navigator.pushNamed(context, R.notifications),
                ),
                const SizedBox(width: 10),
                MemberAvatar(photo: vm.ownerPhoto, name: vm.ownerName, size: 44),
              ],
            ),
          ).from(y: -16, duration: 0.5),

          // Salutation
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Bonjour, ${vm.ownerFirstName}',
                        style: LPText.display(size: 32, w: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const GsapLoop(
                      rotation: 18,
                      duration: 0.6,
                      child: Icon(PhosphorIconsFill.handWaving, size: 28, color: Color(0xFFE9A23B)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(vm.greeting, style: LPText.bodyS.copyWith(fontSize: 14.5)),
              ],
            ),
          ).from(y: 20, delay: 0.08),

          // Garde : les pet sitters inscrits (onglet Garde)
          const SizedBox(height: 22),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.dog, size: 24, color: LP.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Faire garder votre animal', style: LPText.h3)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Comparez les pet sitters inscrits, envoyez votre demande et suivez sa réponse.',
                  style: LPText.bodyS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 14),
                PawButton(
                  label: 'Trouver un pet sitter',
                  icon: PhosphorIconsBold.magnifyingGlass,
                  onPressed: _openGarde,
                ),
              ],
            ),
          ).from(y: 36, delay: 0.16, duration: 0.8),

          // Événements publiés (backend) ; « Tout voir » ouvre la liste (création, réservations).
          ...[
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
              child: Row(
                children: [
                  Expanded(child: Text('Événements à venir', style: LPText.h3)),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, R.events),
                    child: const Text('Tout voir'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text('Rencontres, ateliers et sorties entre voisins', style: LPText.bodyS),
            ),
            if (highlights.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: InfoNote(
                  'Aucun événement à venir pour le moment. « Tout voir » ouvre la liste des événements.',
                  icon: PhosphorIconsRegular.calendarBlank,
                ),
              )
            else
            SizedBox(
              height: 258,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: LP.pagePadding,
                itemCount: highlights.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => EventHighlightCard(
                  event: highlights[i],
                  onOpen: () => _openEvent(highlights[i]),
                ).from(x: 40, delay: stagger(i, start: 0.3, each: 0.08), duration: 0.7),
              ),
            ),
          ],

          // Boutique
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('La boutique', style: LPText.h3)),
                TextButton(
                  onPressed: widget.onOpenShop ?? () => Navigator.pushNamed(context, R.shop),
                  child: const Text('Tout voir'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(vm.shopSubtitle, style: LPText.bodyS),
          ),
          if (vm.recommendedProducts.isNotEmpty)
          SizedBox(
            height: 274,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: LP.pagePadding,
              itemCount: vm.recommendedProducts.take(4).length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final items = vm.recommendedProducts;
                return SizedBox(
                  width: 168,
                  child: ProductCard(product: items[i], onAdd: () => vm.addToCart(items[i])),
                );
              },
            ),
          ),

          // Comment ça marche
          const SizedBox(height: 30),
          const SectionHeader('Comment ça marche'),
          const SizedBox(height: 6),
          Padding(
            padding: LP.pagePadding,
            child: Column(
              children: [
                for (var i = 0; i < _howItWorks.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: i == 0 ? LP.primary : LP.mint, shape: BoxShape.circle),
                          child: Text(
                            '${i + 1}',
                            style: LPText.display(size: 16, color: i == 0 ? LP.white : LP.primaryDark),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_howItWorks[i].$1, style: LPText.title.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(_howItWorks[i].$2, style: LPText.bodyS),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).from(x: 24, delay: stagger(i, start: 0.55, each: 0.08)),
              ],
            ),
          ),

          // Mes compagnons
          const SizedBox(height: 22),
          SectionHeader('Vos compagnons', action: 'Gérer', onAction: () => Navigator.pushNamed(context, R.myPets)),
          const SizedBox(height: 10),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: LP.pagePadding,
              children: [
                for (final p in vm.pets)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, R.pet, arguments: p),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(color: LP.mint, shape: BoxShape.circle),
                            child: LPAvatar(p.photo, size: 64),
                          ),
                          const SizedBox(height: 6),
                          Text(p.name, style: LPText.label.copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, R.addPet),
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: LP.primary, width: 1.4),
                        ),
                        child: const Icon(PhosphorIconsRegular.plus, color: LP.primary),
                      ),
                      const SizedBox(height: 6),
                      Text('Ajouter', style: LPText.label.copyWith(fontSize: 13.5)),
                    ],
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
