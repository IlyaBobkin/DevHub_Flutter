import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('ru');
    final createdAt = DateTime.parse(notification['created_at']);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали уведомления'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['message'] ?? 'Без сообщения',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (notification['vacancy_title'] != null)
              Text(
                'Вакансия: ${notification['vacancy_title']}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 8),
            Text(
              'Тип: ${notification['type'] == 'response_status' ? 'Статус отклика' : 'Приглашение'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Дата: ${DateFormat.yMMMd('ru').format(createdAt)} в ${DateFormat.Hm('ru').format(createdAt)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Статус: ${notification['is_read'] ? 'Прочитано' : 'Непрочитано'}',
              style: TextStyle(
                fontSize: 16,
                color: notification['is_read'] ? Colors.grey : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}