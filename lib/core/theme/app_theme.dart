import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta de colores Premium
  static const Color darkCarbon = Color(0xff121214);
  static const Color midnightGrey = Color(0xff1e1e24);
  static const Color voltYellow = Color(0xffccff00);
  static const Color electricCyan = Color(0xff00f0ff);
  static const Color textPrimary = Color(0xffffffff);
  static const Color textSecondary = Color(0xffa0a0aa);
  static const Color dividerColor = Color(0xff2d2d34);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCarbon,
      cardColor: midnightGrey,
      primaryColor: voltYellow,
      
      colorScheme: const ColorScheme.dark(
        primary: voltYellow,
        secondary: electricCyan,
        surface: midnightGrey,
        background: darkCarbon,
        error: Colors.redAccent,
      ),

      // Configuración de textos usando Google Fonts (Outfit / Space Grotesk)
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkCarbon, // Contraste en botones amarillos
        ),
      ),

      // Estilos de tarjetas (Card)
      cardTheme: CardThemeData(
        color: midnightGrey,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: dividerColor, width: 1),
        ),
      ),

      // Estilos de botones elevados (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: voltYellow,
          foregroundColor: darkCarbon,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Estilos de inputs (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: midnightGrey,
        hintStyle: GoogleFonts.spaceGrotesk(color: textSecondary),
        labelStyle: GoogleFonts.spaceGrotesk(color: textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: voltYellow, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Estilo de sliders
      sliderTheme: const SliderThemeData(
        activeTrackColor: voltYellow,
        inactiveTrackColor: dividerColor,
        thumbColor: voltYellow,
        overlayColor: Color(0x29ccff00),
        valueIndicatorColor: voltYellow,
        valueIndicatorTextStyle: TextStyle(color: darkCarbon, fontWeight: FontWeight.bold),
      ),
    );
  }
}
