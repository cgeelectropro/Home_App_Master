import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_app/theme/color.dart';

///darkTheme
ThemeData darkTheme = ThemeData(
  textTheme: TextTheme(
    titleLarge: GoogleFonts.arvo(color: AppColors.textColor2_dark),
    titleMedium: GoogleFonts.arvo(color: AppColors.textColor2_dark),
    titleSmall: GoogleFonts.arvo(color: AppColors.textColor_dark),
    headlineMedium: GoogleFonts.arvo(color: AppColors.textColor_dark),
    headlineSmall: GoogleFonts.arvo(color: AppColors.textColor2_dark),
    displayLarge: GoogleFonts.arvo(color: AppColors.textColor2_dark),
    displayMedium: GoogleFonts.arvo(color: AppColors.textColor_dark),
    displaySmall: GoogleFonts.arvo(color: AppColors.textColor2_dark),
    bodyLarge: GoogleFonts.arvo(color: AppColors.textColor_dark),
    bodyMedium: GoogleFonts.arvo(color: AppColors.textColor2_dark),
  ),
  scaffoldBackgroundColor: AppColors.backgroundColor_dark,
  primaryColor: AppColors.primaryColor_dark,
  iconTheme: const IconThemeData(color: AppColors.iconsColor_dark),
  cardColor: AppColors.cardColor_dark,
  colorScheme: const ColorScheme.dark(secondary: AppColors.accentColor_dark),
  dialogTheme: const DialogTheme(elevation: 0),
  dialogBackgroundColor: AppColors.cardColor_dark,
  canvasColor: AppColors.backgroundColor_dark,
  hoverColor: AppColors.accentColor_dark.withAlpha((0.2 * 255).toInt()),
  highlightColor: AppColors.accentColor_dark.withAlpha((0.4 * 255).toInt()),
  dividerColor: AppColors.dividerColor_dark,
);

///lightTheme
ThemeData lightTheme = ThemeData(
  textTheme: TextTheme(
    titleLarge: GoogleFonts.arvo(color: AppColors.textColor_light),
    titleMedium: GoogleFonts.arvo(color: AppColors.textColor2_light),
    titleSmall: GoogleFonts.arvo(color: AppColors.textColor_light),
    headlineMedium: GoogleFonts.arvo(color: AppColors.textColor_light),
    headlineSmall: GoogleFonts.arvo(color: AppColors.textColor2_light),
    displayLarge: GoogleFonts.arvo(color: AppColors.textColor2_light),
    displayMedium: GoogleFonts.arvo(color: AppColors.textColor_light),
    displaySmall: GoogleFonts.arvo(color: AppColors.textColor2_light),
    bodyLarge: GoogleFonts.arvo(color: AppColors.textColor_light),
    bodyMedium: GoogleFonts.arvo(color: AppColors.textColor2_light),
  ),
  scaffoldBackgroundColor: AppColors.backgroundColor_light,
  primaryColor: AppColors.primaryColor_light,
  iconTheme: const IconThemeData(color: AppColors.iconsColor_light),
  cardColor: AppColors.cardColor_light,
  colorScheme: const ColorScheme.light(secondary: AppColors.accentColor_light),
  dialogTheme: const DialogTheme(elevation: 0),
  dialogBackgroundColor: AppColors.cardColor_light,
  canvasColor: AppColors.backgroundColor_light,
  hoverColor: AppColors.primaryColor_light.withAlpha((0.2 * 255).toInt()),
  highlightColor: AppColors.primaryColor_light.withAlpha((0.4 * 255).toInt()),
  dividerColor: AppColors.dividerColor_light,
);
