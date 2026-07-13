import 'package:flutter/material.dart';

// TampalPintar design system (citizen app).
// Style: "Accessible & Ethical" — high contrast, WCAG-minded, calm civic
// palette. Asphalt navy primary, sky-blue actions, amber for rewards/points,
// red reserved for risk and destructive actions (matches the red map pins).

const _navy = Color(0xFF0F172A); // slate-900 — asphalt
const _navyInk = Color(0xFF020617); // slate-950
const _sky = Color(0xFF0369A1); // sky-700 — actions/links
const _amber = Color(0xFFB45309); // amber-700 — points/rewards
const _red = Color(0xFFDC2626); // red-600 — risk/destructive

ColorScheme get _lightScheme => const ColorScheme(
      brightness: Brightness.light,
      primary: _navy,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE2E8F0),
      onPrimaryContainer: _navyInk,
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
      onSurface: _navy,
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
      inversePrimary: Color(0xFF7DD3FC),
      shadow: Colors.black,
      scrim: Colors.black,
    );

ColorScheme get _darkScheme => const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7DD3FC), // sky-300
      onPrimary: Color(0xFF082F49),
      primaryContainer: Color(0xFF075985),
      onPrimaryContainer: Color(0xFFE0F2FE),
      secondary: Color(0xFF38BDF8),
      onSecondary: Color(0xFF082F49),
      secondaryContainer: Color(0xFF0C4A6E),
      onSecondaryContainer: Color(0xFFE0F2FE),
      tertiary: Color(0xFFFCD34D),
      onTertiary: Color(0xFF451A03),
      tertiaryContainer: Color(0xFF92400E),
      onTertiaryContainer: Color(0xFFFEF3C7),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF0B1220),
      onSurface: Color(0xFFE2E8F0),
      onSurfaceVariant: Color(0xFF94A3B8),
      outline: Color(0xFF334155),
      outlineVariant: Color(0xFF1E293B),
      surfaceContainerLowest: Color(0xFF0F172A),
      surfaceContainerLow: Color(0xFF111A2E),
      surfaceContainer: Color(0xFF152036),
      surfaceContainerHigh: Color(0xFF1A2740),
      surfaceContainerHighest: Color(0xFF23304C),
      inverseSurface: Color(0xFFE2E8F0),
      onInverseSurface: Color(0xFF0F172A),
      inversePrimary: _sky,
      shadow: Colors.black,
      scrim: Colors.black,
    );

ThemeData buildAppTheme(Brightness brightness) {
  final scheme =
      brightness == Brightness.dark ? _darkScheme : _lightScheme;
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: scheme.surfaceContainer,
      centerTitle: false,
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
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.secondary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        side: BorderSide(color: scheme.outline),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLowest,
      selectedColor: scheme.secondaryContainer,
      labelStyle: base.textTheme.labelLarge
          ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.secondaryContainer,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.secondary,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      unselectedLabelStyle:
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface, fontWeight: FontWeight.w700),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
          color: scheme.onInverseSurface, fontWeight: FontWeight.w500),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      titleTextStyle: base.textTheme.bodyLarge
          ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w500),
      subtitleTextStyle:
          base.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      extendedTextStyle:
          const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}

/// Semantic style for a risk score: container/foreground pair + label.
/// Thresholds mirror the backend contract (>=80 auto-assign, >=50 medium).
({Color bg, Color fg, String label}) riskStyle(
    BuildContext context, int? score) {
  final scheme = Theme.of(context).colorScheme;
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (score == null) {
    return (
      bg: scheme.surfaceContainerHighest,
      fg: scheme.onSurfaceVariant,
      label: 'Analisis dalam proses',
    );
  }
  if (score >= 80) {
    return (bg: scheme.errorContainer, fg: scheme.onErrorContainer, label: 'Risiko $score');
  }
  if (score >= 50) {
    return (
      bg: dark ? const Color(0xFF92400E) : const Color(0xFFFEF3C7),
      fg: dark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
      label: 'Risiko $score',
    );
  }
  return (
    bg: dark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
    fg: dark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
    label: 'Risiko $score',
  );
}

/// Success green (theme-aware) for "fixed"/positive amounts.
Color successColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF34D399)
        : const Color(0xFF059669);

/// Small rounded status pill: optional leading icon + label on a
/// container color. Used for risk badges, assignment state, dashcam status.
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

/// Section header used above grouped content (Rewards, Settings, panel).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.top = 24});
  final String title;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Brand mark: the TampalPintar app icon (pre-rounded, transparent corners).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 64});
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
