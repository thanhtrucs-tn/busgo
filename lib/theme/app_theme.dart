// theme/app_theme.dart
// Dinh nghia theme (light + dark) cho ung dung BusGo.
// Tat ca mau sac lay tu ColorScheme -> cac widget dung Theme.of(context)
// se tu dong doi mau giua che do sang va toi.

import 'package:flutter/material.dart';

/// Mau cho giao dien SANG (Light).
const ColorScheme _lightScheme = ColorScheme.light(
  primary: Color(0xFF2D6A4F), // Xanh la chu dao
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFDDEADF), // Xanh nhat
  onPrimaryContainer: Color(0xFF183B2B),
  secondary: Color(0xFF2D6A4F),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFDDEADF),
  onSecondaryContainer: Color(0xFF183B2B),
  error: Color(0xFFE5484D), // Do (tim, canh bao)
  onError: Colors.white,
  errorContainer: Color(0xFFFBDCE0),
  onErrorContainer: Color(0xFF7A1C22),
  surface: Color(0xFFFFFFFF), // Card / the
  onSurface: Color(0xFF1B3A2B), // Chu trang thanh binh thuong
  onSurfaceVariant: Color(0xFF6B7A6F), // Chu nhat
  outline: Color(0xFF8A978C), // Chu mo
  outlineVariant: Color(0xFFD3DACF), // Vien nhat
  surfaceContainerHighest: Color(0xFFEDF1E8),
  surfaceTint: Color(0xFF2D6A4F),
);

/// Mau cho giao dien TOI (Dark).
const ColorScheme _darkScheme = ColorScheme.dark(
  primary: Color(0xFF1B4332), // Xanh la dam
  onPrimary: Color(0xFFE0F2E7),
  primaryContainer: Color(0xFF2A5A44), // Xanh nhat tren nen toi
  onPrimaryContainer: Color(0xFFD6EDDE),
  secondary: Color(0xFF1B4332),
  onSecondary: Color(0xFFE0F2E7),
  secondaryContainer: Color(0xFF274B38),
  onSecondaryContainer: Color(0xFFD6EDDE),
  error: Color(0xFFEF5350),
  onError: Color(0xFF2B0000),
  errorContainer: Color(0xFF5A1518),
  onErrorContainer: Color(0xFFFBDCE0),
  surface: Color(0xFF1E1E1E), // Card / the toi
  onSurface: Color(0xFFE0E0E0), // Chu trang/nhat
  onSurfaceVariant: Color(0xFFB0B0B0),
  outline: Color(0xFF808080),
  outlineVariant: Color(0xFF3A3A3A),
  surfaceContainerHighest: Color(0xFF2A2A2A),
  surfaceTint: Color(0xFF1B4332),
);

/// Theme chung (xay tu bang mau + ColorScheme).
ThemeData _buildTheme(ColorScheme scheme, Color scaffoldBg) {
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scaffoldBg,

    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      titleTextStyle: TextStyle(
        color: scheme.onPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      prefixIconColor: scheme.primary,
      hintStyle: TextStyle(color: scheme.outline),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      textColor: scheme.onSurface,
    ),

    dividerTheme: DividerThemeData(color: scheme.outlineVariant),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.onPrimary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? scheme.primary : null,
      ),
    ),
  );
}

/// Theme cho giao dien sang: nen #F4F6F0, card trang, chu xanh la dam.
ThemeData buildAppTheme() {
  return _buildTheme(_lightScheme, const Color(0xFFF4F6F0));
}

/// Theme cho giao dien toi: nen #121212, card #1E1E1E, chu #E0E0E0.
ThemeData buildDarkTheme() {
  return _buildTheme(_darkScheme, const Color(0xFF121212));
}

/// Mo rong de lay mau tu theme nhanh gon: context.colors.primary
extension BusGoColors on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Mau nen man hinh hien tai (sang/toi).
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;
}

/// Đổi mã màu "#RRGGBB" từ backend thành Color (null nếu không hợp lệ).
Color? parseHexColor(String? value) {
  if (value == null) return null;
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) return null;
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(0xFF000000 | parsed);
}
