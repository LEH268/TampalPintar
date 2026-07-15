import 'package:flutter/material.dart';

// TampalPintar design system (government dashboard).
// Style: "Data-Dense Dashboard" — authority blue, amber highlights, white
// cards on a cool-gray canvas. Light-only: the dashboard is demoed in Chrome
// and manual verification covers the light theme.
//
// Deliberately duplicated with app/lib/theme.dart (PRD: no shared package);
// keep the two independently consistent.

const _blue = Color(0xFF1E40AF); // blue-800 — primary actions
const _sky = Color(0xFF0369A1); // sky-700 — links/selection
const _amber = Color(0xFFB45309); // amber-700 — highlights
const _red = Color(0xFFDC2626); // red-600 — risk/destructive

ColorScheme get _scheme => const ColorScheme(
      brightness: Brightness.light,
      primary: _blue,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDBEAFE),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: _sky,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2FE),
      onSecondaryContainer: Color(0xFF075985),
      tertiary: _amber,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFFEF3C7),
      onTertiaryContainer: Color(0xFF92400E),
      error: _red,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFFE2E8F0),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Colors.white,
      surfaceContainer: Color(0xFFF1F5F9),
      surfaceContainerHigh: Color(0xFFEDF1F6),
      surfaceContainerHighest: Color(0xFFE2E8F0),
      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Color(0xFFF8FAFC),
      inversePrimary: Color(0xFF93C5FD),
      shadow: Colors.black,
      scrim: Colors.black,
    );

ThemeData buildGovTheme() {
  final scheme = _scheme;
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      titleLarge: base.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleMedium:
          base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall:
          base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      labelLarge:
          base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surfaceContainerLowest,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      shape: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      prefixIconColor: scheme.onSurfaceVariant,
      suffixIconColor: scheme.onSurfaceVariant,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: scheme.outline),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface, fontWeight: FontWeight.w700),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
          color: scheme.onInverseSurface, fontWeight: FontWeight.w500),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
  );
}

/// Semantic style for a risk score: container/foreground pair + label.
/// Thresholds mirror the backend contract (>=80 auto-assign, >=50 medium).
({Color bg, Color fg, String label}) riskStyle(int? score) {
  if (score == null) {
    return (
      bg: const Color(0xFFE2E8F0),
      fg: const Color(0xFF475569),
      label: 'Analisis dalam proses',
    );
  }
  if (score >= 80) {
    return (
      bg: const Color(0xFFFEE2E2),
      fg: const Color(0xFF991B1B),
      label: 'Risiko $score',
    );
  }
  if (score >= 50) {
    return (
      bg: const Color(0xFFFEF3C7),
      fg: const Color(0xFF92400E),
      label: 'Risiko $score',
    );
  }
  return (
    bg: const Color(0xFFD1FAE5),
    fg: const Color(0xFF065F46),
    label: 'Risiko $score',
  );
}

/// Success green for "fixed"/completed states.
const kSuccessGreen = Color(0xFF047857);

/// Small rounded status pill: optional leading icon + label on a
/// container color.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
  });
  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                  color: fg, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}

/// Section header used above grouped panel content.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.top = 20});
  final String title;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Brand mark: the TampalPintar app icon (pre-rounded, transparent corners).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Logo TampalPintar',
      );
}
