import 'package:flutter/material.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'job_app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final userId = prefs.getString('user_id');
  final initialRoute = userId != null ? '/main' : '/hello';

  runApp(JobApp(initialRoute: initialRoute));
}

