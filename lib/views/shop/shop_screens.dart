import 'package:flutter/material.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/big_shapes.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/data/repositories/cart_repository.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/view_models/shop_view_model.dart';
import 'package:pet_sitter/core/widgets/product_art.dart';

String _dt(int v) => '$v DT';

// ————————————————————————————————————————————— Bouton panier (avec pastille)

class CartButton extends StatelessWidget {
  const CartButton({super.key, this.bg = LP.white});
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<CartViewModel>(
      create: (context) => CartViewModel(Deps.of(context).cart),
      builder: (context, vm) {
        final n = vm.count;
        return Semantics(
          button: true,
          label: 'Panier, $n article${n > 1 ? 's' : ''}',
          excludeSemantics: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              RoundIconButton(
                PhosphorIconsRegular.shoppingBag,
                bg: bg,
                tooltip: 'Panier',
                onTap: () => Navigator.pushNamed(context, R.cart),
              ),
              if (n > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: BounceOnChange(
                    value: n,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: LP.accent,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: bg, width: 2),
                      ),
                      child: Text(
                        '$n',
                        style: LPText.body(size: 11, w: FontWeight.w800, color: LP.primaryDark, height: 1),
                      ),
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

// ————————————————————————————————————————————— CATALOGUE

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preview == 'food') {
      WidgetsBinding.instance.addPostFrameCallback((_) => vm.toggleCategory(ShopCategory.nourriture));
    }
  }

  late final vm = ShopViewModel(shop: Deps.of(context).shop, pets: Deps.of(context).pets, cart: Deps.of(context).cart);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final items = vm.products;
    final myPets = vm.myPets;
    final recommended = vm.recommended;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 130),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Boutique', style: LPText.display(size: 32, w: FontWeight.w700)),
                      Text('Nourriture et accessoires livrés chez vous', style: LPText.bodyS.copyWith(fontSize: 14)),
                    ],
                  ),
                ),
                const CartButton(),
              ],
            ),
          ).from(y: -14, duration: 0.5),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: TextField(
              onChanged: vm.setQuery,
              decoration: InputDecoration(
                hintText: 'Croquettes, litière, jouets…',
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, size: 20),
                fillColor: LP.soft,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(99),
                  borderSide: const BorderSide(color: LP.primary, width: 1.6),
                ),
              ),
            ),
          ).from(y: 16, delay: 0.06),
          const SizedBox(height: 16),
          SpeciesChips(selected: vm.species, onChanged: vm.setSpecies).from(x: 40, delay: 0.1),
          const SizedBox(height: 10),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: LP.pagePadding,
              children: [
                _CategoryPill(
                  label: 'Tout',
                  icon: PhosphorIconsRegular.squaresFour,
                  on: vm.category == null,
                  onTap: () => vm.toggleCategory(null),
                ),
                for (final c in ShopCategory.values)
                  _CategoryPill(label: c.label, icon: c.icon, on: vm.category == c, onTap: () => vm.toggleCategory(c)),
              ],
            ),
          ).from(x: 40, delay: 0.14),

          // Bandeau livraison
          const SizedBox(height: 20),
          const _PromoBanner().from(y: 24, scale: 0.97, delay: 0.2, duration: 0.7),

          // Recommandés pour mes animaux
          if (!vm.hasFilters) ...[
            const SizedBox(height: 26),
            Padding(
              padding: LP.pagePadding,
              child: Row(
                children: [
                  SizedBox(
                    width: 30.0 + (myPets.length - 1) * 20,
                    height: 30,
                    child: Stack(
                      children: [
                        for (var i = 0; i < myPets.length; i++)
                          Positioned(left: i * 20.0, child: LPAvatar(myPets[i].photo, size: 30, ring: true)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Pour ${myPets.map((p) => p.name).join(', ')}', style: LPText.h3)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 274,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: LP.pagePadding,
                itemCount: recommended.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => SizedBox(
                  width: 168,
                  child: ProductCard(product: recommended[i], onAdd: () => vm.addToCart(recommended[i])),
                ).from(y: 24, scale: 0.92, delay: stagger(i, start: 0.25, each: 0.07), ease: Ease.backOutSoft),
              ),
            ),
          ],

          // Grille de produits
          const SizedBox(height: 22),
          Padding(
            padding: LP.pagePadding,
            child: Row(
              children: [
                Expanded(child: Text(vm.gridTitle, style: LPText.h3)),
                Text('${items.length} produit${items.length > 1 ? 's' : ''}', style: LPText.bodyS),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(PhosphorIconsRegular.magnifyingGlass, size: 40, color: LP.faint),
                  const SizedBox(height: 10),
                  Text('Aucun produit ne correspond.', style: LPText.title),
                  TextButton(onPressed: vm.clearFilters, child: const Text('Effacer les filtres')),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: LayoutBuilder(
                builder: (context, c) {
                  final w = (c.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < items.length; i++)
                        SizedBox(
                          width: w,
                          child: ProductCard(product: items[i], onAdd: () => vm.addToCart(items[i])),
                        ).from(
                          key: ValueKey('${items[i].id}${vm.species}${vm.category}'),
                          y: 26,
                          delay: stagger(i, start: 0.05, each: 0.05),
                        ),
                    ],
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Produits et marques fictifs, pour l\'exemple.',
            textAlign: TextAlign.center,
            style: LPText.bodyS.copyWith(fontSize: 12.5, color: LP.faint),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.icon, required this.on, required this.onTap});
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: on,
        child: PressScale(
          child: GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: on ? LP.mint : LP.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: on ? LP.primary : LP.softDeep, width: on ? 1.6 : 1.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: on ? LP.primary : LP.muted),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: LPText.body(size: 14, w: FontWeight.w700, color: on ? LP.primaryDark : LP.ink),
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: LP.pagePadding,
      height: 132,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: LP.night, borderRadius: BorderRadius.circular(LP.r28)),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -34,
            width: 150,
            height: 150,
            child: Transform.rotate(
              angle: -0.35,
              child: CustomPaint(
                painter: BigShapePainter(BigShape.paw, color: LP.accent, cutout: LP.night),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 120, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Pill(label: 'Livraison', bg: LP.accent, fg: LP.primaryDark, icon: PhosphorIconsBold.truck),
                const SizedBox(height: 10),
                Text(
                  'Offerte dès 80 DT',
                  style: LPText.display(size: 22, color: LP.white, w: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text('Tunis, Sousse, Sfax · en 24 à 48 h', style: LPText.body(size: 13, color: LP.onNightMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ————————————————————————————————————————————— Carte produit

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onAdd});
  final Product product;

  /// Ajout au panier (fourni par le ViewModel de l'écran qui affiche la carte).
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Semantics(
      button: true,
      label: '${p.name}, ${p.brand}, ${p.price} dinars',
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
            onTap: () => Navigator.pushNamed(context, R.product, arguments: p),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, c) => Stack(
                      children: [
                        ProductArt(p, size: c.maxWidth, radius: 18),
                        if (p.badge != null)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: Pill(
                              label: p.badge!,
                              bg: p.oldPrice != null ? LP.accent : LP.white,
                              fg: LP.primaryDark,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.brand, style: LPText.bodyS.copyWith(fontSize: 12)),
                        Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: LPText.body(size: 14, w: FontWeight.w700, height: 1.25),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: _dt(p.price), style: LPText.price.copyWith(fontSize: 16)),
                                    if (p.oldPrice != null)
                                      TextSpan(
                                        text: '  ${_dt(p.oldPrice!)}',
                                        style: LPText.bodyS.copyWith(
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            _AddButton(product: p, onAdd: onAdd),
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
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.product, required this.onAdd});
  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ajouter au panier',
      child: PressScale(
        child: Material(
          color: LP.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              onAdd();
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('${product.name} ajouté au panier'),
                    action: SnackBarAction(
                      label: 'Voir',
                      textColor: LP.accent,
                      onPressed: () => Navigator.pushNamed(context, R.cart),
                    ),
                  ),
                );
            },
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(PhosphorIconsBold.plus, size: 17, color: LP.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— FICHE PRODUIT

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final vm = ProductViewModel(widget.product, Deps.of(context).cart);

  Product get p => vm.product;

  void _add() {
    vm.addToCart();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${vm.qty} × ${p.name} ajouté${vm.qty > 1 ? 's' : ''} au panier'),
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: LP.accent,
            onPressed: () => Navigator.pushNamed(context, R.cart),
          ),
        ),
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
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Visuel
          Container(
            decoration: BoxDecoration(
              color: p.tint,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Row(
                      children: [
                        RoundIconButton(
                          PhosphorIconsRegular.caretLeft,
                          bg: LP.white,
                          tooltip: 'Retour',
                          onTap: () => Navigator.maybePop(context),
                        ),
                        const Spacer(),
                        BounceOnChange(
                          value: vm.favorite,
                          child: RoundIconButton(
                            vm.favorite ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                            bg: LP.white,
                            fg: vm.favorite ? LP.error : LP.ink,
                            tooltip: 'Favori',
                            onTap: vm.toggleFavorite,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CartButton(),
                      ],
                    ),
                  ),
                  ProductArt(
                    p,
                    size: 250,
                    showBg: false,
                  ).from(scale: 0.6, y: 30, duration: 0.9, ease: Ease.backOutSoft),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (p.badge != null) Pill(label: p.badge!, bg: LP.accentSoft, fg: LP.accentInk),
                    Pill(label: p.category.label, bg: LP.mintPale, fg: LP.primary, icon: p.category.icon),
                    for (final s in p.species) Pill(label: s.plural, bg: LP.soft, fg: LP.ink, icon: s.icon),
                  ],
                ).from(y: 14, delay: 0.15),
                const SizedBox(height: 12),
                Text(p.name, style: LPText.h2).from(y: 16, delay: 0.2),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(p.brand, style: LPText.label.copyWith(color: LP.muted)),
                    const SizedBox(width: 10),
                    RatingLine(p.rating, p.reviews),
                  ],
                ).from(y: 16, delay: 0.24),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CountUp(vm.option.price, suffix: ' DT', style: LPText.display(size: 30)),
                    if (vm.showOldPrice) ...[
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _dt(p.oldPrice!),
                          style: LPText.bodyM.copyWith(color: LP.muted, decoration: TextDecoration.lineThrough),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                Text(vm.optionTitle, style: LPText.label),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final o in p.options)
                      ChoiceChip(
                        label: Text('${o.label} · ${_dt(o.price)}'),
                        selected: o == vm.option,
                        showCheckmark: false,
                        onSelected: (_) => vm.setOption(o),
                        labelStyle: LPText.body(
                          size: 14,
                          w: FontWeight.w700,
                          color: o == vm.option ? LP.white : LP.ink,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Text('Quantité', style: LPText.label)),
                    Counter(value: vm.qty, min: 1, max: 20, onChanged: vm.setQty),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Description', style: LPText.h3),
                const SizedBox(height: 8),
                Text(p.description, style: LPText.bodyM.copyWith(height: 1.55)),
                const SizedBox(height: 18),
                for (final e in p.details.entries) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 110, child: Text(e.key, style: LPText.bodyS)),
                        Expanded(
                          child: Text(e.value, style: LPText.bodyM.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                ],
                const SizedBox(height: 18),
                for (final (icon, text) in const [
                  (PhosphorIconsRegular.truck, 'Livraison en 24 à 48 h à Tunis, Sousse et Sfax'),
                  (PhosphorIconsRegular.money, 'Paiement à la livraison ou par carte'),
                  (PhosphorIconsRegular.arrowCounterClockwise, 'Retour gratuit sous 14 jours'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
                          child: Icon(icon, size: 18, color: LP.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(text, style: LPText.bodyM)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: LPText.bodyS),
                CountUp(vm.total, suffix: ' DT', style: LPText.price.copyWith(fontSize: 21)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PawButton(label: 'Ajouter au panier', icon: PhosphorIconsFill.shoppingBag, onPressed: _add),
            ),
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— PANIER

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, this.preview});

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final vm = CartViewModel(widget.preview == 'empty' ? CartRepository(demo: false) : Deps.of(context).cart);

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  Future<void> _order() async {
    final (total, count) = await vm.order();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, R.orderDone, arguments: (total, count));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final cart = vm;
        final missing = vm.missingForFreeShipping;
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(cart.count == 0 ? 'Panier' : 'Panier · ${cart.count} article${cart.count > 1 ? 's' : ''}'),
          ),
          body: cart.lines.isEmpty
              ? _empty(context)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    for (var i = 0; i < cart.lines.length; i++) ...[
                      _line(cart, cart.lines[i]).from(key: ValueKey(cart.lines[i]), x: 30, delay: stagger(i)),
                      const Divider(),
                    ],
                    const SizedBox(height: 16),
                    // Progression vers la livraison offerte
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: LP.mintPale, borderRadius: BorderRadius.circular(LP.r16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(PhosphorIconsRegular.truck, size: 18, color: LP.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  missing > 0
                                      ? 'Plus que ${_dt(missing)} pour la livraison offerte'
                                      : 'La livraison est offerte !',
                                  style: LPText.label.copyWith(color: LP.primaryDark),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: vm.freeShippingProgress),
                              duration: const Duration(milliseconds: 600),
                              curve: Ease.power3Out,
                              builder: (_, v, _) => LinearProgressIndicator(
                                value: v,
                                minHeight: 7,
                                backgroundColor: LP.white,
                                color: LP.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text('Livraison', style: LPText.h3),
                    const SizedBox(height: 6),
                    LPListTile(
                      icon: PhosphorIconsRegular.mapPin,
                      title: 'Rue du Lac Biwa, La Marsa',
                      subtitle: 'Mar. ou mer. · 9 h – 18 h',
                      trailing: Text('Modifier', style: LPText.label.copyWith(color: LP.primary)),
                    ),
                    const SizedBox(height: 18),
                    Text('Paiement', style: LPText.h3),
                    const SizedBox(height: 6),
                    RadioGroup<String>(
                      groupValue: vm.payment,
                      onChanged: (v) => vm.setPayment(v ?? 'cash'),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: 'cash',
                            title: Text('Paiement à la livraison', style: LPText.bodyL),
                            subtitle: Text('En espèces, au livreur', style: LPText.bodyS),
                            secondary: const Icon(PhosphorIconsRegular.money, color: LP.primary),
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: 'card',
                            title: Text('Carte bancaire', style: LPText.bodyL),
                            subtitle: Text('Paiement sécurisé', style: LPText.bodyS),
                            secondary: const Icon(PhosphorIconsRegular.creditCard, color: LP.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(LP.r20)),
                      child: Column(
                        children: [
                          _sum('Sous-total', _dt(cart.subtotal)),
                          _sum('Livraison', cart.shipping == 0 ? 'Offerte' : _dt(cart.shipping)),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: LP.softDeep),
                          ),
                          Row(
                            children: [
                              Expanded(child: Text('Total', style: LPText.title)),
                              CountUp(cart.total, suffix: ' DT', style: LPText.display(size: 26)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Produits et marques fictifs, pour l\'exemple.',
                      textAlign: TextAlign.center,
                      style: LPText.bodyS.copyWith(fontSize: 12.5, color: LP.faint),
                    ),
                  ],
                ),
          bottomNavigationBar: cart.lines.isEmpty
              ? null
              : BottomActionBar(
                  child: PawButton(label: 'Commander · ${_dt(cart.total)}', loading: vm.ordering, onPressed: _order),
                ),
        );
      },
    );
  }

  Widget _line(CartViewModel cart, CartLine l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, R.product, arguments: l.product),
            child: ProductArt(l.product, size: 78, radius: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: LPText.label),
                Text('${l.product.brand} · ${l.option.label}', style: LPText.bodyS.copyWith(fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(_dt(l.total), style: LPText.price.copyWith(fontSize: 16)),
              ],
            ),
          ),
          Column(
            children: [
              Counter(value: l.qty, min: 0, max: 20, onChanged: (v) => cart.setQty(l, v)),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: LP.muted, minimumSize: const Size(0, 32)),
                onPressed: () => cart.setQty(l, 0),
                icon: const Icon(PhosphorIconsRegular.trash, size: 15),
                label: Text('Retirer', style: LPText.bodyS.copyWith(fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sum(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(child: Text(l, style: LPText.bodyM)),
        Text(v, style: LPText.label.copyWith(fontSize: 15)),
      ],
    ),
  );

  Widget _empty(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
          child: const Icon(PhosphorIconsRegular.shoppingBag, size: 42, color: LP.primary),
        ).from(scale: 0.4, duration: 0.8, ease: Ease.backOut),
        const SizedBox(height: 18),
        Text('Votre panier est vide', style: LPText.h2),
        const SizedBox(height: 8),
        Text(
          'Croquettes, litière, jouets : tout ce qu\'il faut pour vos compagnons.',
          textAlign: TextAlign.center,
          style: LPText.bodyM.copyWith(color: LP.muted),
        ),
        const SizedBox(height: 22),
        PawButton(
          label: 'Découvrir la boutique',
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, R.shop, (r) => r.settings.name == R.catalog),
        ),
      ],
    ),
  );
}

// ————————————————————————————————————————————— COMMANDE CONFIRMÉE

class OrderDoneScreen extends StatelessWidget {
  const OrderDoneScreen({super.key, this.total = 77, this.count = 3});
  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Commande confirmée', 'Aujourd\'hui, 18:42', true),
      ('En préparation', 'Notre entrepôt de Tunis', false),
      ('En route', 'Le livreur vous appelle avant de passer', false),
      ('Livrée', 'Mardi 20 octobre', false),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Fermer',
          icon: const Icon(PhosphorIconsRegular.x),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: LP.primary, shape: BoxShape.circle),
              child: const Icon(PhosphorIconsBold.check, size: 44, color: LP.accent),
            ).from(scale: 0.2, rotation: -30, duration: 1.1, ease: Ease.elasticOut),
          ),
          const SizedBox(height: 20),
          Text('Commande confirmée', textAlign: TextAlign.center, style: LPText.h1).from(y: 20, delay: 0.15),
          const SizedBox(height: 8),
          Text(
            'Commande n° PS-10482 · $count article${count > 1 ? 's' : ''} · ${_dt(total)}\nLivraison prévue mardi 20 octobre à La Marsa.',
            textAlign: TextAlign.center,
            style: LPText.bodyM.copyWith(color: LP.muted),
          ).from(y: 20, delay: 0.22),
          const SizedBox(height: 28),
          for (var i = 0; i < steps.length; i++)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: steps[i].$3 ? LP.primary : LP.bg,
                          shape: BoxShape.circle,
                          border: steps[i].$3 ? null : Border.all(color: LP.softDeep, width: 2),
                        ),
                        child: steps[i].$3 ? const Icon(PhosphorIconsBold.check, size: 14, color: LP.white) : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: LP.softDeep,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            steps[i].$1,
                            style: LPText.body(
                              size: 15.5,
                              w: steps[i].$3 ? FontWeight.w800 : FontWeight.w600,
                              color: steps[i].$3 ? LP.ink : LP.muted,
                              height: 1.2,
                            ),
                          ),
                          Text(steps[i].$2, style: LPText.bodyS),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).from(x: 24, delay: stagger(i, start: 0.3, each: 0.1)),
          const SizedBox(height: 18),
          PawButton(
            label: 'Retour à la boutique',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, R.shop, (r) => r.settings.name == R.catalog),
          ),
        ],
      ),
    );
  }
}
