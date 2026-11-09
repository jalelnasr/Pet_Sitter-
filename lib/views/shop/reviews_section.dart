import 'package:flutter/material.dart';

import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/reviews_view_model.dart';

/// Section « Avis » de la fiche produit.
class ProductReviewsSection extends StatelessWidget {
  const ProductReviewsSection({super.key, required this.vm});
  final ProductReviewsViewModel vm;

  void _toast(BuildContext context, String? failure) {
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  Future<void> _edit(BuildContext context) async {
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReviewSheet(initial: vm.mine),
    );
    if (result == null) return;
    final failure = await vm.save(result.$1, result.$2);
    if (context.mounted) _toast(context, failure);
  }

  Future<void> _confirmDelete(BuildContext context, String title, Future<String?> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await action();
    if (context.mounted) _toast(context, failure);
  }

  @override
  Widget build(BuildContext context) {
    if (!vm.enabled) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text('Avis des clients', style: LPText.h3)),
              if (vm.count > 0) RatingLine(vm.average, vm.count),
            ],
          ),
          const SizedBox(height: 8),
          if (vm.loading && vm.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(color: LP.primary)),
            )
          else if (vm.error != null) ...[
            Text(vm.error!, style: LPText.bodyS),
            TextButton(onPressed: vm.load, child: const Text('Réessayer')),
          ] else ...[
            if (vm.items.isEmpty) Text('Aucun avis pour l\'instant.', style: LPText.bodyS),
            for (final r in vm.items) _tile(context, r),
            const SizedBox(height: 8),
            if (vm.canReview)
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: vm.saving ? null : () => _edit(context),
                    child: Text(vm.mine == null ? 'Donner mon avis' : 'Modifier mon avis'),
                  ),
                  if (vm.mine != null)
                    TextButton(
                      onPressed: vm.saving
                          ? null
                          : () => _confirmDelete(context, 'Supprimer votre avis ?', vm.removeMine),
                      child: const Text('Supprimer'),
                    ),
                ],
              )
            else if (!vm.isAdmin)
              Text('Seuls les clients qui ont reçu ce produit peuvent donner leur avis.', style: LPText.bodyS),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, ProductReview r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(r.author, style: LPText.label)),
              _Stars(r.rating),
              if (vm.isAdmin)
                IconButton(
                  tooltip: 'Supprimer cet avis',
                  icon: const Icon(PhosphorIconsRegular.trash, size: 18),
                  onPressed: vm.saving
                      ? null
                      : () => _confirmDelete(context, 'Supprimer cet avis ?', () => vm.moderate(r)),
                ),
            ],
          ),
          Text(frDate(r.date, weekday: false), style: LPText.bodyS.copyWith(fontSize: 12.5)),
          if (r.comment != null) ...[const SizedBox(height: 4), Text(r.comment!, style: LPText.bodyM)],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.rating);
  final int rating;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$rating sur 5',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
            size: 15,
            color: i <= rating ? LP.accent : LP.faint,
          ),
      ],
    ),
  );
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({this.initial});
  final ProductReview? initial;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.initial?.rating ?? 0;
  late final _comment = TextEditingController(text: widget.initial?.comment);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Votre avis', style: LPText.h3),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i sur 5',
                  icon: Icon(
                    i <= _rating ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                    color: i <= _rating ? LP.accent : LP.faint,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _rating = i),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _comment,
            maxLength: 1000,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Commentaire (facultatif)'),
          ),
          const SizedBox(height: 12),
          PawButton(
            label: 'Publier mon avis',
            onPressed: _rating == 0 ? null : () => Navigator.pop(context, (_rating, _comment.text)),
          ),
        ],
      ),
    );
  }
}
