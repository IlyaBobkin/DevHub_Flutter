// Экран "Чаты"
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'chat_detail_screen.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const Icon(CupertinoIcons.chat_bubble_2),
              title: Text('Чат ${index + 1}'),
              subtitle: const Text('Последнее сообщение: Привет!'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(chatId: index + 1),
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