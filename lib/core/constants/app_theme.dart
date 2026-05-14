import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Tam adres ile import (En güvenlisi)
import 'package:unilife/core/constants/app_colors.dart'; 

class AppTheme {
  // --- AYDINLIK TEMA ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    
    // RENK ŞEMASI (En Önemli Kısım)
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceLight,
      background: AppColors.backgroundLight,
      error: AppColors.error,
    ),

    // Yazı Tipi
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textLight),
      titleTextStyle: TextStyle(
        color: AppColors.textLight, 
        fontSize: 22, 
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // --- KARANLIK TEMA ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surfaceDark,
      background: AppColors.backgroundDark,
      error: AppColors.error,
    ),
    
    // Yazı Tipi
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: AppColors.textDark,
      displayColor: AppColors.textDark,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(
        color: AppColors.textDark, 
        fontSize: 22, 
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}