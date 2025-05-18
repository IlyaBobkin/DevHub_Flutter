import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with RouteAware {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadChats();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _loadChats();
    });
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final chats = await _apiService.getChatsList();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки чатов: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadChats();
    super.didPopNext();
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
        title: const Text('Чаты'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      )
          : _chats.isEmpty
          ? const Center(child: Text('Нет доступных чатов'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final createdAt = chat['createdAt'] != null
              ? DateFormat.yMMMd('ru')
              .format(DateTime.parse(chat['createdAt']))
              : 'Не указано';

          return Card(
            child: ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(chat['opponentName'] ?? 'Неизвестный'),
              subtitle: Text(
                '${chat['contextTitle'] ?? 'Без темы'} • $createdAt',
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                        chatId: chat['id'].toString()),
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