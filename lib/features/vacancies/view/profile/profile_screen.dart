import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import '../../../authorization/view/login_screen.dart';
import 'create_resume_screen.dart';
import 'edit_resume_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String? _userName;
  String? _userEmail;
  Map<String, dynamic>? _resume;
  List<Map<String, dynamic>> _specializations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Получаем информацию о пользователе
      String? _userId = prefs.getString('user_id');
      if (_userId == null) throw Exception('Пользователь не авторизован');
      final userInfo = await _apiService.getUserProfileById(_userId);
      // Проверяем наличие резюме
      final resume = await _apiService.getMyResume();
      // Загружаем список специализаций
      final specializations = await _apiService.getSpecializations();
      setState(() {
        _userName = userInfo['name'] ?? 'Не указано';
        _userEmail = userInfo['email'] ?? 'Не указано';
        _resume = resume;
        _specializations = specializations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  String? getSpecializationName(String? specializationId) {
    if (specializationId == null || _specializations.isEmpty) return 'Не указано';
    final specialization = _specializations.firstWhere(
          (spec) => spec['id'] == specializationId,
      orElse: () => {'name': 'Не указано'},
    );
    return specialization['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              child: const Text('Повторить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Карточка профиля
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Аватар
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Имя
                    Row(
                      children: [
                        Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Имя: $_userName",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Email
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, color: Colors.grey, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          "Почта: $_userEmail",
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Дата
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: Colors.grey, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Дата регистрации: ${DateFormat.yMMMd('ru').format(DateTime.now())}', // 14 мая 2025
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    if (_resume != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.work_outline, color: Theme.of(context).colorScheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Специализация: ${getSpecializationName(_resume!['specialization_id'])}",
                              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Уровень опыта (если резюме существует)
                    if (_resume != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_border, color: Theme.of(context).colorScheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Уровень опыта: ${_resume!['experience_level'] ?? 'Не указано'}",
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Кнопка для резюме
            ElevatedButton(
              onPressed: () {
                if (_resume != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditResumeScreen(resume: _resume!),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateResumeScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
              child: Text(
                _resume != null ? 'Редактировать резюме' : 'Создать резюме',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            // Кнопка выхода
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
              child: const Text('Выйти', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}