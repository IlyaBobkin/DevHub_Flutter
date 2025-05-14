import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_project/router/router.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class JobApp extends StatelessWidget {
  final String initialRoute;
  const JobApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'DevHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x70a9ed)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      routes: routes,
    );
  }
}
