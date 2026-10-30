import 'package:flutter/material.dart';

import 'package:pet_sitter/core/theme/ph_icons.dart';
import 'package:pet_sitter/core/widgets/floating_nav.dart';
import 'package:pet_sitter/views/account/account_screens.dart';
import 'package:pet_sitter/views/messages/messages_screens.dart';
import 'package:pet_sitter/views/shop/shop_screens.dart';
import 'package:pet_sitter/views/owner/home_screen.dart';

/// Index des onglets propriétaire.
class OwnerTab {
  OwnerTab._();
  static const home = 0;
  static const shop = 1;
  static const bookings = 2;
  static const messages = 3;
  static const account = 4;
}

/// Navigation propriétaire : Accueil, Boutique, Réservations, Messages, Profil.
/// Chaque changement d'onglet reconstruit la page pour rejouer ses animations d'entrée.
class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key, this.initialTab = OwnerTab.home, this.preview});
  final int initialTab;

  /// Aperçu transmis à la page de l'onglet initial (captures du sommaire).
  final String? preview;

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  late int _tab = widget.initialTab;

  String? get _initialPreview => _tab == widget.initialTab ? widget.preview : null;

  static const _items = [
    NavItem(PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Accueil'),
    NavItem(PhosphorIconsRegular.storefront, PhosphorIconsFill.storefront, 'Boutique'),
    NavItem(PhosphorIconsRegular.calendarBlank, PhosphorIconsFill.calendarBlank, 'Réservations'),
    NavItem(PhosphorIconsRegular.chatCircleDots, PhosphorIconsFill.chatCircleDots, 'Messages', badge: true),
    NavItem(PhosphorIconsRegular.userCircle, PhosphorIconsFill.userCircle, 'Profil'),
  ];

  Widget _page() => switch (_tab) {
    OwnerTab.home => OwnerHomeScreen(onOpenShop: () => setState(() => _tab = OwnerTab.shop), preview: _initialPreview),
    OwnerTab.shop => ShopScreen(preview: _initialPreview),
    OwnerTab.bookings => const BookingsScreen(),
    OwnerTab.messages => const MessagesListScreen(),
    _ => const AccountScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: KeyedSubtree(key: ValueKey(_tab), child: _page()),
      bottomNavigationBar: FloatingNav(items: _items, index: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}
