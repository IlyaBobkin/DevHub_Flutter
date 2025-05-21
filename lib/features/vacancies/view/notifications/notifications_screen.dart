import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../../repositories/main/api_service.dart';
import 'notification_detail_screen.dart'; // Импортируем новый экран

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadNotifications();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Loading notifications');
      final notifications = await _apiService.getUserNotifications();
      debugPrint('Notifications: $notifications');

      if (mounted) {
        setState(() {
          _notifications = notifications
            ..sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки уведомлений: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    try {
      await _apiService.markNotificationAsRead(notificationId);
      setState(() {
        _notifications[index]['is_read'] = true;
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось отметить уведомление как прочитанное: $e')),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
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
                onPressed: _loadNotifications,
                child: const Text('Повторить попытку'),
              ),
            ],
          ),
        )
            : _notifications.isEmpty
            ? const Center(child: Text('Нет уведомлений'))
            : RefreshIndicator(
          onRefresh: _loadNotifications,
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              final createdAt = DateTime.parse(notification['created_at']);
              return Card(
                child: ListTile(
                  leading: Icon(
                    notification['type'] == 'response_status'
                        ? Icons.how_to_reg
                        : Icons.mail,
                    color: notification['is_read'] ? Colors.grey : Colors.blue,
                  ),
                  title: Text(notification['message'] ?? 'Без сообщения'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (notification['vacancy_title'] != null)
                        Text('Вакансия: ${notification['vacancy_title']}'),
                      Text(
                        'Дата: ${DateFormat.yMMMd('ru').format(createdAt)} в ${DateFormat.Hm('ru').format(createdAt)}',
                      ),
                    ],
                  ),
                  trailing: notification['is_read']
                      ? null
                      : const Icon(Icons.circle, color: Colors.blue, size: 12),
                  onTap: () async {
                    if (!notification['is_read']) {
                      await _markAsRead(notification['id'], index);
                    }
                    // Переход на экран деталей уведомления
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationDetailScreen(notification: notification),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}