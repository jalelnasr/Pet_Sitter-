import 'package:flutter/material.dart';

import 'package:pet_sitter/core/motion/gsap.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';

class NavItem {
  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = false});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool badge;
}

/// Barre de navigation flottante : pilule sombre, onglet actif en pastille blanche avec libellé.
class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.items, required this.index, required this.onTap});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Fondu blanc derrière la barre : le contenu qui défile dessous ne se confond pas avec elle.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LP.bg.withValues(alpha: 0), LP.bg.withValues(alpha: 0.92), LP.bg],
          stops: const [0, 0.45, 1],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 14, top: 26),
        child: Center(
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: LP.night,
              borderRadius: BorderRadius.circular(99),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [for (var i = 0; i < items.length; i++) _item(items[i], i == index, () => onTap(i))],
            ),
          ),
        ).from(y: 90, opacity: 1, delay: 0.25, duration: 0.8, ease: Ease.backOutSoft),
      ),
    );
  }

  Widget _item(NavItem it, bool on, VoidCallback tap) {
    return Semantics(
      selected: on,
      button: true,
      label: it.label,
      excludeSemantics: true,
      child: Tooltip(
        message: it.label,
        child: PressScale(
          child: GestureDetector(
            onTap: tap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Ease.power3Out,
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: on ? 16 : 13),
              decoration: BoxDecoration(
                color: on ? LP.white : Colors.transparent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(on ? it.activeIcon : it.icon, size: 22, color: on ? LP.primary : LP.onNight),
                      if (it.badge && !on)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: LP.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: LP.night, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 380),
                    curve: Ease.power3Out,
                    child: on
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(it.label, style: LPText.body(size: 14, w: FontWeight.w800, height: 1.1)),
                          )
                        : const SizedBox.shrink(),
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
