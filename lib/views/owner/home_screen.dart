import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/view_models/home_view_model.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';

const _howItWorks = [
  ('Présentez votre animal', 'Habitudes, repas, soins : son profil suit chaque demande.'),
  ('Choisissez votre sitter', 'Comparez les profils près de chez vous et échangez avant de réserver.'),
  ('Recevez des nouvelles', 'Messages, photos et journal de garde au quotidien.'),
];

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key, this.onOpenShop, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  /// Bascule vers l'onglet Boutique de la navigation.
  final VoidCallback? onOpenShop;

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preview == 'place') WidgetsBinding.instance.addPostFrameCallback((_) => _pickPlace());
  }

  late final vm = HomeViewModel(
    sitters: Deps.of(context).sitters,
    pets: Deps.of(context).pets,
    shop: Deps.of(context).shop,
    cart: Deps.of(context).cart,
  );

  Future<void> _pickPlace() async {
    final res = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PlaceSheet(cities: vm.cities),
    );
    if (res != null) vm.setPlace(res.$1, res.$2);
  }

  Future<void> _pickDates() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026, 10, 16),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: vm.query.dates,
      helpText: 'Dates de la garde',
      saveText: 'Valider',
    );
    if (r != null) vm.setDates(r);
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final sitters = vm.nearbySitters;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Barre du haut : quartier + notifications + avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                PressScale(
                  child: Material(
                    color: LP.soft,
                    shape: const StadiumBorder(),
                    child: InkWell(
                      customBorder: const StadiumBorder(),
                      onTap: _pickPlace,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsFill.mapPin, size: 18, color: LP.primary),
                            const SizedBox(width: 6),
                            Text('${vm.query.area}, ${vm.query.city}', style: LPText.label.copyWith(fontSize: 14)),
                            const SizedBox(width: 4),
                            const Icon(PhosphorIconsBold.caretDown, size: 14, color: LP.muted),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                RoundIconButton(
                  PhosphorIconsRegular.bell,
                  badge: true,
                  tooltip: 'Notifications',
                  onTap: () => Navigator.pushNamed(context, R.notifications),
                ),
                const SizedBox(width: 10),
                LPAvatar(vm.ownerPhoto, size: 44),
              ],
            ),
          ).from(y: -16, duration: 0.5),

          // Salutation + bouton recherche rond
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
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
                      Text('Bonne soirée ! Qui gardons-nous ?', style: LPText.bodyS.copyWith(fontSize: 14.5)),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Rechercher un pet sitter',
                  child: PressScale(
                    child: Material(
                      color: LP.white,
                      shape: const StadiumBorder(side: BorderSide(color: LP.softDeep, width: 1.3)),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: () => Navigator.pushNamed(context, R.search, arguments: vm.query),
                        child: const SizedBox(
                          width: 50,
                          height: 64,
                          child: Icon(PhosphorIconsRegular.magnifyingGlass, size: 22, color: LP.primary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ).from(y: 20, delay: 0.08),
          const SizedBox(height: 20),

          // Puces d'espèce
          SpeciesChips(selected: vm.filter, onChanged: vm.setFilter).from(x: 40, delay: 0.16, duration: 0.7),

          // Sitters près de chez vous : cartes photo
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Près de chez vous', style: LPText.h3)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, R.search, arguments: vm.query),
                  child: const Text('Tout voir'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              'Profils fictifs, pour illustrer l\'application.',
              style: LPText.body(size: 12.5, color: LP.accentInk, w: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 270,
            child: ListView.separated(
              key: ValueKey(vm.filter),
              scrollDirection: Axis.horizontal,
              padding: LP.pagePadding,
              itemCount: sitters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _SitterCard(
                sitter: sitters[i],
                service: vm.query.service,
              ).from(x: 40, delay: stagger(i, start: 0.2, each: 0.08), duration: 0.7),
            ),
          ),

          // Moteur de recherche
          const SizedBox(height: 28),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    children: [
                      Text('Où et quand ?', style: LPText.h3),
                      const Spacer(),
                      Icon(vm.query.species.iconFill, size: 20, color: LP.primary),
                      const SizedBox(width: 6),
                      Text(vm.query.species.label, style: LPText.label),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SearchRow(
                  icon: PhosphorIconsRegular.mapPin,
                  label: 'Ville ou quartier',
                  value: '${vm.query.area}, ${vm.query.city}',
                  onTap: _pickPlace,
                ),
                const SizedBox(height: 8),
                _SearchRow(
                  icon: PhosphorIconsRegular.calendarBlank,
                  label: 'Dates',
                  value: '${capitalize(frDate(vm.query.dates.start))} → ${frDate(vm.query.dates.end)}',
                  trailing: vm.query.service == ServiceType.accueil
                      ? '${vm.query.nights} nuits'
                      : '${vm.query.nights + 1} jours',
                  onTap: _pickDates,
                ),
                const SizedBox(height: 12),
                _ServiceToggle(value: vm.query.service, onChanged: vm.setService),
                const SizedBox(height: 14),
                PawButton(
                  label: 'Rechercher un pet sitter',
                  icon: PhosphorIconsBold.magnifyingGlass,
                  onPressed: () => Navigator.pushNamed(context, R.search, arguments: vm.query),
                ),
              ],
            ),
          ).from(y: 36, delay: 0.42, duration: 0.8),

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
            child: Text('Pour Simba, Kiwi et Bulle · livraison offerte dès 80 DT', style: LPText.bodyS),
          ),
          SizedBox(
            height: 274,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: LP.pagePadding,
              itemCount: 4,
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

class _SitterCard extends StatefulWidget {
  const _SitterCard({required this.sitter, required this.service});
  final Sitter sitter;
  final ServiceType service;

  @override
  State<_SitterCard> createState() => _SitterCardState();
}

class _SitterCardState extends State<_SitterCard> {
  bool _fav = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sitter;
    final offer = s.services.firstWhere((o) => o.type == widget.service, orElse: () => s.mainOffer);
    return Semantics(
      button: true,
      label: '${s.firstName}, ${s.area}, ${offer.price} dinars par ${offer.unit}',
      child: PressScale(
        scale: 0.97,
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, R.sitter, arguments: s),
          child: Container(
            width: 216,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LP.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: LP.line),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(color: LP.mintBg, borderRadius: BorderRadius.circular(20)),
                      child: LPImage(s.photo, width: 200, height: 168, radius: 20),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(color: LP.white, borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              s.hasReviews ? PhosphorIconsFill.star : PhosphorIconsFill.sparkle,
                              size: 13,
                              color: LP.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.hasReviews ? s.rating!.toStringAsFixed(1).replaceAll('.', ',') : 'Nouveau',
                              style: LPText.body(size: 12.5, w: FontWeight.w800, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: BounceOnChange(
                        value: _fav,
                        child: RoundIconButton(
                          _fav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                          size: 36,
                          bg: LP.white,
                          fg: _fav ? LP.error : LP.ink,
                          tooltip: _fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
                          onTap: () => setState(() => _fav = !_fav),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: LP.night.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final sp in s.species.take(4))
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(sp.iconFill, size: 13, color: LP.white, semanticLabel: sp.plural),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 10, 6, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.firstName,
                              style: LPText.title.copyWith(fontSize: 17),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (s.verifications.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            const Icon(PhosphorIconsFill.sealCheck, size: 16, color: LP.primary),
                          ],
                        ],
                      ),
                      Text(
                        '${s.area} · ${s.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                        style: LPText.bodyS.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(offer.type.icon, size: 15, color: LP.muted),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: '${offer.price} DT', style: LPText.price.copyWith(fontSize: 17)),
                                  TextSpan(text: ' / ${offer.unit}', style: LPText.bodyS.copyWith(fontSize: 13)),
                                ],
                              ),
                            ),
                          ),
                        ],
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

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.icon, required this.label, required this.value, this.trailing, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LP.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: LP.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: LPText.bodyS.copyWith(fontSize: 12.5)),
                    Text(
                      value,
                      style: LPText.body(size: 15.5, w: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailing != null) Pill(label: trailing!, bg: LP.primary, fg: LP.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  const _ServiceToggle({required this.value, required this.onChanged});
  final ServiceType value;
  final ValueChanged<ServiceType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in ServiceType.values) ...[
          Expanded(
            child: Semantics(
              selected: value == s,
              button: true,
              child: PressScale(
                child: GestureDetector(
                  onTap: () => onChanged(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Ease.power3Out,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: value == s ? LP.mint : LP.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: value == s ? LP.primary : LP.line, width: value == s ? 1.8 : 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(s.icon, size: 21, color: LP.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s == ServiceType.accueil ? 'Accueil' : 'Visites',
                                style: LPText.body(
                                  size: 15,
                                  w: FontWeight.w800,
                                  height: 1.2,
                                  color: value == s ? LP.primaryDark : LP.ink,
                                ),
                              ),
                              Text(
                                s == ServiceType.accueil ? 'chez le sitter' : 'à domicile',
                                style: LPText.body(size: 12.5, height: 1.2, color: LP.muted),
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
          if (s == ServiceType.accueil) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  const _PlaceSheet({required this.cities});
  final List<(String, String)> cities;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (_, ctrl) => ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text('Où se trouve votre animal ?', style: LPText.h2),
          const SizedBox(height: 16),
          const TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Ville, quartier ou adresse',
              prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(PhosphorIconsRegular.navigationArrow, color: LP.primary),
            title: Text('Utiliser ma position', style: LPText.label.copyWith(color: LP.primary)),
            onTap: () => Navigator.pop(context, ('La Marsa', 'Tunis')),
          ),
          const Divider(),
          const SizedBox(height: 12),
          Text('SUGGESTIONS', style: LPText.overline),
          for (final (area, city) in cities)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(PhosphorIconsRegular.mapPin, color: LP.muted),
              title: Text(area, style: LPText.bodyL),
              subtitle: Text(city, style: LPText.bodyS),
              onTap: () => Navigator.pop(context, (area, city)),
            ),
        ],
      ),
    );
  }
}
