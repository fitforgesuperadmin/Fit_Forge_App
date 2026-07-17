import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0C0C0C);
  static const Color surface = Color(0xFF161616);
  static const Color elevatedSurface = Color(0xFF1F1F1F);
  
  static const Color primaryAccent = Color(0xFF9E9E9E);
  static const Color strongAccent = Color(0xFFCECECE);
  
  static const Color primaryText = Color(0xFFF0F0F0);
  static const Color secondaryText = Color(0xFF888888);
  static const Color muted = Color(0xFF555555);
  static const Color border = Color(0xFF2A2A2A);
  
  static const Color error = Color(0xFFEF4444);
  
  static const Color progressFill = Color(0xFFB0B0B0);
  static const Color progressTrack = Color(0xFF2C2C2C);
}

class AppTextStyles {
  // Heading styles
  static final TextStyle h1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryText,
  );
  
  static final TextStyle h2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );
  
  static final TextStyle h3 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  // Body styles
  static final TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.primaryText,
  );
  
  static final TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );
  
  static final TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.secondaryText,
  );
  
  // Label styles
  static final TextStyle labelLarge = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: 0.04 * 14, // 0.04em
  );
  
  static final TextStyle labelAllcaps = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
    letterSpacing: 0.04 * 12, // 0.04em
  );
  
  // Data styles (Roboto Mono)
  static final TextStyle dataLarge = GoogleFonts.robotoMono(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );
  
  static final TextStyle dataMedium = GoogleFonts.robotoMono(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );
  
  static final TextStyle dataSmall = GoogleFonts.robotoMono(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primaryAccent,
      cardColor: AppColors.surface,
      dividerColor: AppColors.border,
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.strongAccent),
        ),
        hintStyle: AppTextStyles.bodyMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.strongAccent,
          foregroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.background),
          elevation: 0,
        ),
      ),
    );
  }
}
