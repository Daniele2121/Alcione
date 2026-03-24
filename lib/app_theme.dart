import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AlcioneTheme {
  // Palette Colori Brand
  static const Color orangeAlcione = Color(0xFFFF6600);
  static const Color blueAlcione = Color(0xFF001D3D);
  static const Color blackOled = Color(0xFF000814);
  static const Color lightGrey = Color(0xFFF8F9FA);

  // --- TEMA CHIARO (Originale) ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightGrey,
      primaryColor: orangeAlcione,
      cardColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: orangeAlcione,
        primary: orangeAlcione,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.montserratTextTheme(),
    );
  }

  // --- TEMA SCURO (Elite Night) ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: blackOled,
      primaryColor: orangeAlcione,
      cardColor: blueAlcione,
      colorScheme: const ColorScheme.dark(
        primary: orangeAlcione,
        surface: blueAlcione,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
    );
  }
}