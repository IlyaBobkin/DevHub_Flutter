import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import '../../../../repositories/main/api_service.dart';
import '../../../../repositories/main/model/vacancy.dart';

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
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendResponse() async {
    if (_vacancy == null) return;

    final currentDateTime = DateTime(2025, 5, 14, 13, 13); // 01:13 PM EDT, 14 мая 2025
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(currentDateTime);
    final message = 'Отклик на вакансию от $formattedDate';

    try {
      await _apiService.createVacancyResponse(widget.vacancyId, message);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отклик успешно отправлен!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки отклика: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                  'Создано: ${DateFormat('yyyy-MM-dd').format(_vacancy!.createdAt)}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  _vacancy!.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Зарплата: ${_vacancy!.salaryFrom.toStringAsFixed(2)} - ${_vacancy!.salaryTo.toStringAsFixed(2)} ₽',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
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
                const SizedBox(height: 8),
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