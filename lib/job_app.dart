import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_project/router/router.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class JobApp extends StatelessWidget {
  const JobApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0x70a9ed)),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      routes: routes,
    );
  }
}

Future<void> initializeApp() async {
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('access_token');
  final refreshToken = prefs.getString('refresh_token');

  if (accessToken != null && refreshToken != null) {
    try {
      // Проверка токена и загрузка данных пользователя
      final userInfo = await fetchUserInfo(accessToken);
      final profile = await fetchProfile(accessToken);

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

      // Периодическое обновление токена (например, каждые 10 минут, чтобы не превышать лимиты)
      Future<void>.delayed(const Duration(minutes: 10), () async {
        while (true) {
          await Future.delayed(const Duration(minutes: 10));
          try {
            final newTokens = await refreshTokens(refreshToken);
            final newAccessToken = newTokens['access_token'] as String?;
            final newRefreshToken = newTokens['refresh_token'] as String?;

            if (newAccessToken != null && newRefreshToken != null) {
              await prefs.setString('access_token', newAccessToken);
              await prefs.setString('refresh_token', newRefreshToken);
              print('Token refreshed successfully: $newAccessToken');
            } else {
              throw Exception('Failed to refresh token: No new tokens received.');
            }
          } catch (e) {
            print('Failed to refresh token: $e');
            await prefs.clear();
            break;
          }
        }
      });
    } catch (e) {
      print('Initialization failed: $e');
      await prefs.clear();
    }
  }
}

Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
  final response = await http.post(
    Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/token'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': 'frontend',
      'client_secret': 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp', // Твой Client Secret
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to refresh token: ${response.statusCode} - ${response.body}');
  }
}

Future<Map<String, dynamic>> fetchUserInfo(String token) async {
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch user info: ${response.statusCode} - ${response.body}');
  }
}

Future<Map<String, dynamic>> fetchProfile(String token) async {
  final response = await http.get(
    Uri.parse('http://10.0.2.2:8080/user/profile'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch profile: ${response.statusCode} - ${response.body}');
  }
}