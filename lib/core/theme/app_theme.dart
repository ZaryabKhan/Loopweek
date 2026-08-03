import 'package:flutter/material.dart';
import 'package:loopweek/core/theme/accent_colors.dart';
import 'package:loopweek/domain/models/color_tag.dart';

/// Builds the app [ThemeData] from the user's selected [ColorTag] and a
/// brightness. Per spec: flat design, no shadows, no heavy elevation, off-white
/// light background (#F2F2F2-ish) and near-black dark (#121212-ish) — never pure.
class AppTheme {
  const AppTheme._();

  static const _lightScaffold = Color(0xFFF2F2F2);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _darkScaffold = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);

  static ThemeData light(ColorTag accent) =>
      _build(Brightness.light, AccentColors.of(accent), _lightSurface);

  static ThemeData dark(ColorTag accent) =>
      _build(Brightness.dark, AccentColors.of(accent), _darkSurface);

  static ThemeData _build(Brightness brightness, Color accent, Color surface) {
    final bool isLight = brightness == Brightness.light;
    final Color onAccent = AccentColors.onAccentOf(accent);
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          primary: accent,
          surface: surface,
        ).copyWith(
          primary: accent,
          onPrimary: onAccent,
          secondary: accent,
          onSecondary: onAccent,
          surface: surface,
        );

    final scaffoldBg = isLight ? _lightScaffold : _darkScaffold;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerTheme: DividerThemeData(
        color: isLight ? const Color(0xFFE0E0E0) : const Color(0xFF2A2A2A),
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return onAccent;
          return isLight ? const Color(0xFF9E9E9E) : const Color(0xFFBDBDBD);
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return accent;
          return isLight ? const Color(0xFFE0E0E0) : const Color(0xFF3A3A3A);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: isLight ? Colors.black87 : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      textTheme: _textTheme(scheme),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight
            ? const Color(0xFF323232)
            : const Color(0xFFE6E6E6),
        contentTextStyle: TextStyle(
          color: isLight ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // Per spec: bold, tight-tracking, condensed sans-serif for headings.
    // We approximate "condensed" with letter-spacing reduction since the
    // default Material font stack has no grotesk available offline.
    final headline = TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: scheme.onSurface,
      height: 1.05,
    );

    return TextTheme(
      displayLarge: headline.copyWith(fontSize: 32),
      displayMedium: headline.copyWith(fontSize: 28),
      displaySmall: headline.copyWith(fontSize: 24),
      headlineLarge: headline.copyWith(fontSize: 28),
      headlineMedium: headline.copyWith(fontSize: 24),
      headlineSmall: headline.copyWith(fontSize: 20),
      titleLarge: headline.copyWith(fontSize: 18, letterSpacing: -0.4),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: scheme.onSurface),
      bodySmall: TextStyle(
        fontSize: 13,
        color: scheme.onSurface.withValues(alpha: 0.6),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: scheme.primary,
        letterSpacing: 0.2,
      ),
    );
  }
}
