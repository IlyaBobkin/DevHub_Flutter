import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/vacancy.dart';

class VacancyDetailScreen extends StatefulWidget {
  final String vacancyId;

  const VacancyDetailScreen({super.key, required this.vacancyId});

  @override
  State<VacancyDetailScreen> createState() => _VacancyDetailScreenState();
}

class _VacancyDetailScreenState extends State<VacancyDetailScreen> {
  final ApiService _apiService = ApiService();
  Vacancy? _vacancy;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadVacancy();
  }

  Future<void> _loadVacancy() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final vacancy = await _apiService.getVacancyById(widget.vacancyId);
      setState(() {
        _vacancy = vacancy;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки вакансии: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendResponse() async {
    if (_vacancy == null) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }
    // Проверка наличия резюме
    try {
      final resume = await _apiService.getMyResume();
      if (resume!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сначала создайте резюме')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка проверки резюме: $e')),
      );
      return;
    }

    final currentDateTime = DateTime.now(); // 12:19 PM PDT, 14 мая 2025
    final formattedDate = DateFormat.yMd('ru').format(currentDateTime);
    final message = 'Отклик на вакансию от $formattedDate';

    try {
      debugPrint('Sending response: vacancyId=$widget.vacancyId, userId=$userId, message=$message');
      final response = await _apiService.createVacancyResponse(widget.vacancyId, message, userId: userId);
      debugPrint('Response data: $response');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отклик успешно отправлен!')),
      );
    } catch (e) {
      debugPrint('Error sending response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки отклика: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали вакансии'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _vacancy == null
            ? const Center(child: Text('Вакансия не найдена'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Опубликовано: ${DateFormat.yMMMd('ru').format(_vacancy!.createdAt)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _vacancy!.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_vacancy!.salaryFrom.toStringAsFixed(0)} - ${_vacancy!.salaryTo.toStringAsFixed(0)} ₽',
                  style: const TextStyle(fontSize: 20, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  "Уровень: ${_vacancy!.experienceLevel}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "Компания: ${_vacancy!.companyName}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Местоположение: ${_vacancy!.location}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text(
                  'Описание: ${_vacancy!.description}',
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
                  'Откликнуться',
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