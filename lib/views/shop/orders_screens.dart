import 'package:flutter/material.dart';

import 'package:pet_sitter/app/dependencies.dart';
import 'package:pet_sitter/core/mvvm/view_model.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/common.dart';
import 'package:pet_sitter/models/models.dart';
import 'package:pet_sitter/view_models/orders_view_model.dart';

String _dt(int v) => '$v DT';

String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Pastille de statut, partagée avec l'espace admin.
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill(this.status, {super.key});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    OrderStatus.cancelled => Pill(label: status.label, bg: LP.soft, fg: LP.muted),
    OrderStatus.delivered => Pill(label: status.label, bg: LP.primary, fg: LP.white),
    _ => Pill(label: status.label, bg: LP.accentSoft, fg: LP.accentInk),
  };
}

/// Étapes de suivi d'une commande, avec la date de celles déjà franchies.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline(this.order, {super.key});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final steps = order.status == OrderStatus.cancelled
        ? order.history.map((e) => e.status).toList()
        : const [OrderStatus.confirmed, OrderStatus.preparing, OrderStatus.shipped, OrderStatus.delivered];
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Builder(
            builder: (context) {
              final event = order.history.where((e) => e.status == steps[i]).firstOrNull;
              final done = event != null;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: done ? LP.primary : LP.bg,
                            shape: BoxShape.circle,
                            border: done ? null : Border.all(color: LP.softDeep, width: 2),
                          ),
                          child: done ? const Icon(PhosphorIconsBold.check, size: 14, color: LP.white) : null,
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
                        padding: const EdgeInsets.only(bottom: 18, top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              steps[i].label,
                              style: LPText.body(
                                size: 15.5,
                                w: done ? FontWeight.w800 : FontWeight.w600,
                                color: done ? LP.ink : LP.muted,
                                height: 1.2,
                              ),
                            ),
                            if (done) Text('${frDate(event.at)}, ${_time(event.at)}', style: LPText.bodyS),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<MyOrdersViewModel>(
      create: (context) => MyOrdersViewModel(Deps.of(context).orders),
      builder: (context, vm) => Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('Mes commandes')),
        body: _body(context, vm),
      ),
    );
  }

  Widget _body(BuildContext context, MyOrdersViewModel vm) {
    if (vm.loading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: LP.primary));
    }
    if (vm.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!, textAlign: TextAlign.center, style: LPText.title),
              TextButton(onPressed: vm.load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (vm.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.shoppingBag, size: 40, color: LP.faint),
            const SizedBox(height: 10),
            Text('Aucune commande pour l\'instant.', style: LPText.title),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: vm.load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        itemCount: vm.items.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final o = vm.items[i];
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(vm: vm, orderId: o.id),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.number, style: LPText.title),
                        Text(
                          '${frDate(o.createdAt)} · ${o.itemCount} article${o.itemCount > 1 ? 's' : ''} · ${_dt(o.total)}',
                          style: LPText.bodyS,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusPill(o.status),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.vm, required this.orderId});
  final MyOrdersViewModel vm;
  final int orderId;

  Future<void> _cancel(BuildContext context, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annuler ${order.number} ?'),
        content: const Text('Les articles seront remis en stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Garder')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Annuler la commande')),
        ],
      ),
    );
    if (confirmed != true) return;
    final failure = await vm.cancel(order);
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final o = vm.byId(orderId);
        if (o == null) return const Scaffold();
        return Scaffold(
          appBar: AppBar(leading: const BackButton(), title: Text(o.number)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              OrderTimeline(o),
              Text('Articles', style: LPText.h3),
              const SizedBox(height: 8),
              for (final l in o.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text('${l.quantity} × ${l.productName} · ${l.optionLabel}', style: LPText.bodyM)),
                      const SizedBox(width: 8),
                      Text(_dt(l.lineTotal), style: LPText.label),
                    ],
                  ),
                ),
              const Divider(),
              _row('Sous-total', _dt(o.subtotal)),
              _row('Livraison', o.shipping == 0 ? 'Offerte' : _dt(o.shipping)),
              _row('Total', _dt(o.total)),
              _row('Paiement', o.paid ? 'Payée' : 'À la livraison'),
              const SizedBox(height: 18),
              Text('Livraison', style: LPText.h3),
              const SizedBox(height: 8),
              Text(
                '${o.delivery.recipient}\n${o.delivery.address}, ${o.delivery.city}\n${o.delivery.phone}',
                style: LPText.bodyM,
              ),
              if (o.cancellable) ...[
                const SizedBox(height: 24),
                OutlinedButton(onPressed: () => _cancel(context, o), child: const Text('Annuler la commande')),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label, style: LPText.bodyM)),
        Text(value, style: LPText.label),
      ],
    ),
  );
}
