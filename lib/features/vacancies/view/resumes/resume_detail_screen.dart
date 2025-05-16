import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/resume.dart';

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

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadResume();
  }

  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resumeData = await _apiService.getResumeById(widget.resumeId);
      print(resumeData);
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

  Future<void> _sendResponse() async {
    if (_resume == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    final currentDateTime = DateTime.now(); // 05:51 PM CEST, 16 мая 2025
    final formattedDate = DateFormat.yMd('ru').format(currentDateTime);
    final message = 'Интерес к резюме от $formattedDate';

    try {
      debugPrint('Sending response: resumeId=${widget.resumeId}, userId=$userId, message=$message');
      // Assuming a method to create a response or invitation for a resume
      final response = await _apiService.createVacancyInvitation(widget.resumeId, userId, message);
      debugPrint('Response data: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запрос успешно отправлен!')),
      );
      Navigator.pop(context, true); // Return to refresh the list
    } catch (e) {
      debugPrint('Error sending response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки запроса: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали резюме'),
      ),
      body: Padding(
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
                  style: const TextStyle(fontSize: 20, color: Colors.blue),
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
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _sendResponse,
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
    );
  }
}