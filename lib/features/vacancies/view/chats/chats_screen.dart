import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _startPolling();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('user_id');
    });
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
    try {
      if (_isLoading && _chats.isEmpty) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final chats = await _apiService.getChatsList();
      debugPrint('Fetched chats: $chats');

      // Map existing chats for comparison
      final existingChatMap = {for (var chat in _chats) chat['id'].toString(): chat};

      // Process chats and fetch messages only for updated or new chats
      final updatedChats = await Future.wait(chats.map((chat) async {
        final chatId = chat['id'].toString();
        final existingChat = existingChatMap[chatId];

        // Check if chat is new or has a different timestamp
        final needsUpdate = existingChat == null ||
            existingChat['createdAt'] != chat['createdAt'];

        if (!needsUpdate) {
          return existingChat; // Skip fetching messages if no update
        }

        try {
          final messages = await _apiService.loadMessages(chatId);
          // Ensure messages are sorted by createdAt (latest first)
          messages.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
          final lastMessage = messages.isNotEmpty ? messages.first : null;
          debugPrint('Chat $chatId last message: $lastMessage');
          return {
            ...chat,
            'lastMessage': lastMessage?['text'] ?? 'Нет сообщений',
            'lastMessageTime': lastMessage?['createdAt'] != null
                ? DateFormat.Hm('ru').format(DateTime.parse(lastMessage?['createdAt']))
                : 'Не указано',
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

  Future<void> _updateChatAfterSending(String chatId, String messageText) async {
    try {
      final messages = await _apiService.loadMessages(chatId);
      messages.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      final lastMessage = messages.isNotEmpty ? messages.first : null;

      setState(() {
        _chats = _chats.map((chat) {
          if (chat['id'].toString() == chatId) {
            return {
              ...chat,
              'lastMessage': lastMessage?['text'] ?? messageText,
              'lastMessageTime': lastMessage?['createdAt'] != null
                  ? DateFormat.Hm('ru').format(DateTime.parse(lastMessage?['createdAt']))
                  : DateFormat.Hm('ru').format(DateTime.now()),
              'lastMessageSenderId': lastMessage?['senderId']?.toString() ?? _currentUserId,
            };
          }
          return chat;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error updating chat $chatId after sending: $e');
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
          : ListView.separated(
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
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
              ),
              title: Text(
                chat['opponentName'] ?? 'Неизвестный',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(chatId: chat['id'].toString()),
                  ),
                );
                // Check if a message was sent (assuming ChatDetailScreen returns the sent message text)
                if (result != null && result is String) {
                  await _updateChatAfterSending(chat['id'].toString(), result);
                }
              },
            ),
          );
        },
      ),
    );
  }
}