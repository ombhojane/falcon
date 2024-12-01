import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const primary = Color(0xFF885FFF);    // Phantom's signature purple
  
  // Background colors
  static const backgroundDark = Color(0xFF0A0B0F);  // Deep space black
  static const cardDark = Color(0xFF1C1D21);        // Moonlight card
  static const surfaceDark = Color(0xFF2A2B2F);     // Subtle elevation
  
  // Text colors
  static const textLight = Color(0xFFF7F7F8);       // Crisp white
  static const textGrey = Color(0xFF8E8E93);        // Subtle text
  static const textDim = Color(0xFF636366);         // Dimmed text
  
  // Accent colors
  static const accentGreen = Color(0xFF32D74B);     // Success green
  static const accentRed = Color(0xFFFF453A);       // Error red
  
  // Text Styles
  static final _baseTextTheme = GoogleFonts.montserratTextTheme();

  static final TextStyle headlineLarge = GoogleFonts.montserrat(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textLight,
    letterSpacing: -0.5,
  );

  static final TextStyle headlineMedium = GoogleFonts.montserrat(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textLight,
    letterSpacing: -0.3,
  );

  static final TextStyle titleLarge = GoogleFonts.montserrat(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textLight,
    letterSpacing: 0.15,
  );

  static final TextStyle titleMedium = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textLight,
    letterSpacing: 0.1,
  );

  static final TextStyle bodyLarge = GoogleFonts.montserrat(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textLight,
    letterSpacing: 0.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textLight,
    letterSpacing: 0.25,
  );

  static final TextStyle bodySmall = GoogleFonts.montserrat(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textLight,
    letterSpacing: 0.4,
  );

  static final TextStyle labelLarge = GoogleFonts.montserrat(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textLight,
    letterSpacing: 0.1,
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primary,
    
    // Typography
    textTheme: _baseTextTheme.copyWith(
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
    ),
    
    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: textLight),
      titleTextStyle: titleLarge,
      toolbarHeight: 64, // Slightly taller for better spacing
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: bodyMedium.copyWith(color: textGrey),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    ),
    
    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}