import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:my_new_project/repositories/main/api_service.dart';

class ResponseDetailScreen extends StatefulWidget {
  final String responseId;

  const ResponseDetailScreen({super.key, required this.responseId});

  @override
  State<ResponseDetailScreen> createState() => _ResponseDetailScreenState();
}

class _ResponseDetailScreenState extends State<ResponseDetailScreen> {
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
      debugPrint('Loading responses for responseId: ${widget.responseId}');
      final allResponses = await _apiService.getMyVacancyResponses();
      debugPrint('All responses: $allResponses');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Детали отклика'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : _response == null
            ? const Center(child: Text('Отклик не найден'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отклик на вакансию ${_response!['item_title'] ?? 'Не указана'}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Дата создания: ${_response!['created_at'] != null ? DateFormat.yMMMd('ru').format(DateTime.parse(_response!['created_at'])) : 'Не указана'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Работодатель: ${_response!['who_name'] ?? 'Не указана'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Статус: ${_response!['status'] ?? 'Не указан'}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Комментарий: ${_response!['message'] ?? 'Отсутствует'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}