import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../repositories/main/api_service.dart';
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
  String? _currentUserId;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadUserId();
    _loadChats();
  }


  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('user_id');
    });
  }

  Future<void> _loadChats() async {
    try {
      if (_isLoading && _chats.isEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final chats = await _apiService.getChatsList();
      debugPrint('Fetched chats: $chats');

      final updatedChats = await Future.wait(chats.map((chat) async {
        final chatId = chat['id'].toString();
        try {
          final messages = await _apiService.loadMessages(chatId);
          messages.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
          final lastMessage = messages.isNotEmpty ? messages.first : null;
          debugPrint('Chat $chatId last message: $lastMessage');
          return {
            ...chat,
            'lastMessage': lastMessage?['text'] ?? 'Нет сообщений',
            'lastMessageTime': lastMessage?['createdAt'] != null
                ? DateFormat.Hm('ru').format(DateTime.parse(lastMessage?['createdAt']))
                : '',
            'lastMessageSenderId': lastMessage?['senderId']?.toString(),
          };
        } catch (e) {
          debugPrint('Error loading messages for chat $chatId: $e');
          return {
            ...chat,
            'lastMessage': 'Ошибка загрузки',
            'lastMessageTime': 'Не указано',
            'lastMessageSenderId': null,
          };
        }
      }));

      if (mounted) {
        setState(() {
          _chats = updatedChats;
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
        title: const Text(
          'Чаты',
        ),
      ),
      body: _isLoading && _chats.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[700], size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(fontSize: 16, color: Colors.red[700], fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadChats,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      )
          : _chats.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, color: Colors.grey[500], size: 64),
            const SizedBox(height: 16),
            Text(
              'Нет доступных чатов',
              style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : RefreshIndicator(
            onRefresh: () async {
              _loadChats();
            },
            child: ListView.separated(
                    padding: const EdgeInsets.all(4.0),
                    itemCount: _chats.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.grey),
                    itemBuilder: (context, index) {
            final chat = _chats[index];
            final createdAt = chat['createdAt'] != null
                ? DateFormat.yMMMd('ru').format(DateTime.parse(chat['createdAt']))
                : 'Не указано';
            final lastMessage = chat['lastMessage'];
            final lastMessageTime = chat['lastMessageTime'];
            final senderId = chat['lastMessageSenderId']?.toString();
            final senderName = senderId == _currentUserId
                ? 'Вы'
                : chat['opponentName'] ?? 'Неизвестный';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      chat['opponentName'] ?? 'Неизвестный',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Вакансия: " + (chat['vacancyName'] ?? 'Неизвестный'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '$senderName: $lastMessage • $lastMessageTime',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: Text(
                  createdAt,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                onTap: () async {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(chatId: chat['id'].toString()),
                    ),
                  ).whenComplete(_loadChats);
                },
              ),
            );
                    },
                  ),
          ),
    );
  }
}