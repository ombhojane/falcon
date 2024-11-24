import 'package:flutter/material.dart';

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
  
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundDark,
    primaryColor: primary,
    
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundDark,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textLight,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        color: textGrey,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: textLight,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textGrey,
        fontSize: 14,
      ),
    ),
  );
} 