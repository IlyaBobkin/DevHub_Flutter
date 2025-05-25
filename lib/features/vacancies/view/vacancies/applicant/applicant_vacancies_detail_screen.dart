import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../repositories/main/api_service.dart';
import '../../../../../repositories/main/model/vacancy.dart';

class ApplicantVacancyDetailScreen extends StatefulWidget {
  final String vacancyId;

  const ApplicantVacancyDetailScreen({super.key, required this.vacancyId});

  @override
  State<ApplicantVacancyDetailScreen> createState() => _ApplicantVacancyDetailScreenState();
}

class _ApplicantVacancyDetailScreenState extends State<ApplicantVacancyDetailScreen> {
  final ApiService _apiService = ApiService();
  Vacancy? _vacancy;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasResponded = false;
  String? _responseId;
  String? _responseStatus; // Для хранения статуса отклика

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadVacancy();
    _checkResponseStatus();
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

  Future<void> _checkResponseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;

    try {
      final responses = await _apiService.getMyVacancyResponses();
      final response = responses.firstWhere(
            (r) => r['item_id'] == widget.vacancyId, // Проверяем по vacancy_id
        orElse: () => null,
      );
      debugPrint("Responses: $responses");

      if (mounted) {
        setState(() {
          _hasResponded = response != null;
          _responseId = response?['id']?.toString();
          _responseStatus = response?['status']; // Сохраняем статус отклика
        });
      }
    } catch (e) {
      debugPrint('Ошибка проверки статуса отклика: $e');
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

    final currentDateTime = DateTime.now();
    final formattedDate = DateFormat.yMd('ru').format(currentDateTime);
    final message = 'Отклик на вакансию от $formattedDate';

    try {
      debugPrint('Sending response: vacancyId=${widget.vacancyId}, userId=$userId, message=$message');
      final response = await _apiService.createVacancyResponse(widget.vacancyId, message, userId: userId);
      debugPrint('Response data: $response');
      if (mounted) {
        setState(() {
          _hasResponded = true;
          _responseId = response['id']?.toString();
          _responseStatus = 'pending'; // Новый отклик имеет статус pending
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отклик успешно отправлен!')),
        );
      }
    } catch (e) {
      debugPrint('Error sending response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки отклика: $e')),
      );
    }
  }

  Future<void> _cancelResponse() async {
    if (_responseId == null) return;

    try {
      await _apiService.updateVacancyResponseStatus(widget.vacancyId, _responseId!, 'cancelled');
      if (mounted) {
        setState(() {
          _hasResponded = false;
          _responseId = null;
          _responseStatus = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отклик успешно отменен')),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling response: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отмены отклика: $e')),
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
                  '${_vacancy!.salaryFrom?.replaceAll('.00', '')} - ${_vacancy!.salaryTo?.replaceAll('.00', '')} ₽ в месяц',
                  style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary),
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
            _hasResponded && _responseStatus != 'cancelled'
                ? _responseStatus == 'pending'
                ? Column(
              children: [
                const Text(
                  'Отклик отправлен',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _cancelResponse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 10,
                    ),
                    child: const Text(
                      'Отменить отклик',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
                : const Text(
              'Вы уже откликались на данную вакансию',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.start,
            )
                : SizedBox(
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