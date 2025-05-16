import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/features/vacancies/view/responses/company/response_resume_screen.dart';
import 'package:my_new_project/repositories/main/api_service.dart';

class CompanyResponseDetailScreen extends StatefulWidget {
  final String responseId;

  const CompanyResponseDetailScreen({super.key, required this.responseId});

  @override
  State<CompanyResponseDetailScreen> createState() => _CompanyResponseDetailScreenState();
}

class _CompanyResponseDetailScreenState extends State<CompanyResponseDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _response;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadResponse();
  }

  Future<void> _loadResponse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Loading employer response for responseId: ${widget.responseId}');
      final allResponses = await _apiService.getOwnerVacancyResponses();
      debugPrint('All employer responses: $allResponses');
      final response = allResponses.firstWhere(
            (r) => r['id'].toString() == widget.responseId,
        orElse: () => throw Exception('Отклик с ID ${widget.responseId} не найден'),
      );
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки деталей отклика: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateResponseStatus(String status) async {
    if (_response == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final vacancyId = _response!['vacancy_id'] ?? _response!['vacancyId'];
      await _apiService.updateVacancyResponseStatus(vacancyId.toString(), widget.responseId, status);
      final updatedResponses = await _apiService.getOwnerVacancyResponses();
      final updatedResponse = updatedResponses.firstWhere(
            (r) => r['id'].toString() == widget.responseId,
      );
      setState(() {
        _response = updatedResponse;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Статус обновлён на "$status"')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка обновления статуса: $e';
        _isLoading = false;
      });
    }
  }

  void _viewResume() {
    if (_response == null || _response!['applicant_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID резюме не найден')),
      );
      return;
    }
    // Assuming applicant_id is the resumeId or can be used to fetch the resume
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ResponseResumeScreen(resumeId: _response!['applicant_id'].toString()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали отклика работодателя'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadResponse,
                child: const Text('Повторить попытку'),
              ),
            ],
          ),
        )
            : _response == null
            ? const Center(child: Text('Отклик не найден'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отклик на вакансию ${_response!['vacancy_title'] ?? _response!['item_title'] ?? 'Не указана'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Дата создания: ${_response!['created_at'] != null ? DateFormat.yMMMd('ru').format(DateTime.parse(_response!['created_at'])) : 'Не указана'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Соискатель: ${_response!['applicant_name'] ?? 'Не указан'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Статус: ${_response!['status'] ?? 'Не указан'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Сообщение: ${_response!['message'] ?? 'Отсутствует'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _updateResponseStatus('accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Принять'),
                ),
                ElevatedButton(
                  onPressed: () => _updateResponseStatus('rejected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Отклонить'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _viewResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Просмотреть резюме'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}