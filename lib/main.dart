import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'job_app.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> initializeApp() async {
  await Firebase.initializeApp();

  // Получаем и сохраняем FCM-токен
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    final apiService = ApiService();
    await apiService.saveFcmToken(fcmToken);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();

  // Настройка FCM для обработки сообщений в фоновом режиме
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final userId = prefs.getString('user_id');
  final initialRoute = userId != null ? '/main' : '/hello';

  runApp(JobApp(initialRoute: initialRoute));
}