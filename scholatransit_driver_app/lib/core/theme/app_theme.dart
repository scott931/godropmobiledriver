import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Scheme
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryVariant = Color(0xFF1D4ED8);
  static const Color secondaryColor = Color(0xFF10B981);
  static const Color secondaryVariant = Color(0xFF059669);

  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color successColor = Color(0xFF10B981);
  static const Color infoColor = Color(0xFF3B82F6);

  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  // Trip Status Colors (Updated to match traffic light system)
  static const Color tripPending = Color(
    0xFF9AA0A6,
  ); // Grey - Inactive, No Data
  static const Color tripActive = Color(
    0xFF4285F4,
  ); // Vibrant Blue - Active/Current
  static const Color tripCompleted = Color(
    0xFF34A853,
  ); // Green - On Time, Good Service
  static const Color tripCancelled = Color(
    0xFFEA4335,
  ); // Red - Cancelled, Bad Service
  static const Color tripDelayed = Color(
    0xFFFBBC05,
  ); // Yellow/Amber - Delay, Minor Disruption

  // Student Status Colors
  static const Color studentWaiting = Color(0xFF6B7280);
  static const Color studentOnBus = Color(0xFF3B82F6);
  static const Color studentPickedUp = Color(0xFF10B981);
  static const Color studentDroppedOff = Color(0xFF8B5CF6);

  // Emergency Colors
  static const Color emergencyHigh = Color(0xFFEF4444);
  static const Color emergencyMedium = Color(0xFFF59E0B);
  static const Color emergencyLow = Color(0xFF3B82F6);

  // Map UI Colors - Vehicle/Current Location Markers
  static const Color vehicleMarkerPrimary = Color(
    0xFF4285F4,
  ); // Vibrant Blue - primary choice
  static const Color vehicleMarkerAlt = Color(
    0xFF34A853,
  ); // Bright Green - excellent alternative
  static const Color vehicleMarkerSecondary = Color(
    0xFF3366CC,
  ); // Darker blue variant

  // Map UI Colors - Route & Path Colors
  static const Color routePrimary = Color(
    0xFF4285F4,
  ); // Bold Blue for primary route
  static const Color routeSecondary = Color(
    0xFFAECBFA,
  ); // Lighter blue for route fill
  static const Color routeBorder = Color(0xFF4285F4); // Blue border for route
  static const Color routeAlt = Color(0xFF8A2BE2); // Purple alternative
  static const Color routeAltDark = Color(0xFF6A0DAD); // Dark purple variant

  // Map UI Colors - Multiple Route Colors (for different bus/train lines)
  static const Color routeRed = Color(0xFFEA4335); // Red Line
  static const Color routeBlue = Color(0xFF4285F4); // Blue Line
  static const Color routeGreen = Color(0xFF34A853); // Green Line
  static const Color routeYellow = Color(0xFFFBBC05); // Yellow Line
  static const Color routePurple = Color(0xFF8A2BE2); // Purple Line
  static const Color routeOrange = Color(0xFFFF6D01); // Orange Line

  // Map UI Colors - Status & Alert Colors (Traffic Light System)
  static const Color statusOnTime = Color(
    0xFF34A853,
  ); // Green - On Time, Good Service
  static const Color statusDelay = Color(
    0xFFFBBC05,
  ); // Yellow/Amber - Delay, Minor Disruption
  static const Color statusCancelled = Color(
    0xFFEA4335,
  ); // Red - Significant Delay, Cancellation
  static const Color statusInactive = Color(
    0xFF9AA0A6,
  ); // Grey - Inactive, No Data, Completed

  // Map UI Colors - Background and UI
  static const Color mapBackgroundLight = Color(0xFFFFFFFF);
  static const Color mapBackgroundDark = Color(0xFF1F2937);
  static const Color mapTextPrimary = Color(0xFF1F2937);
  static const Color mapTextSecondary = Color(0xFF6B7280);
  static const Color mapBorder = Color(0xFFE5E7EB);

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
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
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

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
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
          foregroundColor: Colors.black,
          side: const BorderSide(color: Colors.black),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
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

      // Text Theme
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 22.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textPrimary,
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

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryVariant,
        secondary: secondaryColor,
        secondaryContainer: secondaryVariant,
        error: errorColor,
        surface: Color(0xFF1F2937),
        background: Color(0xFF111827),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.white,
        onBackground: Colors.white,
      ),

      // Similar theme configuration for dark mode
      // ... (implement dark theme variants)
    );
  }
}
