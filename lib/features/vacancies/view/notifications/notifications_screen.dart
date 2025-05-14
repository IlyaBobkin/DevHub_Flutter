// Экран "Уведомления"
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_sharp),
                title: const Text('Notification 1'),
                subtitle: const Text('This is a notification'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_sharp),
                title: const Text('Notification 2'),
                subtitle: const Text('This is a notification'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}