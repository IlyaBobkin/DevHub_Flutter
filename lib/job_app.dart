import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_project/themes/themes.dart';
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
  List<ThemeData> _themes = themes;

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