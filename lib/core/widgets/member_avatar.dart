import 'package:flutter/material.dart';
import 'package:pet_sitter/core/theme/app_theme.dart';
import 'package:pet_sitter/core/widgets/common.dart';

/// Photo ronde d'un membre ; sans photo, ses initiales sur fond menthe.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.photo, required this.name, this.size = 48});

  final String photo;
  final String name;
  final double size;

  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (photo.trim().isNotEmpty) return LPAvatar(photo, size: size);
    return Semantics(
      label: name,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: LP.mint, shape: BoxShape.circle),
        child: Text(
          initialsOf(name),
          style: LPText.display(size: size * 0.36, color: LP.primaryDark, w: FontWeight.w800),
        ),
      ),
    );
  }
}
