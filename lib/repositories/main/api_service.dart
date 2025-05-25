import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/vacancy.dart';

class ApiService {
  static const String _apiAddress = 'http://192.168.1.157:8080';
  static const String _keycloakAddress = 'http://192.168.1.157:8086';
  //static const String _apiAddress = 'http://31.207.77.35:8080';
  //static const String _keycloakAddress = 'http://31.207.77.35:8086';

  final Dio _dio = Dio();

  Future<Response> apiFetch(String path, {required String method, dynamic data, bool requiresAuth = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (requiresAuth && accessToken == null) {
      debugPrint('No access token found, redirecting to login');
      throw Exception('Токен авторизации отсутствует. Пожалуйста, войдите заново.');
    }

    final headers = {
      'Content-Type': 'application/json',
      if (requiresAuth) 'Authorization': 'Bearer $accessToken',
    };

    try {
      debugPrint('Making request to $_apiAddress$path with token: $accessToken');
      final response = await _dio.request(
        '$_apiAddress$path',
        options: Options(method: method, headers: headers),
        data: data != null ? jsonEncode(data) : null,
      );

      if (response.statusCode == 401 && refreshToken != null) {
        debugPrint('Received 401, attempting to refresh token');
        final refreshResponse = await _dio.post(
          '$_keycloakAddress/realms/hh_realm/protocol/openid-connect/token',
          data: {
            'grant_type': 'refresh_token',
            'client_id': 'frontend',
            'refresh_token': refreshToken,
          },
          options: Options(contentType: 'application/x-www-form-urlencoded'),
        );

        if (refreshResponse.statusCode == 200) {
          final tokenData = refreshResponse.data as Map<String, dynamic>;
          await prefs.setString('access_token', tokenData['access_token']);
          await prefs.setString('refresh_token', tokenData['refresh_token']);
          debugPrint('Token refreshed successfully: ${tokenData['access_token']}');

          headers['Authorization'] = 'Bearer ${tokenData['access_token']}';
          return await _dio.request(
            '$_apiAddress$path',
            options: Options(method: method, headers: headers),
            data: data != null ? jsonEncode(data) : null,
          );
        } else {
          debugPrint('Failed to refresh token: ${refreshResponse.statusCode} - ${refreshResponse.data}');
          await prefs.clear();
          throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
        }
      }

      if (response.statusCode == 403) {
        debugPrint('Received 403 Forbidden for path: $path');
        throw Exception('Доступ запрещён: недостаточно прав для выполнения запроса.');
      }

      return response;
    } catch (e) {
      debugPrint('API Error: $e');
      throw Exception('Ошибка запроса: $e');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? companyName,
    String? companyDescription,
  }) async {
    final data = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (companyName != null) 'companyName': companyName,
      if (companyDescription != null) 'companyDescription': companyDescription,
    };

    debugPrint('Register data: $data');
    final response = await apiFetch('/user/register', method: 'POST', data: data);
    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('Register response error: ${response.statusCode} - ${response.data}');
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка регистрации');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final data = {
      'username': email,
      'password': password,
      'grant_type': 'password',
      'client_id': 'frontend',
      'client_secret': 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp',
      'scope': 'openid profile email',
    };

    final response = await _dio.post(
      '$_keycloakAddress/realms/hh_realm/protocol/openid-connect/token',
      data: data,
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );

    if (response.statusCode == 200) {
      final tokenData = response.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', tokenData['access_token']);
      await prefs.setString('refresh_token', tokenData['refresh_token']);
      return tokenData;
    } else {
      throw Exception('Ошибка входа: ${response.statusCode} - ${response.data}');
    }
  }

  // Работа с вакансиями
  Future<Map<String, dynamic>> createVacancy({
    required String userId,
    required String companyId,
    required String title,
    required String description,
    required num salaryFrom,
    num? salaryTo,
    required String specializationId,
    required String experienceLevel,
    required String location,
  }) async {
    final data = {
      'user_id': userId,
      'company_id': companyId,
      'title': title,
      'description': description,
      'salary_from': salaryFrom,
      'salary_to': salaryTo,
      'specialization_id': specializationId,
      'experience_level': experienceLevel,
      'location': location,
    };

    final response = await apiFetch('/vacancies', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка при создании вакансии');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getMyVacancies() async {
    final response = await apiFetch('/vacancies/my', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки вакансий');
    }
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> updateVacancy(String vacancyId, {
    required String userId,
    required String companyId,
    required String title,
    required String description,
    required num salaryFrom,
    num? salaryTo,
    required String specializationId,
    required String experienceLevel,
    required String location,
  }) async {
    final data = {
      'user_id': userId,
      'company_id': companyId,
      'title': title,
      'description': description,
      'salary_from': salaryFrom,
      'salary_to': salaryTo,
      'specialization_id': specializationId,
      'experience_level': experienceLevel,
      'location': location,
    };

    final response = await apiFetch('/vacancies/$vacancyId', method: 'PATCH', data: data, requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка при обновлении вакансии');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteVacancy(String vacancyId, String userId) async {
    final response = await apiFetch('/vacancies/$vacancyId', method: 'DELETE', requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка удаления вакансии');
    }
  }

  Future<List<dynamic>> getAllVacancies() async {
    final response = await apiFetch('/vacancies/all', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки вакансий');
    }
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getVacancyResponses(String vacancyId) async {
    final response = await apiFetch('/vacancies/$vacancyId/responses', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки откликов');
    }
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createVacancyResponse(String vacancyId, String message, {required String userId}) async {
    final data = {
      'message': message,
      'user_id': userId,
    };
    final response = await apiFetch(
      '/vacancies/$vacancyId/responses',
      method: 'POST',
      data: data,
      requiresAuth: true,
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      debugPrint('Error response: ${response.data}');
      throw Exception('Ошибка отправки отклика: ${response.data}');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyVacancyResponses() async {
    final response = await apiFetch('/responses/vacancies', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки откликов');
    }
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getOwnerVacancyResponses() async {
    final response = await apiFetch('/responses/vacancies-owner', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки откликов');
    }
    return response.data as List<dynamic>;
  }

  Future<Vacancy> getVacancyById(String vacancyId) async {
    final response = await apiFetch('/vacancy/$vacancyId', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки вакансии');
    }
    return Vacancy.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<dynamic>> getMyVacancyInvitations() async {
    final response = await apiFetch('/responses/vacancies-invited', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки приглашений');
    }
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> getSentVacancyInvitations() async {
    final response = await apiFetch('/responses/vacancies-owner-invited', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки приглашений');
    }
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createVacancyInvitation(
      String id,
      String vacancyId,
      String companyOwnerId,
      String applicantId,
      String message,
      ) async {
    final data = {
      'id': id,
      'vacancyId': vacancyId,
      'companyOwnerId': companyOwnerId,
      'applicantId': applicantId,
      'message': message,
    };
    final response = await apiFetch('/vacancies/$vacancyId/invitations', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка создания приглашения');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVacancyResponseStatus(String vacancyId, String responseId, String status) async {
    final data = {'status': status};
    final response = await apiFetch('/vacancies/$vacancyId/responses/$responseId', method: 'PATCH', data: data, requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Не удалось обновить отклик');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateVacancyInvitationStatus(String vacancyId, String invitationId, String status) async {
    final data = {'status': status};
    final response = await apiFetch('/vacancies/$vacancyId/invitations/$invitationId', method: 'PATCH', data: data, requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Не удалось обновить приглашение');
    }
    return response.data as Map<String, dynamic>;
  }

  // Работа с резюме
  Future<Map<String, dynamic>> createResume({
    required String id,
    required String userId,
    required String title,
    required String description,
    num? expectedSalary,
    required String specializationId,
    required String experienceLevel,
    required String location,
  }) async {
    final data = {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      if (expectedSalary != null) 'expected_salary': expectedSalary,
      'specialization_id': specializationId,
      'experience_level': experienceLevel,
      'location': location,
    };

    final response = await apiFetch('/resumes', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка создания резюме');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getMyResume() async {
    try {
      final response = await apiFetch('/resumes/my', method: 'GET', requiresAuth: true);
      if (response.statusCode != 200) {
        throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки резюме');
      }
      return response.data as Map<String, dynamic>;
    } catch (e) {
      if (e.toString().contains('404')) {
        debugPrint('Резюме не найдено (404), возвращаем null');
        return null;
      }
      debugPrint('Ошибка получения резюме: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> updateResume(String resumeId, {
    required String userId,
    required String title,
    required String description,
    num? expectedSalary,
    required String specializationId,
    required String experienceLevel,
    required String location,
  }) async {
    final data = {
      'user_id': userId,
      'title': title,
      'description': description,
      if (expectedSalary != null) 'expected_salary': expectedSalary,
      'specialization_id': specializationId,
      'experience_level': experienceLevel,
      'location': location,
    };

    final response = await apiFetch('/resumes/$resumeId', method: 'PATCH', data: data, requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка обновления резюме');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteResume(String resumeId) async {
    final response = await apiFetch('/resumes/$resumeId', method: 'DELETE', requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка удаления резюме');
    }
  }

  Future<List<dynamic>> getAllResumes() async {
    final response = await apiFetch('/resumes/all', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки резюме');
    }
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getResumeById(String resumeId) async {
    final response = await apiFetch('/resume/$resumeId', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки резюме');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getResumeByUserId(String userId) async {
    final response = await apiFetch('/resume/user/$userId', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки резюме');
    }
    return response.data as Map<String, dynamic>;
  }

  // Работа с чатами
  Future<List<Map<String, dynamic>>> getChatsList() async {
    final response = await apiFetch('/chats', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки чатов');
    }
    final data = response.data as List<dynamic>;
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    return Future.wait(data.map((c) async {
      final opponentId = c['applicant_id'] == userId ? c['company_owner_id'] : c['applicant_id'];
      final vacancyId = c['vacancy_id'];
      final opponentProfile = await getUserProfileById(opponentId!);
      final vacancy = await getVacancyById(vacancyId);
      return {
        'id': c['id'],
        'opponentName': opponentProfile['name'],
        'vacancyName': vacancy.title,
        'createdAt': c['created_at'],
      };
    }));
  }

  Future<Map<String, dynamic>> createChat({
    required String applicantId,
    required String companyOwnerId,
    required String vacancyId,
  }) async {
    final data = {
      'applicant_id': applicantId,
      'company_owner_id': companyOwnerId,
      'vacancy_id': vacancyId,
    };

    final response = await apiFetch('/chats', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Не удалось создать чат');
    }
    return response.data as Map<String, dynamic>;
  }

  // Работа с сообщениями
  Future<List<Map<String, dynamic>>> loadMessages(String chatId) async {
    final response = await apiFetch('/chats/$chatId/messages', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки сообщений');
    }
    return (response.data as List<dynamic>).map((m) => {
      'id': m['id'],
      'senderId': m['sender_id'],
      'text': m['text'],
      'createdAt': m['created_at'],
    }).toList();
  }

  Future<Map<String, dynamic>> sendMessage(String chatId, String text) async {
    final data = {'text': text};
    final response = await apiFetch('/chats/$chatId/messages', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка отправки сообщения');
    }
    return response.data as Map<String, dynamic>;
  }

  // Работа с профилями пользователей
  Future<Map<String, dynamic>> getUserProfileById(String userId) async {
    final response = await apiFetch('/user/profile/$userId', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки профиля пользователя');
    }
    return response.data as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getSpecializations() async {
    final response = await apiFetch('/specializations', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки специализаций');
    }
    return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  // Работа с FCM-токеном
  Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      throw Exception('User ID not found');
    }
    final data = {'fcm_token': fcmToken};
    final response = await apiFetch('/fcm-token', method: 'POST', data: data, requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка сохранения FCM-токена');
    }
  }

  // Работа с уведомлениями
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final response = await apiFetch('/notifications', method: 'GET', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка загрузки уведомлений');
    }
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final response = await apiFetch('/notifications/$notificationId/read', method: 'POST', requiresAuth: true);
    if (response.statusCode != 200) {
      throw Exception((response.data as Map<String, dynamic>)['error'] ?? 'Ошибка пометки уведомления как прочитанного');
    }
  }

/*  Future<void> initializeApp(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    var accessToken = prefs.getString('access_token');
    final refreshToken = prefs.getString('refresh_token');

    if (accessToken != null && refreshToken != null) {
      try {
        // Проверка токена и загрузка данных пользователя
        if (await isTokenExpired(accessToken)) {
          try {
            accessToken = await refreshAccessToken(refreshToken, prefs);
          } catch (e) {
            debugPrint('Refresh token failed: $e. Redirecting to login.');
            await prefs.clear();
            Navigator.pushReplacementNamed(context, '/login');
            return;
          }
        }

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

        // Периодическое обновление токена
        _startTokenRefreshLoop(prefs, refreshToken, context);
      } catch (e) {
        debugPrint('Initialization failed: $e');
        await prefs.clear();
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }*/

// Проверка истечения токена
  Future<bool> isTokenExpired(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      final expiry = payload['exp'] as int?;
      if (expiry == null) return true;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiry < now;
    } catch (e) {
      debugPrint('Error checking token expiry: $e');
      return true;
    }
  }

// Обновление токена
  Future<String> refreshAccessToken(String refreshToken, SharedPreferences prefs) async {
    final response = await _dio.post(
      '$_keycloakAddress/realms/hh_realm/protocol/openid-connect/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': 'frontend',
        'client_secret': 'QMtjD85G7WZ6ZWE5SdIV6MaA3393Qrgp',
      },
      options: Options(contentType: 'application/x-www-form-urlencoded'),
    );
    if (response.statusCode == 200) {
      final tokenData = response.data as Map<String, dynamic>;
      final newAccessToken = tokenData['access_token'] as String?;
      final newRefreshToken = tokenData['refresh_token'] as String?;
      if (newAccessToken != null && newRefreshToken != null) {
        await prefs.setString('access_token', newAccessToken);
        await prefs.setString('refresh_token', newRefreshToken);
        debugPrint('Token refreshed successfully: $newAccessToken');
        return newAccessToken;
      }
      throw Exception('No new tokens received');
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode} - ${response.data}');
    }
  }

/*// Периодическое обновление токена
  void _startTokenRefreshLoop(SharedPreferences prefs, String refreshToken, BuildContext context) {
    Future<void>.delayed(const Duration(minutes: 5), () async {
      while (true) {
        await Future.delayed(const Duration(minutes: 5));
        try {
          final accessToken = await refreshAccessToken(refreshToken, prefs);
          debugPrint('Token refreshed periodically: $accessToken');
        } catch (e) {
          debugPrint('Periodic token refresh failed: $e');
          await prefs.clear();
          Navigator.pushReplacementNamed(context, '/login');
          break;
        }
      }
    });
  }*/

  Future<Map<String, dynamic>> fetchUserInfo(String token) async {
    final response = await _dio.get(
      '$_keycloakAddress/realms/hh_realm/protocol/openid-connect/userinfo',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch user info: ${response.statusCode} - ${response.data}');
    }
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await _dio.get(
      '$_apiAddress/user/profile',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch profile: ${response.statusCode} - ${response.data}');
    }
  }



/*  void registerUsers() async {
    final api = ApiService();
    final prefs = await SharedPreferences.getInstance();
    final random = Random();

    // Определение уровней опыта, местоположений и специализаций
    final experienceLevels = ['junior', 'middle', 'senior'];
    final locations = ['Москва', 'Санкт-Петербург', 'Казань', 'Новосибирск', 'Екатеринбург', 'Воронеж', 'Нижний Новгород', 'Ростов-на-Дону'];

    // Получение специализаций из API
    final specializations = await api.getSpecializations();
    if (specializations.isEmpty) {
      print('Нет доступных специализаций');
      return;
    }

    // Функции для получения случайных данных
    String getRandomExperience() => experienceLevels[random.nextInt(experienceLevels.length)];
    String getRandomLocation() => locations[random.nextInt(locations.length)];

    // Данные работодателей с привязкой к специализациям
    final employers = [
      {
        'name': 'ООО ТехСофт',
        'email': 'hr@techsoft.ru',
        'specializationId': '11933bc1-da4f-4703-80b4-11df98341c32', // Mobile Developer (iOS/Android)
        'vacancy': 'Мобильный разработчик Flutter',
        'desc': 'Мы ищем опытного мобильного разработчика Flutter для работы над инновационным приложением для электронной коммерции. Проект включает разработку сложных UI/UX, интеграцию с REST API, Firebase и Stripe для платежей. Вы будете работать в команде из 15 разработчиков, участвовать в проектировании архитектуры и внедрении CI/CD. Мы предлагаем гибкий график, удаленную работу и бонусы за успешные релизы.',
        'salaryFrom': 130000,
        'salaryTo': 160000,
      },
      {
        'name': 'АО ВебПро',
        'email': 'jobs@webpro.ru',
        'specializationId': '16011ab0-c524-4399-b947-ac5bb7a6886a', // Frontend Developer
        'vacancy': 'Frontend Developer (React)',
        'desc': 'Приглашаем Frontend Developer с опытом работы в React и Vue для разработки современных интерфейсов. Вы будете работать над проектами с миллионами пользователей, включая локализацию на 10 языков и интеграцию с GraphQL. Мы используем современный стек технологий (TypeScript, Webpack, Redux), предоставляем обучение и участие в международных конференциях. Гибкий график и офис в центре города.',
        'salaryFrom': 150000,
        'salaryTo': 180000,
      },
      {
        'name': 'ООО ИнфоБит',
        'email': 'hr@infobit.ru',
        'specializationId': '2a9a91e8-2321-45f1-82b8-8d13a8d69826', // Automation QA Engineer
        'vacancy': 'Automation QA Engineer',
        'desc': 'Ищем Automation QA Engineer для покрытия автотестами API и UI наших проектов. Вы будете работать с Selenium, Appium и Java, разрабатывать тест-кейсы и интегрировать их в CI/CD пайплайн. Проект включает тестирование Flutter-приложений и веб-сервисов с миллионами пользователей. Мы предлагаем обучение новым инструментам, комфортный офис и возможность карьерного роста.',
        'salaryFrom': 110000,
        'salaryTo': 140000,
      },
      {
        'name': 'Digital Solutions',
        'email': 'careers@digisol.ru',
        'specializationId': '844fe14d-66d9-41c1-8752-a8c6186ce84a', // UI/UX Designer
        'vacancy': 'UI/UX Designer',
        'desc': 'Приглашаем UI/UX Designer для работы над дизайном мобильных и веб-приложений с глобальным охватом. Вы будете проводить исследования пользователей, создавать прототипы в Figma и тесно сотрудничать с разработчиками Flutter. Проект включает A/B тестирование и внедрение передовых стандартов UX. Мы предлагаем удаленную работу, доступ к премиум-инструментам и участие в международных проектах.',
        'salaryFrom': 145000,
        'salaryTo': 175000,
      },
      {
        'name': 'SecureTech',
        'email': 'hr@securetech.ru',
        'specializationId': '0850d43e-5716-43d6-9899-4d17137a1fc0', // Cybersecurity Engineer
        'vacancy': 'Cybersecurity Engineer',
        'desc': 'Ищем Cybersecurity Engineer для проведения аудитов безопасности и защиты данных. Задачи включают тесты на проникновение, разработку политик безопасности (ISO 27001, GDPR) и защиту приложений, включая Flutter. Вы будете работать с Nessus, Metasploit и Wireshark, участвовать в проектах с миллионами пользователей. Мы предлагаем бонусы за успешные аудиты и гибкий график.',
        'salaryFrom': 170000,
        'salaryTo': 200000,
      },
      {
        'name': 'CloudLine',
        'email': 'team@cloudline.ru',
        'specializationId': '60384426-b477-4a82-a182-055a344e101f', // DevOps Engineer
        'vacancy': 'DevOps Engineer',
        'desc': 'Требуется DevOps Engineer для настройки CI/CD и облачных решений (AWS, GCP). Вы будете работать с Docker, Kubernetes и Terraform, оптимизировать инфраструктуру для Flutter-приложений и внедрять мониторинг (Prometheus, Grafana). Проект включает высоконагруженные системы с миллионами пользователей. Мы предлагаем удаленную работу, участие в конференциях и карьерный рост.',
        'salaryFrom': 165000,
        'salaryTo': 195000,
      },
      {
        'name': 'AI Systems',
        'email': 'jobs@aisystems.ru',
        'specializationId': '36358281-9e8b-400b-a5b7-6dc87c8d075b', // Data Scientist
        'vacancy': 'Data Scientist',
        'desc': 'Приглашаем Data Scientist для работы с большими данными и моделями машинного обучения. Вы будете разрабатывать модели прогнозирования (Python, TensorFlow), интегрировать их с мобильными приложениями и создавать дашборды (Tableau). Проект включает анализ данных в реальном времени и работу с объемами до 15 TB. Мы предлагаем гибкий график, обучение новым технологиям и бонусы.',
        'salaryFrom': 190000,
        'salaryTo': 220000,
      },
      {
        'name': 'РосТехСеть',
        'email': 'recruit@rt-net.ru',
        'specializationId': '40c84fdb-c09e-497d-b3b0-ef868be408f4', // Systems Analyst
        'vacancy': 'Systems Analyst',
        'desc': 'Ищем Systems Analyst для описания бизнес-процессов и постановки задач разработчикам. Вы будете работать с проектами на Flutter и веб-сервисами, анализировать требования и взаимодействовать со стейкхолдерами. Мы используем BPMN, UML и Confluence для документации. Предлагаем комфортный офис, участие в международных проектах и бонусы за успешные релизы.',
        'salaryFrom': 140000,
        'salaryTo': 170000,
      },
      {
        'name': 'CodeWorks',
        'email': 'hr@codeworks.ru',
        'specializationId': 'e34d82ec-89f2-4592-9e46-05f7b150a0c8', // Backend Developer
        'vacancy': 'Backend Developer (Java)',
        'desc': 'Требуется Backend Developer для разработки микросервисов с использованием Java (Spring Boot). Вы будете проектировать масштабируемые API, интегрировать их с Kafka и работать с PostgreSQL/MongoDB. Проект включает высоконагруженные системы с миллионами пользователей. Мы предлагаем удаленную работу, участие в хакатонах и карьерный рост до архитектора.',
        'salaryFrom': 160000,
        'salaryTo': 190000,
      },
      {
        'name': 'SoftFox',
        'email': 'vacancy@softfox.ru',
        'specializationId': '115fb85f-8e22-459f-b80a-900f27bd9124', // Project Manager
        'vacancy': 'Project Manager',
        'desc': 'Приглашаем Project Manager для управления Agile-командами (до 20 человек). Вы будете координировать проекты на Flutter и веб-сервисы, контролировать сроки, бюджеты и коммуникацию со стейкхолдерами. Мы используем Jira, Confluence и MS Project, предоставляем обучение и участие в международных проектах. Гибкий график и бонусы за успешные запуски.',
        'salaryFrom': 175000,
        'salaryTo': 205000,
      },
    ];

    // Создание работодателей
    for (final e in employers) {
      try {
        // Логин под текущим пользователем
        final loginResponse = await api.login(email: e['email'].toString(), password: 'Test123!', role: 'company_owner');
        final accessToken = loginResponse['access_token'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', loginResponse['refresh_token'] as String);
        print('Успешный логин для ${e['email']}');

        // Получение профиля пользователя для получения companyId
        final profile = await api.fetchProfile(accessToken);
        final companyId = profile['companyId'] as String?;

        // Сохранение companyId в SharedPreferences
        if (companyId != null && companyId.isNotEmpty) {
          await prefs.setString('companyId', companyId);
          print('Сохранен companyId: $companyId для ${e['name']}');
        } else {
          print('Ошибка: companyId не получен для ${e['name']}. Проверьте API-ответ: $profile');
          continue;
        }

        final userId = prefs.getString('user_id') ?? '';
        if (userId.isEmpty) {
          print('Ошибка: userId не найден для ${e['name']}. Проверьте инициализацию.');
          continue;
        }

        final level = getRandomExperience();
        final location = getRandomLocation();

        // Вывод данных запроса для отладки
        print('Создание вакансии для ${e['name']}: userId=$userId, companyId=$companyId, title=${e['vacancy']}, '
            'salaryFrom=${e['salaryFrom']}, salaryTo=${e['salaryTo']}, specializationId=${e['specializationId']}, '
            'experienceLevel=$level, location=$location');

        await api.createVacancy(
          userId: userId,
          companyId: companyId,
          title: e['vacancy'].toString(),
          description: e['desc'].toString(),
          salaryFrom: e['salaryFrom'] as num,
          salaryTo: e['salaryTo'] as num,
          specializationId: e['specializationId'].toString(),
          experienceLevel: level,
          location: location,
        );
        print('Вакансия успешно создана для ${e['name']} | Specialization ID: ${e['specializationId']} | $level | $location');
      } catch (e) {
        print('Ошибка при создании вакансии для');
        if (e is DioException) {
          print('Детали ошибки: ${e.response?.data}');
        }
      }
    }
  }*/


}

