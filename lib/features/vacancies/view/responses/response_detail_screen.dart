
// Экран деталей отклика
import 'package:flutter/material.dart';

class ResponseDetailScreen extends StatelessWidget {
  final int responseId;

  const ResponseDetailScreen({super.key, required this.responseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отклик $responseId'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Отклик $responseId',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Вакансия: Junior Developer'),
            const SizedBox(height: 8),
            const Text('Статус: На рассмотрении'),
            const SizedBox(height: 16),
            const Text('Комментарий: Lorem ipsum dolor sit amet.'),
          ],
        ),
      ),
    );
  }
}