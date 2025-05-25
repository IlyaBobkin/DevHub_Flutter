import 'dart:convert';
import 'package:DevHub/router/router.dart';
import 'package:DevHub/themes/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global ValueNotifier for theme index
final ValueNotifier<int> themeIndexNotifier = ValueNotifier<int>(0);

class JobApp extends StatefulWidget {
  final String initialRoute;

  const JobApp({
    super.key,
    required this.initialRoute,
  });

  @override
  State<JobApp> createState() => _JobAppState();
}

class _JobAppState extends State<JobApp> {
  final List<ThemeData> _themes = themes;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _setupFirebaseMessaging();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeIndex') ?? 0;
    themeIndexNotifier.value = themeIndex;
  }

  Future<void> _setupFirebaseMessaging() async {
    // Запрашиваем разрешение на уведомления
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Обработка foreground-уведомлений
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }
    });

    // Обработка уведомлений при открытии приложения из уведомления
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked! Navigating to notifications screen.');
      Navigator.pushNamed(context, '/notifications');
    });

    // Проверяем, если приложение открыто из уведомления
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from a terminated state via notification.');
      Navigator.pushNamed(context, '/notifications');
    }
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