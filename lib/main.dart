import 'package:flutter/material.dart';
import 'job_app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(const JobApp());
}

