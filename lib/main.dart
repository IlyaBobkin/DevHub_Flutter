import 'package:DevHub/repositories/main/api_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart'; // Для проверки токена
import 'job_app.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    print("Handling a background message: ${message.messageId}");
  } catch (e) {
    print("Error in background handler: $e");
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Настройка FCM для обработки фоновых сообщений
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  // Получаем FCM-токен
  final fcmToken = await FirebaseMessaging.instance.getToken();
  String? accessToken = prefs.getString('access_token');
  final refreshToken = prefs.getString('refresh_token');

  final apiService = ApiService();
  //apiService.registerUsers();

  // Проверяем и обновляем токен, если он истек
  if (accessToken != null && refreshToken != null) {
    try {
      if (await apiService.isTokenExpired(accessToken)) {
        try {
          accessToken = await apiService.refreshAccessToken(refreshToken, prefs);
        } catch (e) {
          print('Refresh token failed: $e. Redirecting to login.');
          await prefs.clear();
          runApp(JobApp(initialRoute: '/login'));
          return;
        }
      }

      // Загружаем данные пользователя
      final userInfo = await apiService.fetchUserInfo(accessToken);
      final profile = await apiService.fetchProfile(accessToken);

      await prefs.setString('user_id', userInfo['sub'] ?? '');
      await prefs.setString('name', userInfo['name'] ?? profile['name'] ?? '');
      await prefs.setString('email', userInfo['email'] ?? '');
      final roles = userInfo['realm_access']?['roles'] as List<String>?;
      String role = '';
      if (roles != null) {
        if (roles.contains('company_owner')) {
          role = 'company_owner';
        } else if (roles.contains('applicant')) {
          role = 'applicant';
        }
      }
      await prefs.setString('role', role);
      await prefs.setString('created_at', profile['created_at'] ?? DateTime.now().toIso8601String());
      await prefs.setString('companyId', profile['companyId'] ?? '');
      await prefs.setString('companyName', profile['companyName'] ?? '');
      await prefs.setString('companyDescription', profile['companyDescription'] ?? '');

      // Сохраняем и отправляем FCM-токен, если он есть
      if (fcmToken != null) {
        await apiService.saveFcmToken(fcmToken);
      }
    } catch (e) {
      print('Initialization failed: $e');
      await prefs.clear();
      runApp(JobApp(initialRoute: '/hello'));
      return;
    }
  } else {
    // Если токенов нет, переходим на экран логина
    runApp(JobApp(initialRoute: '/hello'));
    return;
  }

  // Запускаем приложение с определенным маршрутом
  final userId = prefs.getString('user_id');
  final initialRoute = userId != null ? '/main' : '/hello';
  runApp(JobApp(initialRoute: initialRoute));
}

void main() async {
  await initializeApp();
}