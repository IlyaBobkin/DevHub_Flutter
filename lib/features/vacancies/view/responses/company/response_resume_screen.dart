import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../../repositories/main/api_service.dart';
import '../../../../../repositories/main/model/resume.dart';

class ResponseResumeScreen extends StatefulWidget {
  final String resumeId;

  const ResponseResumeScreen({super.key, required this.resumeId});

  @override
  State<ResponseResumeScreen> createState() => _ResponseResumeScreenState();
}

class _ResponseResumeScreenState extends State<ResponseResumeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали резюме'),
        backgroundColor: Colors.transparent,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}