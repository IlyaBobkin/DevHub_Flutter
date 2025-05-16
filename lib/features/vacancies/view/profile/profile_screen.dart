import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import '../../../../job_app.dart';
import '../../../authorization/view/login_screen.dart';
import 'applicant/actions/create_resume_screen.dart';
import 'applicant/actions/edit_resume_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  String? _userName;
  String? _userEmail;
  String? _userRole;
  DateTime _userDate = DateTime.now();
  Map<String, dynamic>? _resume;
  List<Map<String, dynamic>> _specializations = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ru');
    _loadUserData();
    _loadTheme();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      String? userId = prefs.getString('user_id');
      if (userId == null) throw Exception('Пользователь не авторизован');
      final userInfo = await _apiService.getUserProfileById(userId);
      Map<String, dynamic>? resume = null;
      if (userInfo['role'] == 'applicant') {
        resume = await _apiService.getMyResume();
      }
      final specializations = await _apiService.getSpecializations();
      setState(() {
        _userName = userInfo['name'] ?? 'Не указано';
        _userEmail = userInfo['email'] ?? 'Не указано';
        _userDate = DateTime.parse(userInfo['created_at'] as String) ?? DateTime.now();
        _userRole = userInfo['role'] == 'applicant'
            ? 'Соискатель'
            : userInfo['role'] == 'company_owner'
            ? 'Работодатель'
            : 'Не указано';
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

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = (prefs.getInt('themeIndex') ?? 0) == 1;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkTheme = !_isDarkTheme;
      final newThemeIndex = _isDarkTheme ? 1 : 0;
      prefs.setInt('themeIndex', newThemeIndex);
      themeIndexNotifier.value = newThemeIndex; // Update the ValueNotifier
    });
  }

  Future<void> _deleteResume() async {
    if (_resume == null || _resume!['id'] == null) return;
    try {
      await _apiService.deleteResume(_resume!['id']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Резюме удалено!')));
      await _loadUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e')));
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
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
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(Icons.person, size: 60, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Имя: $_userName",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, color: Colors.grey, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Почта: $_userEmail",
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.quick_contacts_mail, color: Colors.grey, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Роль: $_userRole",
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Дата регистрации: ${DateFormat.yMMMd('ru').format(_userDate)}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (_userRole == 'Соискатель' && _resume != null) ...[
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star_border, color: Theme.of(context).colorScheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Уровень опыта: ${_resume!['experience_level'] ?? 'Не указано'}",
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Местоположение: ${_resume!['location'] ?? 'Не указано'}",
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_userRole == 'Соискатель') ...[
                ElevatedButton(
                  onPressed: () async {
                    if (_resume != null) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditResumeScreen(resume: _resume!),
                        ),
                      );
                      if (result == true) {
                        await _loadUserData();
                      }
                    } else {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateResumeScreen()),
                      );
                      if (result == true) {
                        await _loadUserData();
                      }
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
                if (_resume != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _deleteResume,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                    ),
                    child: const Text(
                      'Удалить резюме',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 16),
              const Text(
                'Настройки темы',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Темная тема',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Switch(
                    value: _isDarkTheme,
                    onChanged: (value) {
                      _toggleTheme();
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Выберите тему для приложения. Темная тема может быть удобна в условиях низкой освещенности.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
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
      ),
    );
  }
}