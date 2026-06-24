import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary (Fuska Pembesi)
  static const Color primary = Color(0xFFE6118E);
  static const Color primaryDark = Color(0xFFC70F7B);
  static const Color primaryLight = Color(0xFFF06FAD);

  // Secondary (Lacivert)
  static const Color secondary = Color(0xFF17233D);
  static const Color secondaryLight = Color(0xFF1E3A78);
  static const Color secondaryDark = Color(0xFF0A1533);

  // Accent (Teal/Turkuaz)
  static const Color accent = Color(0xFF10B5AC);

  // Water Blue (Yeni)
  static const Color waterBlue = Color(0xFF1273C2);

  // Background & Surface
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color navBg = Color(0xFFEEF0F5);
  static const Color inputBg = Color(0xFFEDEFF4);
  static const Color imageBg = Color(0xFFF4F6FA);

  // Text
  static const Color textPrimary = Color(0xFF11131A);
  static const Color textSecondary = Color(0xFF5B6478);
  static const Color textHint = Color(0xFF9AA3B4);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Badge / Tag arka planları
  static const Color pinkLight = Color(0xFFFCE3F1);
  static const Color blueLight = Color(0xFFEAF4FD);
  static const Color tealLight = Color(0xFFE7F9FC);

  // Border & Divider
  static const Color border = Color(0xFFC7CEDB);
  static const Color divider = Color(0xFFEEF0F5);

  // Semantic
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Order Status
  static const Color statusPending = Color(0xFFFF9800);
  static const Color statusConfirmed = Color(0xFF10B5AC);
  static const Color statusPreparing = Color(0xFFE6118E);
  static const Color statusOnTheWay = Color(0xFF1273C2);
  static const Color statusDelivered = Color(0xFF43A047);
  static const Color statusCancelled = Color(0xFFF44336);
  static const Color statusRefunded = Color(0xFF9C27B0);

  // Admin
  static const Color adminBackground = Color(0xFFF4F6FA);
  static const Color softPinkBackground = Color(0xFFFCE3F1);

  // Shimmer
  static const Color shimmerBase = Color(0xFFEEEEEE);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Misc
  static const Color whatsapp = Color(0xFF25D366);
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalGoldDark = Color(0xFFB8860B);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalSilverDark = Color(0xFF808080);
  static const Color medalBronze = Color(0xFFCD7F32);
  static const Color medalBronzeDark = Color(0xFF8B4513);
  static const Color excelGreen = Color(0xFF217346);
  static const Color pdfRed = Color(0xFFD32F2F);
  static const Color categoryOrange = Color(0xFFFF7043);
  static const Color categoryPurple = Color(0xFF7B1FA2);
  static const Color black = Color(0xFF000000);
}

class AppGradients {
  static const primary = LinearGradient(
    colors: [Color(0xFFE6118E), Color(0xFF1273C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const teal = LinearGradient(
    colors: [Color(0xFF18B6D9), Color(0xFF1273C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const pinkVertical = LinearGradient(
    colors: [Color(0xFFE6118E), Color(0xFFC70F7B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppShadows {
  static const sm = BoxShadow(
    offset: Offset(0, 4),
    blurRadius: 12,
    spreadRadius: -4,
    color: Color(0x1A141E3C),
  );

  static const md = BoxShadow(
    offset: Offset(0, 12),
    blurRadius: 30,
    spreadRadius: -10,
    color: Color(0x40141E3C),
  );

  static const primary = BoxShadow(
    offset: Offset(0, 18),
    blurRadius: 36,
    spreadRadius: -12,
    color: Color(0x8CE6118E),
  );

  static const blue = BoxShadow(
    offset: Offset(0, 14),
    blurRadius: 28,
    spreadRadius: -12,
    color: Color(0x8C1273C2),
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
      ),

      // Elevated Button — pill style
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(46),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button — pill style
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(46),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textHint,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),

      // Card
      cardTheme: const CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme — Plus Jakarta Sans
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        titleMedium: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        titleSmall: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary),
        bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary),
        labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
        labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary),
        labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.textHint),
      ),
    );
  }
}
