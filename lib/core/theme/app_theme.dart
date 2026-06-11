import 'package:flutter/material.dart';

class AppColors {
  // Primary (Fuska Pembesi)
  static const Color primary = Color(0xFFE73A99);      // Vibrant pink
  static const Color primaryLight = Color(0xFFF06FAD); // Light pink
  static const Color primaryDark = Color(0xFFD91B7F);  // Dark pink

  // Secondary (Lacivert - Derin Su Mavisi)
  static const Color secondary = Color(0xFF13275A);    // Deep navy
  static const Color secondaryLight = Color(0xFF1E3A78);
  static const Color secondaryDark = Color(0xFF0A1533);
  
  // Accent (Turkuaz - Kaynak Suyu)
  static const Color accent = Color(0xFF00A6AB);       // Turquoise

  // Background (Fuska palette)
  static const Color background = Color(0xFFFFFFFF);   // Pure white — matches design reference
  static const Color imageBg    = Color(0xFFF5F5F5);   // Neutral light gray — image placeholder bg
  static const Color surface = Color(0xFFFFFFFF);      // Pure white
  static const Color cardBg = Color(0xFFFFFFFF);       // White cards

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF43A047);      // #43A047 (Fuska green - matches statusDelivered)
  static const Color warning = Color(0xFFFF9800);      // Orange (changed from amber)
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Order Status Colors (Fuska Theme)
  static const Color statusPending = Color(0xFFFF9800);     // Orange
  static const Color statusConfirmed = Color(0xFF00A6AB);   // Turquoise (accent)
  static const Color statusPreparing = Color(0xFFE73A99);   // Pink (primary)
  static const Color statusOnTheWay = Color(0xFF13275A);    // Navy (secondary)
  static const Color statusDelivered = Color(0xFF43A047);   // Green
  static const Color statusCancelled = Color(0xFFF44336);   // Red

  // Border
  static const Color border = Color(0xFFE8EAED);       // Neutral light gray — matches design reference
  static const Color divider = Color(0xFFF0F0F0);

  // Soft pink background (Fuska Design System — onboarding/marketing alanlar)
  static const Color softPinkBackground = Color(0xFFFDF2F8);

  // Admin panel — sayfa arka planı (gri ton)
  static const Color adminBackground = Color(0xFFF8F9FA);

  // Shimmer (yukleniyor) renkleri
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // WhatsApp marka rengi
  static const Color whatsapp = Color(0xFF25D366);

  // Madalya renkleri (en cok satanlar / leaderboard)
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalGoldDark = Color(0xFFB8860B);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalSilverDark = Color(0xFF808080);
  static const Color medalBronze = Color(0xFFCD7F32);
  static const Color medalBronzeDark = Color(0xFF8B4513);

  // Excel/PDF export renkleri (rapor butonlari)
  static const Color excelGreen = Color(0xFF217346);
  static const Color pdfRed = Color(0xFFD32F2F);

  // Refunded order durumu (Fuska genisletilmis durum paleti)
  static const Color statusRefunded = Color(0xFF9C27B0);

  // Kategori renk paleti — ek tonlar (turuncu, mor)
  static const Color categoryOrange = Color(0xFFFF7043);
  static const Color categoryPurple = Color(0xFF7B1FA2);

  // Genel amacli siyah (hex parse fallback vb.)
  static const Color black = Color(0xFF000000);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        // background is deprecated in M3; scaffoldBackgroundColor handles it
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Fuska: 12px per DESIGN_SYSTEM.md
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),  // Fuska: 12px per DESIGN_SYSTEM.md
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),  // Fuska: 12px per DESIGN_SYSTEM.md
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),  // Fuska: 16px per DESIGN_SYSTEM.md
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.secondary,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textHint),
      ),
    );
  }
}
