// Экран "Отклики"
import 'package:flutter/material.dart';
import 'package:my_new_project/features/vacancies/view/responses/response_detail_screen.dart';

class ResponsesScreen extends StatelessWidget {
  const ResponsesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отклики'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.mail),
              title: Text('Отклик ${index + 1}'),
              subtitle: const Text('Вакансия: Junior Developer'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ResponseDetailScreen(responseId: index + 1),
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