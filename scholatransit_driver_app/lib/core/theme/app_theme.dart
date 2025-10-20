import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Professional Blue Color Scheme - Trust, Security, Reliability
  // Primary Blue Palette (Inspired by Samsara, Verizon Connect, Fleetio)
  static const Color primaryColor = Color(
    0xFF0052CC,
  ); // Deep Professional Blue (#0052cc)
  static const Color primaryVariant = Color(
    0xFF003D99,
  ); // Darker Blue for containers
  static const Color primaryLight = Color(
    0xFF1E40AF,
  ); // Lighter Blue for accents
  static const Color primaryLighter = Color(
    0xFF3B82F6,
  ); // Even lighter for backgrounds

  // Secondary Blue Palette
  static const Color secondaryColor = Color(
    0xFF0EA5E9,
  ); // Sky Blue - Trust & Communication
  static const Color secondaryVariant = Color(0xFF0284C7); // Darker Sky Blue
  static const Color secondaryLight = Color(0xFF38BDF8); // Light Sky Blue

  // Neutral Blue Colors for Professional Look (No Grey)
  static const Color neutralBlue = Color(0xFF1E40AF); // Professional Blue
  static const Color neutralBlueLight = Color(0xFF3B82F6); // Lighter Blue
  static const Color neutralBlueDark = Color(0xFF1E3A8A); // Darker Blue

  // Status Colors with Blue Theme
  static const Color errorColor = Color(0xFFDC2626); // Professional Red
  static const Color warningColor = Color(0xFFD97706); // Professional Orange
  static const Color successColor = Color(0xFF059669); // Professional Green
  static const Color infoColor = Color(0xFF0EA5E9); // Sky Blue for info

  // Surface Colors with Blue Tints
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(
    0xFFF8FAFC,
  ); // Cool white background
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color surfaceBlue = Color(0xFFF0F9FF); // Very light blue surface
  static const Color surfaceBlueLight = Color(0xFFE0F2FE); // Light blue surface

  // Text Colors with Blue Theme (No Grey)
  static const Color textPrimary = Color(0xFF1E293B); // Dark blue
  static const Color textSecondary = Color(0xFF1E40AF); // Professional blue
  static const Color textTertiary = Color(0xFF3B82F6); // Light blue
  static const Color textBlue = Color(
    0xFF0052CC,
  ); // Blue text for links/accents (#0052cc)

  // Border and Divider Colors (Blue Theme)
  static const Color borderColor = Color(0xFFE0F2FE); // Light blue border
  static const Color dividerColor = Color(0xFFF0F9FF); // Very light blue
  static const Color borderBlue = Color(0xFF3B82F6); // Blue border

  // Trip Status Colors (Professional Blue Theme)
  static const Color tripPending = Color(
    0xFF3B82F6,
  ); // Blue - Inactive, No Data
  static const Color tripActive = Color(
    0xFF0052CC,
  ); // Deep Professional Blue (#0052cc) - Active/Current
  static const Color tripCompleted = Color(
    0xFF059669,
  ); // Professional Green - On Time, Good Service
  static const Color tripCancelled = Color(
    0xFFDC2626,
  ); // Professional Red - Cancelled, Bad Service
  static const Color tripDelayed = Color(
    0xFFD97706,
  ); // Professional Orange - Delay, Minor Disruption

  // Student Status Colors (Blue Theme)
  static const Color studentWaiting = Color(0xFF3B82F6); // Blue for waiting
  static const Color studentOnBus = Color(
    0xFF0052CC,
  ); // Deep blue (#0052cc) for on bus
  static const Color studentPickedUp = Color(0xFF059669); // Green for picked up
  static const Color studentDroppedOff = Color(
    0xFF0EA5E9,
  ); // Sky blue for dropped off

  // Emergency Colors (Professional Theme)
  static const Color emergencyHigh = Color(0xFFDC2626); // Professional Red
  static const Color emergencyMedium = Color(0xFFD97706); // Professional Orange
  static const Color emergencyLow = Color(0xFF0EA5E9); // Sky Blue

  // Map UI Colors - Vehicle/Current Location Markers (Professional Blue)
  static const Color vehicleMarkerPrimary = Color(
    0xFF0052CC,
  ); // Deep Professional Blue (#0052cc)
  static const Color vehicleMarkerAlt = Color(0xFF059669); // Professional Green
  static const Color vehicleMarkerSecondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color vehicleMarkerAccent = Color(
    0xFF1E40AF,
  ); // Light Blue accent

  // Map UI Colors - Route & Path Colors (Blue Theme)
  static const Color routePrimary = Color(
    0xFF0052CC,
  ); // Deep Blue (#0052cc) for primary route
  static const Color routeSecondary = Color(
    0xFF60A5FA,
  ); // Light blue for route fill
  static const Color routeBorder = Color(
    0xFF0052CC,
  ); // Deep blue (#0052cc) border for route
  static const Color routeAlt = Color(0xFF0EA5E9); // Sky blue alternative
  static const Color routeAltDark = Color(0xFF0284C7); // Dark sky blue variant

  // Map UI Colors - Multiple Route Colors (Professional Theme)
  static const Color routeRed = Color(0xFFDC2626); // Professional Red Line
  static const Color routeBlue = Color(
    0xFF0052CC,
  ); // Professional Blue Line (#0052cc)
  static const Color routeGreen = Color(0xFF059669); // Professional Green Line
  static const Color routeYellow = Color(
    0xFFD97706,
  ); // Professional Orange Line
  static const Color routePurple = Color(
    0xFF7C3AED,
  ); // Professional Purple Line
  static const Color routeOrange = Color(
    0xFFEA580C,
  ); // Professional Orange Line

  // Map UI Colors - Status & Alert Colors (Professional Theme)
  static const Color statusOnTime = Color(
    0xFF059669,
  ); // Professional Green - On Time
  static const Color statusDelay = Color(
    0xFFD97706,
  ); // Professional Orange - Delay
  static const Color statusCancelled = Color(
    0xFFDC2626,
  ); // Professional Red - Cancelled
  static const Color statusInactive = Color(0xFF3B82F6); // Blue - Inactive

  // Map UI Colors - Background and UI (Blue Theme)
  static const Color mapBackgroundLight = Color(0xFFFFFFFF);
  static const Color mapBackgroundDark = Color(0xFF1E293B); // Dark blue
  static const Color mapTextPrimary = Color(0xFF1E293B); // Dark blue text
  static const Color mapTextSecondary = Color(
    0xFF1E40AF,
  ); // Professional blue text
  static const Color mapBorder = Color(0xFFE0F2FE); // Light blue border

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryVariant,
        secondary: secondaryColor,
        secondaryContainer: secondaryVariant,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: textPrimary,
      ),

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(8.w),
      ),

      // Button Themes (Professional Blue)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme (Blue Theme)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F9FF), // Light blue surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        labelStyle: TextStyle(fontSize: 14.sp, color: textSecondary),
        hintStyle: TextStyle(fontSize: 14.sp, color: textTertiary),
      ),

      // Text Theme (Professional Blue Titles)
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: primaryColor, // Professional blue for large titles
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: primaryColor, // Professional blue for medium titles
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: primaryColor, // Professional blue for small titles
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for large headlines
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for medium headlines
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for small headlines
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for large titles
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for medium titles
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: primaryColor, // Professional blue for small titles
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: textTertiary,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textSecondary, size: 24),

      // Primary Icon Theme
      primaryIconTheme: const IconThemeData(color: primaryColor, size: 24),
    );
  }

  // Dark Theme (Professional Blue Dark)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        primaryContainer: primaryColor,
        secondary: secondaryLight,
        secondaryContainer: secondaryColor,
        error: errorColor,
        surface: Color(0xFF1E293B),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.white,
      ),

      // App Bar Theme (Dark Blue)
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Card Theme (Dark Blue)
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(8.w),
      ),

      // Button Themes (Dark Blue)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme (Dark Blue)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF334155), // Dark blue surface
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF475569)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        labelStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFF94A3B8)),
        hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xFF64748B)),
      ),

      // Bottom Navigation Bar Theme (Dark Blue)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: primaryLight,
        unselectedItemColor: const Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Floating Action Button Theme (Dark Blue)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),

      // Divider Theme (Dark Blue)
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
        space: 1,
      ),

      // Text Theme (Dark Blue Titles)
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: primaryLight, // Light blue for large titles in dark mode
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: primaryLight, // Light blue for medium titles in dark mode
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: primaryLight, // Light blue for small titles in dark mode
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for large headlines in dark mode
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for medium headlines in dark mode
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for small headlines in dark mode
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for large titles in dark mode
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for medium titles in dark mode
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: primaryLight, // Light blue for small titles in dark mode
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: Colors.white,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF94A3B8),
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF94A3B8),
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF64748B),
        ),
      ),

      // Icon Theme (Dark Blue)
      iconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 24),
      primaryIconTheme: const IconThemeData(color: primaryLight, size: 24),
    );
  }
}
