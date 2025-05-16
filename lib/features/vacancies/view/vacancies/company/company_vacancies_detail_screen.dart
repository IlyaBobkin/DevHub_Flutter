import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/vacancy.dart';

import 'actions/edit_vacancy_screen.dart';

class CompanyVacancyDetailScreen extends StatefulWidget {
  final String vacancyId;

  const CompanyVacancyDetailScreen({super.key, required this.vacancyId});

  @override
  State<CompanyVacancyDetailScreen> createState() => _CompanyVacancyDetailScreenState();
}

class _CompanyVacancyDetailScreenState extends State<CompanyVacancyDetailScreen> {
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

  Future<void> _deleteVacancy() async {
    try {
      await _apiService.deleteVacancy(widget.vacancyId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вакансия удалена!')),
      );
      Navigator.pop(context, true); // Возвращаем true, чтобы обновить список
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления: $e')),
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
              '${_vacancy!.salaryFrom} - ${_vacancy!.salaryTo} ₽',
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
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVacancyScreen(vacancy: _vacancy!),
                        ),
                      );
                      if (result == true) {
                        await _loadVacancy(); // Обновляем данные вакансии
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Редактировать',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _deleteVacancy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Удалить',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}