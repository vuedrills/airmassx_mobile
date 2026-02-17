import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Airmass Xpress Design System
/// Inspired by Airbnb, AllTrails, and Rocket Money
/// Production-ready, award-winning design system
class AppTheme {
  // ============================================================
  // COLOR SYSTEM
  // ============================================================

  // Primary Palette (Brand Red - Action Color)
  static const Color primary = brandRed;
  static const Color primaryDark = Color(0xFFE04850);
  static const Color primaryLight = Color(0xFFFF8589);
  static const Color primarySoft = Color(0xFFFFEBEB);

  // Secondary Palette (Teal Accent)
  static const Color secondary = Color(0xFF00A699);
  static const Color secondaryDark = Color(0xFF008080);
  static const Color secondaryLight = Color(0xFF4DD4C4);
  static const Color secondarySoft = Color(0xFFE6F7F5);

  // Brand Colors
  static const Color navy = Color(0xFF1A2B4A);
  static const Color navyDark = Color(0xFF0F1A2E);
  static const Color navyLight = Color(0xFF2E4A6F);
  static const Color navySoft = Color(0xFFE8EBF0);
  static const Color brandRed = Color(0xFFFF5A5F);

  // Neutral Palette (Warm-tinted)
  static const Color neutral900 = Color(0xFF222222);
  static const Color neutral800 = Color(0xFF333333);
  static const Color neutral700 = Color(0xFF484848);
  static const Color neutral600 = Color(0xFF5E5E5E);
  static const Color neutral500 = Color(0xFF767676);
  static const Color neutral400 = Color(0xFF9B9B9B);
  static const Color neutral300 = Color(0xFFB0B0B0);
  static const Color neutral200 = Color(0xFFDDDDDD);
  static const Color neutral100 = Color(0xFFF7F7F7);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFDCFCE7); // Light Green
  static const Color warning = Color(0xFFFFB400);
  static const Color warningLight = Color(0xFFFFF6E0);
  static const Color error = Color(0xFFC04433); // Professional Muted Red
  static const Color errorLight = Color(0xFFFFF1F0);
  static const Color info = Color(0xFF0077CC);
  static const Color infoLight = Color(0xFFE6F3FA);

  // Legacy aliases (for backward compatibility)
  // Legacy aliases (for backward compatibility)
  static const Color primaryBlue = navy;
  static const Color accentTeal = secondary;
  static const Color accentRed = brandRed;
  static const Color accentGreen = success;
  static const Color successGreen = success;
  static const Color warningOrange = warning;
  static const Color backgroundColor = neutral50;
  static const Color cardBackground = white;
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral500;
  static const Color divider = neutral200;
  static const Color statusOnline = success;
  static const Color statusOffline = neutral400;
  static const Color verifiedBlue = info;

  // ============================================================
  // GRADIENTS
  // ============================================================

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2B4A), Color(0xFF2E4A6F)],
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF6B6B), Color(0xFFFF5A5F), Color(0xFFE04850)],
  );

  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2B4A), Color(0xFF2E4A6F), Color(0xFF4A6B9A)],
  );

  static const LinearGradient nightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
  );

  static const LinearGradient overlayGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2B4A), Color(0xFF2E4A6F), Color(0xFF4A6B9A)],
  );

  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF5A5F), Color(0xFFFF7E82)],
  );

  // ============================================================
  // SPACING
  // ============================================================

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 48;
  static const double space4xl = 64;

  // Layout
  static const double pageMarginH = 20;
  static const double pageMarginV = 16;
  static const double cardPadding = 16;
  static const double buttonPaddingH = 24;
  static const double buttonPaddingV = 16;

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ============================================================
  // ELEVATION / SHADOWS
  // ============================================================

  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get elevation4 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ];

  // ============================================================
  // THEME DATA
  // ============================================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: white,
        primaryContainer: primarySoft,
        secondary: navy,
        onSecondary: white,
        secondaryContainer: navySoft,
        surface: white,
        onSurface: neutral900,
        error: error,
        onError: white,
        errorContainer: errorLight,
      ),
      scaffoldBackgroundColor: neutral50,

      // Typography
      textTheme: _buildTextTheme(),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: primary), // Icons in red
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: navy, // Font in navy
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: neutral200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: spaceSm, vertical: 6),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: buttonPaddingH,
            vertical: buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(
            horizontal: buttonPaddingH,
            vertical: buttonPaddingV,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMd,
            vertical: spaceSm,
          ),
          textStyle: GoogleFonts.nunitoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: neutral300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: neutral200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceLg,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.nunitoSans(
          color: neutral400,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.nunitoSans(
          color: neutral700,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.nunitoSans(
          color: navy, // Font in navy
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary, // Icons will be red
        unselectedItemColor: neutral500,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(color: navy), // Attempt to keep label navy
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: white,
        indicatorColor: primarySoft,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary);
          }
          return const IconThemeData(color: neutral500);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.nunitoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: navy, // Font in navy
            );
          }
          return GoogleFonts.nunitoSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: neutral500,
          );
        }),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: neutral100,
        labelStyle: GoogleFonts.nunitoSans(
          color: neutral700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: GoogleFonts.nunitoSans(
          color: navy, // Font in navy
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: primarySoft,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: spaceXs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusFull),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: neutral300,
        dragHandleSize: Size(40, 4),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutral900,
        ),
        contentTextStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: neutral700,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: neutral200,
        thickness: 1,
        space: 1,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceLg),
        titleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutral900,
        ),
        subtitleTextStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          color: neutral500,
        ),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: navy, // Font in navy
        unselectedLabelColor: neutral500,
        indicatorColor: primary, // Indicator in red
        labelStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.nunitoSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: GoogleFonts.nunitoSans(
          color: white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: primary, // Icons in red
        size: 24,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: neutral200,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryLight;
          }
          return neutral200;
        }),
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return GoogleFonts.nunitoSansTextTheme().copyWith(
      // Display styles - for hero/splash text
      displayLarge: GoogleFonts.nunitoSans(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: neutral900,
        height: 1.2,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.nunitoSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: neutral900,
        height: 1.25,
        letterSpacing: -0.25,
      ),
      displaySmall: GoogleFonts.nunitoSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.3,
      ),

      // Headline styles - for page/section titles
      headlineLarge: GoogleFonts.nunitoSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.35,
      ),
      headlineMedium: GoogleFonts.nunitoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.4,
      ),
      headlineSmall: GoogleFonts.nunitoSans(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: neutral900,
        height: 1.4,
      ),

      // Title styles - for cards, buttons
      titleLarge: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.5,
      ),
      titleMedium: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: neutral900,
        height: 1.5,
      ),

      // Body styles - for content
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: neutral900,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: neutral900,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: neutral500,
        height: 1.5,
      ),

      // Label styles - for captions, hints
      labelLarge: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: neutral700,
        height: 1.4,
      ),
      labelMedium: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neutral700,
        height: 1.4,
      ),
      labelSmall: GoogleFonts.nunitoSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: neutral500,
        height: 1.4,
      ),
    );
  }
}
