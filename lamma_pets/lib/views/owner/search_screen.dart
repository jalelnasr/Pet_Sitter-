import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';

import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/app/routes.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/view_models/search_view_model.dart';
import 'package:pet_sitter/core/widgets/illustrations.dart';

class SearchResultsScreen extends StatefulWidget {
  const SearchResultsScreen({super.key, this.query, this.forceEmpty = false, this.startOnMap = false, this.preview});
  final SearchQuery? query;

  /// Aperçu d'un état précis (pour les captures du sommaire), sinon null.
  final String? preview;
  final bool forceEmpty;
  final bool startOnMap;

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.preview == 'filters') WidgetsBinding.instance.addPostFrameCallback((_) => _openFilters());
  }

  late final vm = SearchViewModel(
    Deps.of(context).sitters,
    query: widget.query,
    forceEmpty: widget.forceEmpty,
    startOnMap: widget.startOnMap,
  );

  Future<void> _openFilters() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FiltersSheet(vm: vm),
  );

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final results = vm.results;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: LP.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: LP.line),
            ),
            child: Row(
              children: [
                Icon(vm.query.species.icon, size: 20, color: LP.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vm.query.area}, ${vm.query.city}',
                        style: LPText.label.copyWith(fontSize: 14.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${vm.query.datesLabel} · ${vm.query.service.short}',
                        style: LPText.bodyS.copyWith(fontSize: 12.5, height: 1.2),
                      ),
                    ],
                  ),
                ),
                const Icon(PhosphorIconsRegular.pencilSimple, size: 17, color: LP.muted),
              ],
            ),
          ),
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChipBtn(
                  label: vm.filters.activeCount > 0 ? 'Filtres · ${vm.filters.activeCount}' : 'Filtres',
                  icon: PhosphorIconsRegular.slidersHorizontal,
                  active: vm.filters.activeCount > 0,
                  onTap: _openFilters,
                ),
                _FilterChipBtn(
                  label: 'Budget · ${vm.filters.budget.start.round()}–${vm.filters.budget.end.round()} DT',
                  active: vm.filters.budget != const RangeValues(10, 60),
                  onTap: _openFilters,
                ),
                _FilterChipBtn(
                  label: 'Moins de ${vm.filters.distance.round()} km',
                  active: vm.filters.distance != 10,
                  onTap: _openFilters,
                ),
                _FilterChipBtn(label: 'Espèces', active: vm.filters.species.isNotEmpty, onTap: _openFilters),
                _FilterChipBtn(
                  label: 'Disponible sur mes dates',
                  active: vm.filters.allDates,
                  onTap: () => vm.setAllDates(!vm.filters.allDates),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    results.isEmpty
                        ? 'Aucun résultat'
                        : '${results.length} pet sitter${results.length > 1 ? 's' : ''} disponible${results.length > 1 ? 's' : ''}',
                    style: LPText.title,
                  ),
                ),
                if (results.isNotEmpty) _ViewToggle(map: vm.showMap, onChanged: vm.setShowMap),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? _EmptyState(query: vm.query)
                : vm.showMap
                ? _MapView(results: results, service: vm.query.service, selected: vm.selected!.id, onSelect: vm.select)
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: results.length + 1,
                    separatorBuilder: (_, i) =>
                        i == 0 ? const SizedBox.shrink() : const Divider(indent: 20, endIndent: 20),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return const Padding(
                          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: InfoNote(
                            'Profils fictifs présentés à titre d\'exemple.',
                            icon: PhosphorIconsRegular.info,
                            tone: InfoTone.apricot,
                          ),
                        );
                      }
                      final s = results[i - 1];
                      return SitterResultRow(
                        sitter: s,
                        service: vm.query.service,
                        fav: vm.isFavorite(s),
                        onFav: () => vm.toggleFavorite(s),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bascule compacte Liste / Carte.
class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.map, required this.onChanged});
  final bool map;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(bool value, IconData icon, String label) {
      final on = map == value;
      return Semantics(
        selected: on,
        button: true,
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: on ? LP.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: on ? LP.white : LP.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: LPText.body(size: 14, w: FontWeight.w600, color: on ? LP.white : LP.ink, height: 1.1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: LP.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(false, PhosphorIconsRegular.listBullets, 'Liste'),
          seg(true, PhosphorIconsRegular.mapTrifold, 'Carte'),
        ],
      ),
    );
  }
}

class _FilterChipBtn extends StatelessWidget {
  const _FilterChipBtn({required this.label, this.icon, this.active = false, required this.onTap});
  final String label;
  final IconData? icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? LP.primaryDark : LP.white,
        shape: StadiumBorder(side: BorderSide(color: active ? LP.primaryDark : LP.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 17, color: active ? LP.white : LP.ink),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: LPText.body(size: 14, w: FontWeight.w600, color: active ? LP.white : LP.ink),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ligne de résultat : pas de carte, une rangée aérée séparée par un filet.
class SitterResultRow extends StatelessWidget {
  const SitterResultRow({super.key, required this.sitter, required this.service, this.fav = false, this.onFav});
  final Sitter sitter;
  final ServiceType service;
  final bool fav;
  final VoidCallback? onFav;

  @override
  Widget build(BuildContext context) {
    final offer = sitter.services.firstWhere((o) => o.type == service, orElse: () => sitter.mainOffer);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, R.sitter, arguments: sitter),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LPImage(sitter.photo, width: 104, height: 124, radius: LP.r16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(sitter.firstName, style: LPText.title.copyWith(fontSize: 18))),
                      if (sitter.verifications.isNotEmpty) ...[
                        const SizedBox(width: 5),
                        const Tooltip(
                          message: 'Identité vérifiée',
                          child: Icon(PhosphorIconsFill.sealCheck, size: 17, color: LP.primary),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const FictifBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${sitter.area} · ${sitter.distanceKm.toStringAsFixed(1).replaceAll('.', ',')} km',
                    style: LPText.bodyS,
                  ),
                  const SizedBox(height: 8),
                  SpeciesIcons(sitter.species, size: 15),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(offer.type.icon, size: 15, color: LP.muted),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          offer.type.label,
                          style: LPText.bodyS.copyWith(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      PriceTag(offer.price, offer.unit),
                      const Spacer(),
                      if (sitter.hasReviews)
                        RatingLine(sitter.rating!, sitter.reviewCount, compact: true)
                      else
                        const NewSitterTag(),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: fav ? 'Retirer des favoris' : 'Ajouter aux favoris',
              onPressed: onFav,
              icon: Icon(
                fav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                color: fav ? LP.accentInk : LP.muted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ————————————————————————————————————————————— Vue carte

class _MapView extends StatelessWidget {
  const _MapView({required this.results, required this.service, required this.selected, required this.onSelect});
  final List<Sitter> results;
  final ServiceType service;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final sel = results.firstWhere((s) => s.id == selected, orElse: () => results.first);
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            // repère "vous"
            Positioned(
              left: c.maxWidth * 0.58 - 11,
              top: c.maxHeight * 0.36 - 11,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: LP.info,
                  shape: BoxShape.circle,
                  border: Border.all(color: LP.white, width: 4),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
                ),
              ),
            ),
            for (final s in results)
              Positioned(
                left: c.maxWidth * s.mapPos.dx - 36,
                top: c.maxHeight * s.mapPos.dy - 18,
                child: GestureDetector(
                  onTap: () => onSelect(s.id),
                  child: _PricePin(
                    label: '${s.services.firstWhere((o) => o.type == service, orElse: () => s.mainOffer).price} DT',
                    active: s.id == sel.id,
                  ),
                ),
              ),
            Positioned(
              right: 16,
              top: 12,
              child: Column(
                children: [RoundIconButton(PhosphorIconsRegular.crosshair, tooltip: 'Me localiser', bg: LP.white)],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 16,
              child: Material(
                color: LP.bg,
                elevation: 6,
                shadowColor: const Color(0x33000000),
                borderRadius: BorderRadius.circular(LP.r20),
                child: SitterResultRow(sitter: sel, service: service),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PricePin extends StatelessWidget {
  const _PricePin({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: active ? LP.primary : LP.white,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: active ? LP.primary : LP.line),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(
              label,
              style: LPText.body(size: 13.5, w: FontWeight.w700, color: active ? LP.white : LP.ink, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte stylisée du nord de Tunis (illustrative, pas de fournisseur cartographique).
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFF1EBDD));
    // mer (golfe de Tunis)
    final sea = Path()
      ..moveTo(w * 0.80, 0)
      ..cubicTo(w * 0.72, h * 0.2, w * 0.86, h * 0.34, w * 0.80, h * 0.5)
      ..cubicTo(w * 0.76, h * 0.62, w * 0.88, h * 0.74, w * 0.84, h)
      ..lineTo(w, h)
      ..lineTo(w, 0)
      ..close();
    c.drawPath(sea, Paint()..color = LP.water);
    // lac de Tunis
    final lake = Path()..addOval(Rect.fromLTWH(w * 0.30, h * 0.72, w * 0.44, h * 0.2));
    c.drawPath(lake, Paint()..color = LP.water);
    // parcs
    final park = Paint()..color = const Color(0xFFD9E6D3);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.10, w * 0.22, h * 0.12), const Radius.circular(18)),
      park,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.44, h * 0.46, w * 0.16, h * 0.10), const Radius.circular(18)),
      park,
    );
    // routes
    final road = Paint()
      ..color = LP.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final main = Path()
      ..moveTo(0, h * 0.68)
      ..cubicTo(w * 0.3, h * 0.6, w * 0.5, h * 0.42, w * 0.66, h * 0.08);
    c.drawPath(main, road..strokeWidth = 9);
    final second = Path()
      ..moveTo(w * 0.1, h * 0.3)
      ..lineTo(w * 0.74, h * 0.34);
    c.drawPath(second, road..strokeWidth = 6);
    final third = Path()
      ..moveTo(w * 0.42, h)
      ..cubicTo(w * 0.5, h * 0.7, w * 0.62, h * 0.6, w * 0.78, h * 0.55);
    c.drawPath(third, road..strokeWidth = 6);
    for (var i = 1; i < 6; i++) {
      c.drawLine(Offset(w * i * 0.15, h * 0.18), Offset(w * i * 0.13, h * 0.66), road..strokeWidth = 3);
    }
    // libellés
    void label(String t, double x, double y, {bool water = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: LPText.body(
            size: 12,
            w: FontWeight.w600,
            color: water ? LP.info : LP.muted,
            height: 1,
          ).copyWith(letterSpacing: water ? 1.2 : 0.2),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(w * x, h * y));
    }

    label('GAMMARTH', 0.40, 0.08);
    label('LA MARSA', 0.50, 0.24);
    label('SIDI BOU SAÏD', 0.56, 0.44);
    label('CARTHAGE', 0.60, 0.62);
    label('LAC 2', 0.26, 0.54);
    label('LA SOUKRA', 0.06, 0.36);
    label('GOLFE', 0.83, 0.16, water: true);
    label('DE TUNIS', 0.83, 0.19, water: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ————————————————————————————————————————————— État sans résultat

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final SearchQuery query;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const Center(child: EmptyIllustration(size: 132)),
        const SizedBox(height: 20),
        Text(
          'Personne n\'est disponible pour ces critères… pour l\'instant',
          style: LPText.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Aucun sitter n\'accueille de ${query.species.plural.toLowerCase()} près de ${query.area} (${query.city}) sur ces dates. Voici quelques pistes :',
          style: LPText.bodyM.copyWith(color: LP.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _Alt(
          icon: PhosphorIconsRegular.mapPinLine,
          title: 'Élargir la zone à 25 km',
          sub: '3 sitters à Sakiet Ezzit et Sfax centre',
        ),
        _Alt(
          icon: PhosphorIconsRegular.key,
          title: 'Essayer les visites à domicile',
          sub: '2 sitters passent chez vous, dès 14 DT / visite',
        ),
        _Alt(
          icon: PhosphorIconsRegular.calendarDots,
          title: 'Décaler d\'un jour',
          sub: '1 sitter disponible du 24 au 27 oct.',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alerte créée : nous vous prévenons dès qu\'un sitter se libère.')),
          ),
          icon: const Icon(PhosphorIconsRegular.bell, size: 20),
          label: const Text('Me prévenir si un sitter se libère'),
        ),
      ],
    );
  }
}

class _Alt extends StatelessWidget {
  const _Alt({required this.icon, required this.title, required this.sub});
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.pushReplacementNamed(context, R.search),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: LP.mintPale, shape: BoxShape.circle),
                  child: Icon(icon, color: LP.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: LPText.title.copyWith(fontSize: 16)),
                      Text(sub, style: LPText.bodyS),
                    ],
                  ),
                ),
                const Icon(PhosphorIconsRegular.arrowRight, color: LP.primary, size: 20),
              ],
            ),
          ),
        ),
        const Divider(),
      ],
    );
  }
}

// ————————————————————————————————————————————— Filtres

/// Feuille de filtres : elle affiche et modifie les filtres du même ViewModel que la liste.
class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet({required this.vm});
  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: vm, builder: (context, _) => _content(context));

  Widget _content(BuildContext context) {
    final f = vm.filters;
    final unit = vm.query.service.unit;
    final count = vm.results.length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.86,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                Text('Filtres', style: LPText.h2),
                const SizedBox(height: 24),
                _h('Budget par $unit', '${f.budget.start.round()} – ${f.budget.end.round()} DT'),
                RangeSlider(
                  values: f.budget,
                  min: 10,
                  max: 100,
                  divisions: 18,
                  labels: RangeLabels('${f.budget.start.round()} DT', '${f.budget.end.round()} DT'),
                  onChanged: vm.setBudget,
                ),
                const SizedBox(height: 18),
                _h('Distance maximale', '${f.distance.round()} km'),
                Slider(
                  value: f.distance,
                  min: 1,
                  max: 25,
                  divisions: 24,
                  label: '${f.distance.round()} km',
                  onChanged: vm.setDistance,
                ),
                const SizedBox(height: 18),
                _h('Le sitter accepte aussi', null),
                const SizedBox(height: 4),
                Text('Pratique si vous faites garder plusieurs animaux ensemble.', style: LPText.bodyS),
                const SizedBox(height: 12),
                ChoiceGroup(
                  options: [
                    for (final s in Species.values)
                      if (s != vm.query.species) s.plural,
                  ],
                  selected: {for (final s in f.species) s.plural},
                  onTap: (label) => vm.toggleExtraSpecies(Species.values.firstWhere((e) => e.plural == label)),
                ),
                const SizedBox(height: 22),
                _h('Disponibilité', null),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: f.allDates,
                  onChanged: vm.setAllDates,
                  title: Text('Disponible sur toutes mes dates', style: LPText.bodyL),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: f.lastMinute,
                  onChanged: vm.setLastMinute,
                  title: Text('Accepte les demandes de dernière minute', style: LPText.bodyL),
                  subtitle: Text('Moins de 48 h avant le début', style: LPText.bodyS),
                ),
              ],
            ),
          ),
          BottomActionBar(
            child: Row(
              children: [
                TextButton(onPressed: vm.resetFilters, child: const Text('Réinitialiser')),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(count == 0 ? 'Aucun résultat' : 'Voir $count résultat${count > 1 ? 's' : ''}'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _h(String t, String? v) => Row(
    children: [
      Expanded(child: Text(t, style: LPText.title)),
      if (v != null) Text(v, style: LPText.label.copyWith(color: LP.primary)),
    ],
  );
}
