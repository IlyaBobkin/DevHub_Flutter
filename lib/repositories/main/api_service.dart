import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'model/vacancy.dart';

class ApiService {
/*  static const String _apiAddress = 'http://10.0.2.2:8080';
  static const String _keycloakAddress = 'http://10.0.2.2:8086';  */
  static const String _apiAddress = 'http://192.168.1.157:8080';
  static const String _keycloakAddress = 'http://192.168.1.157:8086';
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

    debugPrint('Register data: $data'); // Логируем данные перед отправкой
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

// Получение резюме пользователя
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
        return null; // Если резюме нет, возвращаем null
      }
      debugPrint('Ошибка получения резюме: $e');
      throw e; // Пробрасываем другие ошибки
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
      final opponentProfile = await getUserProfileById(opponentId!);
      return {
        'id': c['id'],
        'opponentName': opponentProfile['name'],
        'contextTitle': c['context_title'],
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
    //Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/token'),
    Uri.parse('http://192.168.1.157:8086/realms/hh_realm/protocol/openid-connect/token'),
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
    Uri.parse('http://192.168.1.157:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
    //Uri.parse('http://10.0.2.2:8086/realms/hh_realm/protocol/openid-connect/userinfo'),
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
/*    Uri.parse('http://10.0.2.2:8080/user/profile'),*/
    Uri.parse('http://192.168.1.157:8080/user/profile'),
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    return Map<String, dynamic>.from(jsonDecode(response.body));
  } else {
    throw Exception('Failed to fetch profile: ${response.statusCode} - ${response.body}');
  }
}

