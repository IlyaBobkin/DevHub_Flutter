import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

List<ThemeData> themes = [
  // Light Theme
  ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: const Color(0xFF3672A6),
      secondary: const Color(0xFF4CAF50),
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black, error: Colors.white, onError: Colors.white,
    ),
    scaffoldBackgroundColor: Color(0xE4F8F8F8),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),
    useMaterial3: true,
  ),
  // Dark Theme
  ThemeData(
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFF3672A6),
      secondary: const Color(0xFF4CAF50),
      surface: const Color(0xFF131313),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white, error: Colors.black, onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF191919),
    textTheme: GoogleFonts.poppinsTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    useMaterial3: true,
  ),
];