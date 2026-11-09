import 'package:flutter/material.dart';

import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/view_models/admin_view_model.dart';

/// 12345 -> « 12 345 » : espace des milliers, comme en français.
String _thousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return b.toString();
}

String _dt(int v) => '${_thousands(v)} DT';

/// Résumé des ventes : chiffres calculés par le serveur, commentaire rédigé par l'IA.
class SalesTab extends StatelessWidget {
  const SalesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AdminSalesViewModel>(
      create: (context) => AdminSalesViewModel(Deps.of(context).admin, analysis: Deps.of(context).salesAnalysis),
      builder: (context, vm) => RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
          children: [
            Row(
              children: [
                for (final d in AdminSalesViewModel.periods)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$d jours'),
                      selected: vm.days == d,
                      onSelected: (_) => vm.setDays(d),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._body(context, vm),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context, AdminSalesViewModel vm) {
    final s = vm.summary;
    if (vm.loading && s == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: LP.primary)),
        ),
      ];
    }
    if (vm.error != null) {
      return [Text(vm.error!, style: LPText.title), TextButton(onPressed: vm.load, child: const Text('Réessayer'))];
    }
    if (s == null) return const [];
    final change = s.changePercent;
    return [
      LayoutBuilder(
        builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: w,
                child: _StatTile(
                  label: 'Chiffre d\'affaires',
                  value: _dt(s.revenue),
                  delta: change == null
                      ? 'Rien à comparer'
                      : '${change > 0
                            ? '↑ +'
                            : change < 0
                            ? '↓ '
                            : ''}$change % vs ${s.days} jours précédents',
                  deltaColor: change == null || change == 0
                      ? LP.muted
                      : change > 0
                      ? LP.primary
                      : LP.error,
                ),
              ),
              SizedBox(
                width: w,
                child: _StatTile(label: 'Commandes', value: _thousands(s.orders), delta: '${s.itemsSold} articles'),
              ),
              SizedBox(
                width: w,
                child: _StatTile(label: 'Panier moyen', value: _dt(s.averageBasket)),
              ),
              SizedBox(
                width: w,
                child: _StatTile(label: 'Annulées', value: _thousands(s.cancelled)),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      _CommentaryCard(vm: vm),
      const SizedBox(height: 22),
      Text('Les plus vendus', style: LPText.h3),
      const SizedBox(height: 6),
      if (s.topProducts.isEmpty) Text('Aucune vente sur la période.', style: LPText.bodyS),
      for (final (i, p) in s.topProducts.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text('${i + 1}', style: LPText.label.copyWith(color: LP.muted)),
              ),
              Expanded(child: Text(p.name, style: LPText.bodyM)),
              Text(
                '${p.quantity} · ${_dt(p.revenue)}',
                style: LPText.label.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      const SizedBox(height: 18),
      Text('Stocks bas', style: LPText.h3),
      const SizedBox(height: 6),
      if (s.lowStock.isEmpty) Text('Aucun format à 5 unités ou moins.', style: LPText.bodyS),
      for (final l in s.lowStock)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.warningCircle, size: 18, color: LP.warning),
              const SizedBox(width: 8),
              Expanded(child: Text('${l.name} · ${l.option}', style: LPText.bodyM)),
              Text(
                l.stock == 0 ? 'Épuisé' : '${l.stock} restant${l.stock > 1 ? 's' : ''}',
                style: LPText.label.copyWith(color: LP.warning),
              ),
            ],
          ),
        ),
    ];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.delta, this.deltaColor = LP.muted});
  final String label;
  final String value;
  final String? delta;
  final Color deltaColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LP.white,
        borderRadius: BorderRadius.circular(LP.r20),
        border: Border.all(color: LP.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: LPText.bodyS),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: LPText.display(size: 24, w: FontWeight.w700)),
          ),
          if (delta != null) ...[
            const SizedBox(height: 2),
            Text(delta!, style: LPText.bodyS.copyWith(fontSize: 12.5, color: deltaColor)),
          ],
        ],
      ),
    );
  }
}

class _CommentaryCard extends StatelessWidget {
  const _CommentaryCard({required this.vm});
  final AdminSalesViewModel vm;

  Widget _text(String summary, List<String> points) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(summary, style: LPText.bodyM),
      for (final p in points)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: LPText.bodyM),
              Expanded(child: Text(p, style: LPText.bodyM)),
            ],
          ),
        ),
    ],
  );

  List<Widget> _content() {
    // Analyse par l'IA externe, appelée depuis l'application
    if (vm.usesAi) {
      if (vm.analyzing) {
        return [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: LP.primary),
              ),
              const SizedBox(width: 10),
              Text('${vm.aiName} analyse vos chiffres…', style: LPText.bodyS),
            ],
          ),
        ];
      }
      final result = vm.analysis;
      if (result != null) {
        return [
          _text(result.summary, result.points),
          const SizedBox(height: 10),
          Text(
            'Rédigé par ${vm.aiName} (API Google) à partir des chiffres ci-dessus : à vérifier.',
            style: LPText.bodyS.copyWith(fontSize: 12),
          ),
        ];
      }
      return [
        Text(vm.analysisError ?? 'Analyse indisponible.', style: LPText.bodyS),
        TextButton(onPressed: vm.analyze, child: const Text('Réessayer')),
      ];
    }
    // Sans clé : commentaire préparé par le serveur
    final s = vm.summary!;
    if (s.commentary == null) return [Text(s.commentaryError ?? 'Analyse indisponible.', style: LPText.bodyS)];
    return [
      _text(s.commentary!, s.points),
      const SizedBox(height: 10),
      Text(
        s.demo
            ? 'Mode démonstration : texte construit sans IA.'
            : 'Rédigé par une IA à partir des chiffres ci-dessus : à vérifier.',
        style: LPText.bodyS.copyWith(fontSize: 12),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LP.mintPale, borderRadius: BorderRadius.circular(LP.r20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.sparkle, size: 18, color: LP.primary),
              const SizedBox(width: 8),
              Text(vm.usesAi ? 'Analyse ${vm.aiName}' : 'Analyse', style: LPText.label.copyWith(color: LP.primaryDark)),
            ],
          ),
          const SizedBox(height: 8),
          ..._content(),
        ],
      ),
    );
  }
}
