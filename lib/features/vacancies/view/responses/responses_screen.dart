import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/features/vacancies/view/responses/response_detail_screen.dart';
import 'package:my_new_project/repositories/main/api_service.dart';

class ResponsesScreen extends StatefulWidget {
  const ResponsesScreen({super.key});

  @override
  State<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _responses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Loading responses');
      final responses = await _apiService.getMyVacancyResponses();
      debugPrint('Responses: $responses');
      setState(() {
        _responses = responses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки откликов: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отклики'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _responses.isEmpty
          ? const Center(child: Text('Нет откликов'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _responses.length,
        itemBuilder: (context, index) {
          final response = _responses[index];
          final vacancyTitle = response['item_title'] ?? 'Не указана';
          final status = response['status'] ?? '-';
          final createdAt = response['created_at'] != null
              ? DateFormat.yMMMd('ru').format(DateTime.parse(response['created_at']))
              : 'Не указано';
          return Card(
            child: ListTile(
              leading: const Icon(Icons.mail),
              title: Text('Отклик ${index + 1}'),
              subtitle: Text('Вакансия: $vacancyTitle\nСтатус: $status\nДата: $createdAt'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ResponseDetailScreen(
                      responseId: response['id'].toString(),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}