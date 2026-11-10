import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/core/widgets/floating_nav.dart';
import 'package:pet_sitter/core/widgets/product_art.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/admin_view_model.dart';
import 'package:pet_sitter/view_models/reviews_view_model.dart';
import 'package:pet_sitter/views/admin/sales_tab.dart';
import 'package:pet_sitter/views/shop/orders_screens.dart';
import 'package:pet_sitter/views/shop/reviews_section.dart';

String _dt(int v) => '$v DT';

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Administration de la boutique : Commandes, Produits, Ventes.
/// Ouverte depuis les actions de la boutique ou le profil d'un administrateur.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, this.initialTab = 0});

  /// 0 : commandes, 1 : produits, 2 : ventes.
  final int initialTab;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  late int _tab = widget.initialTab;

  static const _items = [
    NavItem(PhosphorIconsRegular.shoppingBag, PhosphorIconsFill.shoppingBag, 'Commandes'),
    NavItem(PhosphorIconsRegular.storefront, PhosphorIconsFill.storefront, 'Produits'),
    NavItem(PhosphorIconsRegular.chartBar, PhosphorIconsRegular.chartBar, 'Ventes'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(leading: const BackButton(), title: const Text('Espace admin')),
      body: KeyedSubtree(
        key: ValueKey(_tab),
        child: switch (_tab) {
          0 => const _OrdersTab(),
          1 => const _ProductsTab(),
          _ => const SalesTab(),
        },
      ),
      bottomNavigationBar: FloatingNav(items: _items, index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

Widget _errorView(String message, VoidCallback onRetry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center, style: LPText.title),
        TextButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    ),
  ),
);

// ————————————————————————————————————————————— COMMANDES

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminOrdersViewModel>(
      create: (context) => AdminOrdersViewModel(Deps.of(context).admin),
      builder: (context, vm) => Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Toutes'),
                    selected: vm.filter == null,
                    onSelected: (_) => vm.setFilter(null),
                  ),
                ),
                for (final s in OrderStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s.label),
                      selected: vm.filter == s,
                      onSelected: (_) => vm.setFilter(s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _list(context, vm)),
        ],
      ),
    );
  }

  Widget _list(BuildContext context, AdminOrdersViewModel vm) {
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: LP.primary));
    }
    if (vm.error != null) return _errorView(vm.error!, vm.load);
    if (vm.items.isEmpty) return Center(child: Text('Aucune commande.', style: LPText.title));
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
        itemCount: vm.items.length,
        separatorBuilder: (_, _) => const Divider(height: 28),
        itemBuilder: (context, i) => _orderTile(context, vm, vm.items[i]),
      ),
    );
  }

  Future<void> _change(BuildContext context, AdminOrdersViewModel vm, Order o, OrderStatus next) async {
    if (next == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Annuler ${o.number} ?'),
          content: const Text('Les articles seront remis en stock. Cette action est définitive.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Annuler la commande')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final failure = await vm.setStatus(o, next);
    if (failure != null && context.mounted) _toast(context, failure);
  }

  Widget _orderTile(BuildContext context, AdminOrdersViewModel vm, Order o) {
    final busy = vm.updating == o.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('${o.number} · ${_dt(o.total)}', style: LPText.title)),
            OrderStatusPill(o.status),
          ],
        ),
        const SizedBox(height: 4),
        Text('${frDate(o.createdAt)} · ${o.paid ? 'payée' : 'paiement à la livraison'}', style: LPText.bodyS),
        const SizedBox(height: 6),
        Text(
          '${o.delivery.recipient} · ${o.delivery.phone}\n${o.delivery.address}, ${o.delivery.city}',
          style: LPText.bodyM,
        ),
        const SizedBox(height: 6),
        for (final l in o.lines) Text('${l.quantity} × ${l.productName} · ${l.optionLabel}', style: LPText.bodyS),
        if (o.status.next.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final next in o.status.next)
                next == OrderStatus.cancelled
                    ? OutlinedButton(
                        onPressed: busy ? null : () => _change(context, vm, o, next),
                        child: Text(next.action),
                      )
                    : FilledButton(
                        onPressed: busy ? null : () => _change(context, vm, o, next),
                        child: Text(next.action),
                      ),
            ],
          ),
        ],
      ],
    );
  }
}

// ————————————————————————————————————————————— PRODUITS

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  Future<void> _open(BuildContext context, AdminProductsViewModel vm, Product? product) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (changed == true) vm.load();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminProductsViewModel>(
      create: (context) => AdminProductsViewModel(Deps.of(context).admin),
      builder: (context, vm) => Scaffold(
        // Remonté pour rester au-dessus de la barre flottante.
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90),
          child: FloatingActionButton.extended(
            onPressed: () => _open(context, vm, null),
            icon: const Icon(PhosphorIconsBold.plus),
            label: const Text('Ajouter'),
          ),
        ),
        body: _list(context, vm),
      ),
    );
  }

  Widget _list(BuildContext context, AdminProductsViewModel vm) {
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: LP.primary));
    }
    if (vm.error != null) return _errorView(vm.error!, vm.load);
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 170),
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in vm.items)
                    SizedBox(
                      width: w,
                      child: _ProductTile(product: p, onTap: () => _open(context, vm, p)),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.onTap});
  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final stock = p.options.fold(0, (n, o) => n + (o.stock ?? 0));
    return Material(
      color: LP.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: LP.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Opacity(
                      opacity: p.active ? 1 : 0.4,
                      child: ProductArt(p, size: c.maxWidth, radius: 18),
                    ),
                    if (!p.active)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: Pill(label: 'Retiré', bg: LP.soft, fg: LP.muted),
                      )
                    else if (stock == 0)
                      const Positioned(
                        left: 8,
                        top: 8,
                        child: Pill(label: 'Épuisé', bg: LP.accentSoft, fg: LP.accentInk),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LPText.bodyS.copyWith(fontSize: 12),
                    ),
                    Text(
                      p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LPText.body(size: 14, w: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Text('dès ${_dt(p.price)}', style: LPText.price.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('Stock $stock · ${p.reviews} avis', style: LPText.bodyS.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  late final vm = ProductFormViewModel(Deps.of(context).admin, widget.product);

  /// Avis du produit, à lire et à modérer. Un produit retiré de la vente n'en affiche plus.
  late final ProductReviewsViewModel? reviews = widget.product?.active == true
      ? ProductReviewsViewModel(Deps.of(context).reviews, Deps.of(context).session, widget.product!.id)
      : null;
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    reviews?.dispose();
    vm.dispose();
    super.dispose();
  }

  static String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Champ obligatoire.' : null;

  static String? _positive(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n <= 0) ? 'Nombre entier positif.' : null;
  }

  static String? _zeroOrMore(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 0) ? 'Nombre entier.' : null;
  }

  static String? _optionalPositive(String? v) => (v == null || v.trim().isEmpty) ? null : _positive(v);

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final failure = vm.setImage(bytes, file.name);
    if (failure != null && mounted) _toast(context, failure);
  }

  Widget _photo(Product? p) {
    final picked = vm.pickedImage;
    return Row(
      children: [
        if (picked != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(picked, width: 96, height: 96, fit: BoxFit.cover),
          )
        else if (p != null)
          ProductArt(p, size: 96, radius: 16)
        else
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: LP.soft, borderRadius: BorderRadius.circular(16)),
            child: const Icon(PhosphorIconsRegular.shoppingBag, color: LP.faint),
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo du produit', style: LPText.label),
              Text('JPG, PNG ou WebP, 5 Mo maximum', style: LPText.bodyS),
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: vm.saving ? null : _pickPhoto,
                child: Text(picked != null || vm.imageUrl != null ? 'Changer la photo' : 'Choisir une photo'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final failure = await vm.save();
    if (!mounted) return;
    if (failure != null) {
      _toast(context, failure);
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer de la vente ?'),
        content: const Text('Le produit disparaît de la boutique, mais reste dans l\'historique des commandes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Retirer')),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await vm.remove();
    if (!mounted) return;
    if (failure != null) {
      _toast(context, failure);
    } else {
      Navigator.pop(context, true);
    }
  }

  Widget _text(
    String label,
    String initial,
    ValueChanged<String> onChanged, {
    String? Function(String?)? validator,
    int lines = 1,
    bool digits = false,
  }) {
    return TextFormField(
      initialValue: initial,
      minLines: lines,
      maxLines: lines,
      keyboardType: digits ? TextInputType.number : null,
      inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final p = widget.product;
        final saveLabel = vm.isNew
            ? 'Créer le produit'
            : (p!.active ? 'Enregistrer' : 'Enregistrer et remettre en vente');
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(vm.isNew ? 'Nouveau produit' : 'Modifier le produit'),
          ),
          bottomNavigationBar: BottomActionBar(
            child: PawButton(label: saveLabel, loading: vm.saving, onPressed: vm.saving ? null : _save),
          ),
          body: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _photo(p),
                const SizedBox(height: 16),
                _text('Nom', vm.name, (v) => vm.name = v, validator: _required),
                const SizedBox(height: 12),
                _text('Marque', vm.brand, (v) => vm.brand = v, validator: _required),
                const SizedBox(height: 12),
                _text('Description', vm.description, (v) => vm.description = v, validator: _required, lines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<ShopCategory>(
                  initialValue: vm.category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [for (final c in ShopCategory.values) DropdownMenuItem(value: c, child: Text(c.label))],
                  onChanged: (c) => vm.setCategory(c!),
                ),
                const SizedBox(height: 16),
                Text('Espèces', style: LPText.label),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in Species.values)
                      FilterChip(
                        label: Text(s.plural),
                        selected: vm.species.contains(s),
                        onSelected: (_) => vm.toggleSpecies(s),
                        // Texte blanc sur la pastille verte quand l'espèce est cochée, sinon il est illisible.
                        checkmarkColor: LP.white,
                        labelStyle: LPText.body(
                          size: 14,
                          w: FontWeight.w600,
                          color: vm.species.contains(s) ? LP.white : LP.ink,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Text('Formats, prix et stock', style: LPText.h3)),
                    TextButton(onPressed: vm.addOption, child: const Text('Ajouter')),
                  ],
                ),
                for (final o in vm.options)
                  Padding(
                    key: ObjectKey(o),
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _text('Format', o.label, (v) => o.label = v, validator: _required)),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _text('Prix', o.price, (v) => o.price = v, validator: _positive, digits: true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _text('Stock', o.stock, (v) => o.stock = v, validator: _zeroOrMore, digits: true),
                        ),
                        IconButton(
                          tooltip: 'Supprimer ce format',
                          icon: const Icon(PhosphorIconsRegular.x, size: 18),
                          onPressed: vm.options.length > 1 ? () => vm.removeOption(o) : null,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Text('Caractéristiques', style: LPText.h3)),
                    TextButton(onPressed: vm.addDetail, child: const Text('Ajouter')),
                  ],
                ),
                for (final d in vm.details)
                  Padding(
                    key: ObjectKey(d),
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _text('Nom', d.label, (v) => d.label = v, validator: _required)),
                        const SizedBox(width: 8),
                        Expanded(flex: 3, child: _text('Valeur', d.value, (v) => d.value = v, validator: _required)),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(PhosphorIconsRegular.x, size: 18),
                          onPressed: () => vm.removeDetail(d),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Text('Promotion', style: LPText.h3),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _text(
                        'Ancien prix DT',
                        vm.oldPrice,
                        (v) => vm.oldPrice = v,
                        validator: _optionalPositive,
                        digits: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _text('Badge', vm.badge, (v) => vm.badge = v)),
                  ],
                ),
                if (reviews != null) ProductReviewsSection(vm: reviews!),
                if (!vm.isNew && p!.active) ...[
                  const SizedBox(height: 28),
                  OutlinedButton(onPressed: vm.saving ? null : _remove, child: const Text('Retirer de la vente')),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
