import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
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
  String? _responseStatus; // Для хранения статуса отклика

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
        _responseStatus = response['status']; // Сохраняем статус
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки деталей отклика: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelResponse() async {
    if (_response == null || _response!['item_id'] == null || _responseStatus != 'pending') return;

    try {
      await _apiService.updateVacancyResponseStatus(
        _response!['item_id'].toString(),
        widget.responseId,
        'cancelled',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отклик успешно отменен')),
      );
      setState(() {
        _responseStatus = 'cancelled'; // Обновляем статус
        _loadResponse();
      });
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
            Row(
              children: [
                Text(
                  'Статус: ${_response!['status'] == 'accepted' ? 'принято' : _response!['status'] == 'pending' ? 'ожидание' : _response!['status'] == 'cancelled' ? 'отменен' : 'отклонено'}',
                  style: const TextStyle(fontSize: 18),
                ),
                SizedBox(width: 5),
                (_response!['status'] == 'accepted')
                    ? Icon(Icons.check_circle_rounded, color: Colors.green)
                    : (_response!['status'] == 'declined')
                    ? Icon(Icons.close, color: Colors.red)
                    : (_response!['status'] == 'cancelled')
                    ? Icon(Icons.settings_backup_restore, color: Colors.red)
                    : Icon(Icons.pending_outlined, color: Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Комментарий: ${_response!['message'] ?? 'Отсутствует'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_responseStatus == 'pending')
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
        ),
      ),
    );
  }
}