import 'package:flutter/material.dart';

class AppColors {
  static bool get isDark => AppTheme.themeModeNotifier.value == ThemeMode.dark;

  // Màu chủ đạo Vàng - Đen phong cách chú ong
  static const Color primary = Color(0xFFFBBF24);
  static const Color primaryDark = Color(0xFFD97706);
  static Color get primaryLight =>
      isDark ? const Color(0xFF3D2800) : const Color(0xFFFEF3C7);

  static const Color secondary = Color(0xFF2E2A1F);
  static const Color secondaryLight = Color(0xFF443E2E);

  // Màu nền và bề mặt tự động đổi theo chế độ Sáng / Tối
  static Color get background =>
      isDark ? const Color(0xFF0B0A07) : const Color(0xFFFFFDF5);
  static Color get surface =>
      isDark ? const Color(0xFF171510) : const Color(0xFFFFFFFF);
  static Color get surfaceElevated =>
      isDark ? const Color(0xFF221F17) : const Color(0xFFFEF9C3);
  static Color get border =>
      isDark ? const Color(0xFF332E22) : const Color(0xFFE7E5E4);

  static Color get lightSurface => surface;
  static Color get lightBackground => background;

  // Màu chữ
  static Color get textPrimary =>
      isDark ? const Color(0xFFFEFCE8) : const Color(0xFF1C1917);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA8A29E) : const Color(0xFF57534E);
  static Color get textMuted => const Color(0xFF78716C);
  static const Color onPrimary = Color(0xFF0B0A07);

  // Màu trạng thái thu / chi / cảnh báo
  static const Color expense = Color(0xFFEF4444);
  static Color get expenseLight =>
      isDark ? const Color(0xFF3B0D0D) : const Color(0xFFFEE2E2);

  static const Color income = Color(0xFF10B981);
  static Color get incomeLight =>
      isDark ? const Color(0xFF022C22) : const Color(0xFFD1FAE5);

  static const Color warning = Color(0xFFF59E0B);
  static Color get warningLight =>
      isDark ? const Color(0xFF2D1F00) : const Color(0xFFFEF3C7);

  static const Color voiceActive = Color(0xFFF59E0B);
  static const Color voiceWave = Color(0xFFFDE68A);
  static const Color savings = Color(0xFFFBBF24);
  static const Color bee = Color(0xFFFBBF24);

  static const Color darkBackground = Color(0xFF0B0A07);
  static const Color darkSurface = Color(0xFF171510);
  static const Color darkSurfaceCard = Color(0xFF221F17);
  static const Color darkTextPrimary = Color(0xFFFEFCE8);
  static const Color darkTextSecondary = Color(0xFFA8A29E);
  static const Color darkBorder = Color(0xFF332E22);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient beeGradient = primaryGradient;

  static const LinearGradient voiceGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get navyGradient => LinearGradient(
    colors: isDark
        ? const [Color(0xFF0B0A07), Color(0xFF171510)]
        : const [Color(0xFFFFFDF5), Color(0xFFFEF3C7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient savingsGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final bg = dark ? const Color(0xFF0B0A07) : const Color(0xFFFFFDF5);
    final surf = dark ? const Color(0xFF171510) : const Color(0xFFFFFFFF);
    final surfElev = dark ? const Color(0xFF221F17) : const Color(0xFFFEF9C3);
    final brd = dark ? const Color(0xFF332E22) : const Color(0xFFE7E5E4);
    final txtPri = dark ? const Color(0xFFFEFCE8) : const Color(0xFF1C1917);
    final txtSec = dark ? const Color(0xFFA8A29E) : const Color(0xFF57534E);
    const txtMuted = Color(0xFF78716C);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.voiceActive,
        surface: surf,
        brightness: brightness,
      ),
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: txtPri),
        titleTextStyle: TextStyle(
          color: txtPri,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surf,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: brd, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brd, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: brd, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: txtMuted, fontSize: 14),
        labelStyle: TextStyle(color: txtSec),
        prefixIconColor: txtMuted,
        suffixIconColor: txtMuted,
      ),
      dividerTheme: DividerThemeData(color: brd),
      popupMenuTheme: PopupMenuThemeData(
        color: surf,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surf,
        selectedItemColor: dark ? AppColors.primary : AppColors.primaryDark,
        unselectedItemColor: txtMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surf,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surf,
        contentTextStyle: TextStyle(color: txtPri),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfElev,
        labelStyle: TextStyle(color: txtSec, fontSize: 12),
        side: BorderSide(color: brd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
}
