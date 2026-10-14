// lib/theme/design_tokens.dart
//
// Identidad visual de Vence -- azul noche + azul principal + lavanda sobre
// superficies claras ("niebla"), premium y minimalista, con fuente nativa
// del sistema (SF Pro en iPhone, Roboto en Android) para que se sienta de
// app y no de página web, igual que Repara/Convive/VecindApp.
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

class VenceColors extends ThemeExtension<VenceColors> {
  const VenceColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSunken,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.brand,
    required this.brandStrong,
    required this.brandOn,
    required this.brandTint,
    required this.lavanda,
    required this.success,
    required this.warning,
    required this.warningText,
    required this.error,
    required this.errorText,
    required this.overlay,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSunken;
  final Color ink;
  final Color inkMuted;
  final Color inkFaint; // NUNCA para texto que haya que leer
  final Color brand;
  final Color brandStrong;
  final Color brandOn;
  final Color brandTint;
  final Color lavanda; // acento decorativo, nunca semántico
  final Color success;
  final Color warning; // SOLO icono o fondo tenue -- como texto usa warningText
  final Color warningText;
  final Color error; // SOLO icono, borde o fondo tenue -- como texto usa errorText
  final Color errorText;
  final Color overlay;

  static const light = VenceColors(
    background: Color(0xFFF4F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFECEEF5),
    surfaceSunken: Color(0xFFE2E6EF),
    ink: Color(0xFF26365B),
    inkMuted: Color(0xFF64748B),
    inkFaint: Color(0xFF97A1B5),
    brand: Color(0xFF5268D9),
    brandStrong: Color(0xFF3B4FBF),
    brandOn: Color(0xFFFFFFFF),
    brandTint: Color(0x24A99AE8),
    lavanda: Color(0xFFA99AE8),
    success: Color(0xFF23856D),
    warning: Color(0xFFE5A23B),
    warningText: Color(0xFF8A5A1F),
    error: Color(0xFFD96565),
    errorText: Color(0xFFB23D3D),
    overlay: Color(0x26131A2B),
  );

  static const dark = VenceColors(
    background: Color(0xFF0F1422),
    surface: Color(0xFF1A2235),
    surfaceMuted: Color(0xFF212B42),
    surfaceSunken: Color(0xFF2A3550),
    ink: Color(0xFFEEF1FA),
    inkMuted: Color(0xFF9AA6C0),
    inkFaint: Color(0xFF6E7996),
    brand: Color(0xFF7C8CEF),
    brandStrong: Color(0xFF99A6F5),
    brandOn: Color(0xFF10142A),
    brandTint: Color(0x33A99AE8),
    lavanda: Color(0xFFBFB2F0),
    success: Color(0xFF4FB996),
    warning: Color(0xFFF0B860),
    warningText: Color(0xFFF3C88A),
    error: Color(0xFFE08A8A),
    errorText: Color(0xFFF2A7A7),
    overlay: Color(0x59000000),
  );

  @override
  VenceColors copyWith({
    Color? background, Color? surface, Color? surfaceMuted, Color? surfaceSunken,
    Color? ink, Color? inkMuted, Color? inkFaint,
    Color? brand, Color? brandStrong, Color? brandOn, Color? brandTint,
    Color? lavanda, Color? success, Color? warning, Color? warningText,
    Color? error, Color? errorText, Color? overlay,
  }) {
    return VenceColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      brand: brand ?? this.brand,
      brandStrong: brandStrong ?? this.brandStrong,
      brandOn: brandOn ?? this.brandOn,
      brandTint: brandTint ?? this.brandTint,
      lavanda: lavanda ?? this.lavanda,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      warningText: warningText ?? this.warningText,
      error: error ?? this.error,
      errorText: errorText ?? this.errorText,
      overlay: overlay ?? this.overlay,
    );
  }

  @override
  VenceColors lerp(ThemeExtension<VenceColors>? other, double t) {
    if (other is! VenceColors) return this;
    return t < 0.5 ? this : other;
  }
}

class VenceRadius {
  VenceRadius._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 24;
  static const double pill = 999;
}

class VenceSpace {
  VenceSpace._();
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
}

extension VenceThemeContextX on BuildContext {
  VenceColors get colors => Theme.of(this).extension<VenceColors>()!;
}

class VenceText {
  VenceText._();

  static String get fontFamily => defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : 'Roboto';

  static TextTheme uiTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final palette = brightness == Brightness.dark ? VenceColors.dark : VenceColors.light;
    final sistema = base.apply(
      fontFamily: fontFamily,
      bodyColor: palette.ink,
      displayColor: palette.ink,
    );
    TextStyle display(double size, double height) => TextStyle(
          fontFamily: fontFamily,
          color: palette.ink,
          fontSize: size,
          height: height / size,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        );
    return sistema.copyWith(
      displayMedium: display(28, 34),
      displaySmall: display(22, 28),
      headlineSmall: display(18, 24),
      labelSmall: sistema.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
      bodyLarge: sistema.bodyLarge?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400),
      titleMedium: sistema.titleMedium?.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w600),
      bodySmall: sistema.bodySmall?.copyWith(fontSize: 12.5, height: 17 / 12.5, fontWeight: FontWeight.w500, color: palette.inkMuted),
      labelLarge: sistema.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
  }

  static TextStyle amount(BuildContext context, {bool large = false}) {
    final palette = Theme.of(context).extension<VenceColors>()!;
    return TextStyle(
      fontFamily: fontFamily,
      color: palette.ink,
      fontSize: large ? 32 : 17,
      fontWeight: large ? FontWeight.w800 : FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

ThemeData _buildVenceTheme(Brightness brightness) {
  final palette = brightness == Brightness.dark ? VenceColors.dark : VenceColors.light;
  final textTheme = VenceText.uiTextTheme(brightness);
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: palette.background,
    textTheme: textTheme,
    extensions: [palette],
    colorScheme: ColorScheme(
      brightness: brightness,
      surface: palette.surface,
      onSurface: palette.ink,
      primary: palette.brand,
      onPrimary: palette.brandOn,
      secondary: palette.lavanda,
      onSecondary: palette.ink,
      tertiary: palette.success,
      onTertiary: Colors.white,
      error: palette.error,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: VenceText.fontFamily,
        color: palette.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 1,
      shadowColor: palette.ink.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VenceRadius.md),
        side: BorderSide(color: palette.ink.withValues(alpha: 0.05)),
      ),
    ),
    dividerColor: palette.inkMuted.withValues(alpha: 0.15),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceMuted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VenceRadius.sm),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: palette.inkMuted.withValues(alpha: 0.8)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.brand,
        foregroundColor: palette.brandOn,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VenceRadius.sm)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.brand,
        side: BorderSide(color: palette.brand.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VenceRadius.sm)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: palette.brand,
      side: BorderSide(color: palette.ink.withValues(alpha: 0.12)),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(color: palette.ink, fontSize: 13, fontWeight: FontWeight.w500),
      secondaryLabelStyle: TextStyle(color: palette.brandOn, fontSize: 13, fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: palette.surface,
      selectedItemColor: palette.brand,
      unselectedItemColor: palette.inkFaint,
      type: BottomNavigationBarType.fixed,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.ink,
      contentTextStyle: TextStyle(color: palette.background),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

ThemeData buildVenceLightTheme() => _buildVenceTheme(Brightness.light);
ThemeData buildVenceDarkTheme() => _buildVenceTheme(Brightness.dark);
