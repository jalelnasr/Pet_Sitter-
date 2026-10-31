import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pet_sitter/core/motion/gsap.dart';

/// Palette Pet Sitter, tirée du logo : vert de la maison, jaune de l'empreinte, crème et blanc.
/// Les couples texte/fond utilisés respectent un contraste AA (≥ 4,5:1).
class LP {
  LP._();

  // Fonds
  static const bg = Color(0xFFFFFFFF); // fond principal
  static const white = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF3F6F5); // zones secondaires, champs
  static const softDeep = Color(0xFFE2E8E6); // séparateurs appuyés, pistes
  static const mintBg = Color(0xFFD2EAD9); // vert doux : cercles photo, aplats
  static const cream = Color(0xFFFFFAF0); // fond du logo : démarrage, guide

  // Couleurs du logo (fixes, indépendantes du thème)
  static const brandGreen = Color(0xFF0F5534);
  static const brandYellow = Color(0xFFFABB24);

  // Noir (actions)
  static const primary = Color(0xFF0F5534); // vert du logo : boutons, sélection — 8,6:1 sur blanc
  static const primaryDark = Color(0xFF093D25);

  // Menthe (accent)
  static const mint = Color(0xFFDFF0E4); // vert clair : sélection douce
  static const mintPale = Color(0xFFEFF7F1); // pastilles d'icône
  static const accent = Color(0xFFFABB24); // jaune de l'empreinte : étoiles, points, détails
  static const accentSoft = Color(0xFFFEF0C7); // jaune pâle : badges, trait du guide
  static const accentInk = Color(0xFF7A5300); // texte jaune lisible — 6,4:1 sur blanc

  // Panneau sombre
  static const night = Color(0xFF0E3B26);
  static const nightSoft = Color(0xFF1B4C35);
  static const nightLine = Color(0xFF537D67);
  static const onNight = Color(0xFFF5F8F4);
  static const onNightMuted = Color(0xFFB7CFC0); // 7,6:1 sur night

  // Texte
  static const ink = Color(0xFF151816); // 17:1
  static const muted = Color(0xFF5C6461); // 6:1
  static const faint = Color(0xFF9AA19E); // décoratif uniquement
  static const line = Color(0xFFE4E9E7);

  // États
  static const error = Color(0xFFB3261E);
  static const errorSoft = Color(0xFFFBE4E1);
  static const warning = Color(0xFF7A5200);
  static const warningSoft = Color(0xFFFFF0CF);
  static const info = Color(0xFF1F5A7A);
  static const infoSoft = Color(0xFFE1EEF5);
  static const water = Color(0xFFCFE8EC);

  // Rayons & espacements
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r28 = 28.0;

  static const pagePadding = EdgeInsets.symmetric(horizontal: 20);
}

/// Typographie : Outfit (titres géométriques, très gras) + Urbanist (texte courant).
class LPText {
  LPText._();

  static TextStyle display({double size = 32, Color color = LP.ink, FontWeight w = FontWeight.w800}) =>
      GoogleFonts.outfit(fontSize: size, fontWeight: w, color: color, height: 1.06, letterSpacing: -0.8);

  static TextStyle body({
    double size = 15,
    Color color = LP.ink,
    FontWeight w = FontWeight.w500,
    double height = 1.45,
  }) => GoogleFonts.urbanist(fontSize: size, fontWeight: w, color: color, height: height);

  static TextStyle get h1 => display(size: 34);
  static TextStyle get h2 => display(size: 25, w: FontWeight.w700);
  static TextStyle get h3 => display(size: 19, w: FontWeight.w700).copyWith(letterSpacing: -0.3);
  static TextStyle get title => body(size: 17, w: FontWeight.w700, height: 1.3);
  static TextStyle get bodyL => body(size: 16);
  static TextStyle get bodyM => body(size: 15);
  static TextStyle get bodyS => body(size: 13.5, color: LP.muted);
  static TextStyle get label => body(size: 14.5, w: FontWeight.w700, height: 1.2);
  static TextStyle get overline =>
      body(size: 12, w: FontWeight.w800, color: LP.muted, height: 1.2).copyWith(letterSpacing: 1);
  static TextStyle get price => display(size: 18, w: FontWeight.w800).copyWith(letterSpacing: -0.3);
}

ThemeData buildPetSitterTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final textTheme = GoogleFonts.urbanistTextTheme(base.textTheme).apply(bodyColor: LP.ink, displayColor: LP.ink);

  const scheme = ColorScheme.light(
    primary: LP.primary,
    onPrimary: LP.white,
    primaryContainer: LP.mint,
    onPrimaryContainer: LP.primaryDark,
    secondary: LP.accent,
    onSecondary: LP.primaryDark,
    secondaryContainer: LP.accentSoft,
    onSecondaryContainer: LP.accentInk,
    surface: LP.bg,
    onSurface: LP.ink,
    surfaceContainerHighest: LP.soft,
    surfaceContainerHigh: LP.soft,
    surfaceContainer: LP.soft,
    surfaceContainerLow: LP.bg,
    surfaceContainerLowest: LP.white,
    outline: LP.line,
    outlineVariant: LP.line,
    error: LP.error,
    onError: LP.white,
  );

  const buttonShape = StadiumBorder();
  const buttonSize = Size(64, 56);
  final buttonText = GoogleFonts.urbanist(fontSize: 16.5, fontWeight: FontWeight.w700);

  OutlineInputBorder border(Color c, [double w = 1.2]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: c, width: w),
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: LP.bg,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: GsapPageTransitionsBuilder(),
        TargetPlatform.iOS: GsapPageTransitionsBuilder(),
        TargetPlatform.macOS: GsapPageTransitionsBuilder(),
        TargetPlatform.windows: GsapPageTransitionsBuilder(),
        TargetPlatform.linux: GsapPageTransitionsBuilder(),
        TargetPlatform.fuchsia: GsapPageTransitionsBuilder(),
      },
    ),
    dividerTheme: const DividerThemeData(color: LP.line, thickness: 1, space: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: LP.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: LP.ink,
      titleTextStyle: LPText.display(size: 21, w: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: LP.primary,
        foregroundColor: LP.white,
        disabledBackgroundColor: LP.softDeep,
        disabledForegroundColor: LP.muted,
        minimumSize: buttonSize,
        shape: buttonShape,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 24),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LP.primary,
        minimumSize: buttonSize,
        shape: buttonShape,
        side: const BorderSide(color: LP.primary, width: 1.5),
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 22),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LP.primary,
        textStyle: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700),
        minimumSize: const Size(48, 44),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LP.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: GoogleFonts.urbanist(color: LP.faint, fontSize: 15.5, fontWeight: FontWeight.w500),
      labelStyle: GoogleFonts.urbanist(color: LP.muted, fontSize: 15.5),
      floatingLabelStyle: GoogleFonts.urbanist(color: LP.primary, fontWeight: FontWeight.w700),
      errorMaxLines: 2,
      helperStyle: GoogleFonts.urbanist(color: LP.muted, fontSize: 13),
      errorStyle: GoogleFonts.urbanist(color: LP.error, fontSize: 13, fontWeight: FontWeight.w600),
      prefixIconColor: LP.muted,
      suffixIconColor: LP.muted,
      border: border(LP.line),
      enabledBorder: border(LP.line),
      focusedBorder: border(LP.primary, 1.8),
      errorBorder: border(LP.error, 1.4),
      focusedErrorBorder: border(LP.error, 2),
      disabledBorder: border(LP.line.withValues(alpha: 0.5)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LP.white,
      selectedColor: LP.primary,
      side: const BorderSide(color: LP.softDeep, width: 1.3),
      labelStyle: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w600, color: LP.ink),
      secondaryLabelStyle: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w700, color: LP.white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      shape: const StadiumBorder(),
      checkmarkColor: LP.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: LP.bg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: LP.mint,
      height: 72,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => GoogleFonts.urbanist(
          fontSize: 12.5,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          color: s.contains(WidgetState.selected) ? LP.primaryDark : LP.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(size: 24, color: s.contains(WidgetState.selected) ? LP.primaryDark : LP.muted),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: LP.primaryDark,
      unselectedLabelColor: LP.muted,
      indicatorColor: LP.primary,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: LP.line,
      labelStyle: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w800),
      unselectedLabelStyle: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? LP.mint : LP.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? LP.primary : LP.soft),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? LP.primary : LP.softDeep,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? LP.primary : Colors.transparent,
      ),
      side: const BorderSide(color: LP.muted, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? LP.primary : LP.muted),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: LP.primary,
      inactiveTrackColor: LP.softDeep,
      thumbColor: LP.primary,
      overlayColor: Color(0x220F5534),
      trackHeight: 4,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: LP.bg,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: LP.softDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(LP.r28))),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: LP.night,
      contentTextStyle: GoogleFonts.urbanist(color: LP.white, fontSize: 15, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: LP.bg,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: LP.mintBg,
      headerForegroundColor: LP.primaryDark,
      rangeSelectionBackgroundColor: LP.mint,
      todayBorder: const BorderSide(color: LP.accent, width: 1.5),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: LP.primary),
  );
}
