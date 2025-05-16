import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/router/router.dart';

// Global ValueNotifier for theme index
final ValueNotifier<int> themeIndexNotifier = ValueNotifier<int>(0);

class JobApp extends StatefulWidget {
  final String initialRoute;
  const JobApp({super.key, required this.initialRoute});

  @override
  State<JobApp> createState() => _JobAppState();
}

class _JobAppState extends State<JobApp> {
  final List<ThemeData> _themes = [
    // Light Theme
    ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF70A9ED),
        brightness: Brightness.light,
        primary: const Color(0xFF70A9ED),
        secondary: const Color(0xFF4CAF50),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      useMaterial3: true,
    ),
    // Dark Theme
    ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.dark,
        primary: const Color(0xFF70A9ED),
        secondary: const Color(0xFF4CAF50),
        surface: const Color(0xFF1E1E1E),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      useMaterial3: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeIndex') ?? 0;
    themeIndexNotifier.value = themeIndex;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: themeIndexNotifier,
      builder: (context, themeIndex, child) {
        return MaterialApp(
          title: 'DevHub',
          theme: _themes[themeIndex],
          initialRoute: widget.initialRoute,
          routes: routes,
        );
      },
    );
  }
}