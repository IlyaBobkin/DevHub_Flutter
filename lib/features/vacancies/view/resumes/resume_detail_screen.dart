import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../repositories/main/api_service.dart';
import '../../../../repositories/main/model/resume.dart';

class ResumeDetailScreen extends StatefulWidget {
  final String resumeId;

  const ResumeDetailScreen({super.key, required this.resumeId});

  @override
  State<ResumeDetailScreen> createState() => _ResumeDetailScreenState();
}

class _ResumeDetailScreenState extends State<ResumeDetailScreen> {
  final ApiService _apiService = ApiService();
  Resume? _resume;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _vacancies = [];
  String? _selectedVacancyId;
  bool _isVacanciesLoading = true;
  String? _vacanciesError;
  String _message = '';
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadResume();
    _loadVacancies();
  }

  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resumeData = await _apiService.getResumeById(widget.resumeId);
      print('Resume data: $resumeData');
      setState(() {
        _resume = Resume.fromJson(resumeData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки резюме: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVacancies() async {
    setState(() {
      _isVacanciesLoading = true;
      _vacanciesError = null;
    });
    try {
      final vacancies = await _apiService.getMyVacancies();
      setState(() {
        _vacancies = vacancies;
        _isVacanciesLoading = false;
        if (_vacancies.isNotEmpty) {
          _selectedVacancyId = _vacancies[0]['id'] as String?;
        }
      });
    } catch (e) {
      setState(() {
        _vacanciesError = 'Ошибка загрузки вакансий: $e';
        _isVacanciesLoading = false;
      });
    }
  }

  Future<void> _sendResponse() async {
    if (_resume == null || _selectedVacancyId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    if (_resume!.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить ID соискателя')),
      );
      return;
    }

    final invitationId = _uuid.v4();
    final currentDateTime = DateTime.now(); // 08:38 PM CEST, 16 мая 2025
    final formattedDate = DateFormat.yMd('ru').format(currentDateTime);
    final message = _message.isNotEmpty ? _message : 'Интерес к резюме от $formattedDate';

    try {
      debugPrint('Sending invitation: id=$invitationId, vacancyId=$_selectedVacancyId, companyOwnerId=$userId, applicantId=${_resume!.userId}, message=$message');
      final response = await _apiService.createVacancyInvitation(
        invitationId,
        _selectedVacancyId!,
        userId,
        _resume!.userId!, // Use applicantId instead of resume.id
        message,
      );
      debugPrint('Server response: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Приглашение успешно отправлено!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error sending invitation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки приглашения: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали резюме'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _resume == null
              ? const Center(child: Text('Резюме не найдено'))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Создано: ${DateFormat.yMMMd('ru').format(_resume!.createdAt)}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resume!.specializationName ?? 'Без названия',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Соискатель: ${_resume!.applicantName ?? 'Не указан'}",
                    style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resume!.expectedSalary != null
                        ? 'Ожидаемая зарплата: ${_resume!.expectedSalary} ₽'
                        : 'Ожидаемая зарплата: не указана',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Уровень опыта: ${_resume!.experienceLevel ?? 'Не указан'}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Местоположение: ${_resume!.location ?? 'Не указано'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Описание: ${_resume!.description ?? 'Не указано'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Выберите вакансию для приглашения:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isVacanciesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _vacanciesError != null
                      ? Text(
                    _vacanciesError!,
                    style: const TextStyle(color: Colors.red),
                  )
                      : _vacancies.isEmpty
                      ? const Text(
                    'У вас нет доступных вакансий. Создайте вакансию, чтобы отправить приглашение.',
                    style: TextStyle(color: Colors.grey),
                  )
                      : DropdownButton<String>(
                    value: _selectedVacancyId,
                    hint: const Text('Выберите вакансию'),
                    isExpanded: true,
                    items: _vacancies.map((vacancy) {
                      return DropdownMenuItem<String>(
                        value: vacancy['id'] as String,
                        child: Text(vacancy['title'] ?? 'Вакансия ${vacancy['id']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedVacancyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Сообщение для соискателя:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Введите ваше сообщение...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _message = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_selectedVacancyId == null || _vacancies.isEmpty) ? null : _sendResponse,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 10,
                  ),
                  child: const Text(
                    'Отправить приглашение',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}