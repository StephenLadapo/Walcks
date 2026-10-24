import 'package:flutter/material.dart';

/// An immutable set of Walcks colours for one [Brightness].
@immutable
class WalcksPalette {
  const WalcksPalette({
    required this.primary,
    required this.primaryLight,
    required this.navy,
    required this.lavender,
    required this.peach,
    required this.background,
    required this.card,
    required this.teal,
    required this.coral,
    required this.blue,
    required this.textMain,
    required this.textSecondary,
    required this.border,
    required this.mintSoft,
    required this.peachSoft,
    required this.blueSoft,
    required this.lavenderSoft,
    required this.toastBackground,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.sidebar,
    required this.cardShadow,
    required this.softShadow,
    required this.buttonShadow,
  });

  final Color primary;
  final Color primaryLight;

  /// Strong text colour on light surfaces (headings, sidebar labels).
  final Color navy;
  final Color lavender;
  final Color peach;
  final Color background;
  final Color card;
  final Color teal;
  final Color coral;
  final Color blue;
  final Color textMain;
  final Color textSecondary;
  final Color border;

  /// Soft tints used by the feature cards.
  final Color mintSoft;
  final Color peachSoft;
  final Color blueSoft;
  final Color lavenderSoft;

  final Color toastBackground;
  final Color heroGradientStart;
  final Color heroGradientEnd;

  /// Background of the sidebar rail and the mobile navigation drawer.
  final Color sidebar;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> softShadow;
  final List<BoxShadow> buttonShadow;

  static const WalcksPalette light = WalcksPalette(
    primary: Color(0xFF6840E8),
    primaryLight: Color(0xFF8B65F5),
    navy: Color(0xFF111638),
    lavender: Color(0xFFF0EDFF),
    peach: Color(0xFFFFF0EC),
    background: Color(0xFFFAF9FD),
    card: Color(0xFFFFFFFF),
    teal: Color(0xFF159E91),
    coral: Color(0xFFF16B50),
    blue: Color(0xFF3978E8),
    textMain: Color(0xFF151832),
    textSecondary: Color(0xFF656782),
    border: Color(0xFFEEEAF5),
    mintSoft: Color(0xFFEAF7F3),
    peachSoft: Color(0xFFFFF0EC),
    blueSoft: Color(0xFFEAF1FE),
    lavenderSoft: Color(0xFFF0EDFF),
    toastBackground: Color(0xFF111638),
    heroGradientStart: Color(0xFFF2EEFF),
    heroGradientEnd: Color(0xFFFFEFE6),
    sidebar: Color(0xFFFCFBFF),
    cardShadow: [
      BoxShadow(
        color: Color(0x146840E8),
        blurRadius: 30,
        offset: Offset(0, 14),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Color(0x0F1E1B4B),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x596840E8),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const WalcksPalette dark = WalcksPalette(
    primary: Color(0xFF8B65F5),
    primaryLight: Color(0xFFA98DFF),
    navy: Color(0xFFEDECF7),
    lavender: Color(0xFF232544),
    peach: Color(0xFF33262B),
    background: Color(0xFF0C0D1A),
    card: Color(0xFF16182C),
    teal: Color(0xFF35C0B0),
    coral: Color(0xFFFF8A70),
    blue: Color(0xFF6FA2FF),
    textMain: Color(0xFFF1F0F9),
    textSecondary: Color(0xFFA2A4C0),
    border: Color(0xFF262941),
    mintSoft: Color(0xFF12302C),
    peachSoft: Color(0xFF33231F),
    blueSoft: Color(0xFF17243E),
    lavenderSoft: Color(0xFF232544),
    toastBackground: Color(0xFF2B2D4A),
    heroGradientStart: Color(0xFF1B1C36),
    heroGradientEnd: Color(0xFF30222F),
    sidebar: Color(0xFF101223),
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 30,
        offset: Offset(0, 14),
      ),
    ],
    softShadow: [
      BoxShadow(
        color: Color(0x4D000000),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
    buttonShadow: [
      BoxShadow(
        color: Color(0x598B65F5),
        blurRadius: 22,
        offset: Offset(0, 12),
      ),
    ],
  );
}

/// Walcks brand colours resolved for the active brightness.
///
/// Call [apply] from the root widget once per build so every `WalcksColors.x`
/// lookup matches the theme currently in use.
class WalcksColors {
  WalcksColors._();

  static WalcksPalette _palette = WalcksPalette.light;

  static WalcksPalette get palette => _palette;

  static void apply(Brightness brightness) {
    _palette =
        brightness == Brightness.dark ? WalcksPalette.dark : WalcksPalette.light;
  }

  static bool get isDark => identical(_palette, WalcksPalette.dark);

  static Color get primary => _palette.primary;
  static Color get primaryLight => _palette.primaryLight;
  static Color get navy => _palette.navy;
  static Color get lavender => _palette.lavender;
  static Color get peach => _palette.peach;
  static Color get background => _palette.background;
  static Color get card => _palette.card;
  static Color get teal => _palette.teal;
  static Color get coral => _palette.coral;
  static Color get blue => _palette.blue;
  static Color get textMain => _palette.textMain;
  static Color get textSecondary => _palette.textSecondary;
  static Color get border => _palette.border;

  static Color get mintSoft => _palette.mintSoft;
  static Color get peachSoft => _palette.peachSoft;
  static Color get blueSoft => _palette.blueSoft;
  static Color get lavenderSoft => _palette.lavenderSoft;

  /// Background of the floating toast/snackbar.
  static Color get toastBackground => _palette.toastBackground;

  /// Background of the sidebar rail and mobile navigation drawer.
  static Color get sidebar => _palette.sidebar;
}

LinearGradient get walcksHeroGradient => LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        WalcksColors.palette.heroGradientStart,
        WalcksColors.palette.heroGradientEnd,
      ],
    );

LinearGradient get walcksPrimaryGradient => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [WalcksColors.primary, WalcksColors.primaryLight],
    );

List<BoxShadow> get walcksCardShadow => WalcksColors.palette.cardShadow;
List<BoxShadow> get walcksSoftShadow => WalcksColors.palette.softShadow;
List<BoxShadow> get walcksButtonShadow => WalcksColors.palette.buttonShadow;

/// Shared text styles (Inter when available, clean sans-serif fallback).
class WalcksText {
  WalcksText._();

  static TextStyle get hero => TextStyle(
        fontSize: 42,
        fontWeight: FontWeight.w800,
        height: 1.12,
        letterSpacing: -0.6,
        color: WalcksColors.navy,
      );

  static TextStyle get sectionTitle => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: WalcksColors.textMain,
      );

  static TextStyle get cardTitle => TextStyle(
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
        color: WalcksColors.textMain,
      );

  static TextStyle get body => TextStyle(
        fontSize: 14.5,
        height: 1.45,
        color: WalcksColors.textSecondary,
      );

  static TextStyle get small => TextStyle(
        fontSize: 13,
        color: WalcksColors.textSecondary,
      );
}

ThemeData buildWalcksTheme(WalcksPalette p, Brightness brightness) {
  final ColorScheme scheme =
      ColorScheme.fromSeed(seedColor: p.primary, brightness: brightness)
          .copyWith(
    primary: p.primary,
    onPrimary: Colors.white,
    secondary: p.primaryLight,
    onSecondary: Colors.white,
    surface: p.card,
    onSurface: p.textMain,
    onSurfaceVariant: p.textSecondary,
    outlineVariant: p.border,
    error: p.coral,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    canvasColor: p.card,
    fontFamily: 'Inter',
    fontFamilyFallback: const ['Roboto', 'Helvetica', 'Arial', 'sans-serif'],
    textTheme: TextTheme(
      headlineMedium: WalcksText.hero,
      titleLarge: WalcksText.sectionTitle,
      titleMedium: WalcksText.cardTitle,
      bodyMedium: WalcksText.body,
      bodySmall: WalcksText.small,
      labelLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: p.textMain,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: p.navy,
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1),
    iconTheme: IconThemeData(color: p.navy),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: p.textSecondary),
      labelStyle: TextStyle(color: p.textSecondary),
      prefixIconColor: p.primary,
      border: _inputBorder(p.border),
      enabledBorder: _inputBorder(p.border),
      focusedBorder: _inputBorder(p.primary, width: 1.6),
      errorBorder: _inputBorder(p.coral),
      focusedErrorBorder: _inputBorder(p.coral, width: 1.6),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(96, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        side: BorderSide(color: p.primary, width: 1.4),
        minimumSize: const Size(96, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.textSecondary,
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.card,
      modalBarrierColor: Colors.black.withValues(alpha: 0.5),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.background,
      selectedColor: p.lavender,
      side: BorderSide(color: p.border),
      labelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: p.textMain,
      ),
      secondaryLabelStyle: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: p.primary,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.toastBackground,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1.2}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
}
