import 'package:flutter/material.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'job_app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(const JobApp());
}

