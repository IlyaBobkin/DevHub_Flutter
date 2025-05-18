import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;

  const ChatDetailScreen({super.key, required this.chatId});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _opponentName;
  String? _userId;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadUserId();
    _loadMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _pollMessages();
    });
  }

  Future<void> _pollMessages() async {
    try {
      final messages = await _apiService.loadMessages(widget.chatId);
      final sortedMessages = messages.toList()
        ..sort((a, b) => DateTime.parse(a['createdAt']).compareTo(DateTime.parse(b['createdAt'])));
      if (!_areMessagesEqual(sortedMessages, _messages)) {
        final isAtBottom = _scrollController.hasClients &&
            _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent - 50;

        setState(() {
          _messages = sortedMessages;
        });

        if (isAtBottom) {
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('Error polling messages: $e');
    }
  }

  bool _areMessagesEqual(List<Map<String, dynamic>> list1, List<Map<String, dynamic>> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i]['id'] != list2[i]['id'] ||
          list1[i]['text'] != list2[i]['text'] ||
          list1[i]['senderId'] != list2[i]['senderId'] ||
          list1[i]['createdAt'] != list2[i]['createdAt']) {
        return false;
      }
    }
    return true;
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
    debugPrint('Loaded userId: $_userId');
    if (_userId != null) {
      await _loadOpponentName();
    } else {
      setState(() {
        _opponentName = 'Неизвестный';
      });
    }
  }

  Future<void> _loadOpponentName() async {
    try {
      final chats = await _apiService.getChatsList();
      debugPrint('Chats response: $chats');
      final chat = chats.firstWhere(
            (c) => c['id'].toString() == widget.chatId,
        orElse: () => throw Exception('Чат с ID ${widget.chatId} не найден'),
      );
      debugPrint('Found chat: $chat');
      setState(() {
        _opponentName = chat['opponentName'] ?? 'Неизвестный';
      });
    } catch (e) {
      debugPrint('Error loading opponent name: $e');
      setState(() {
        _opponentName = 'Неизвестный';
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final messages = await _apiService.loadMessages(widget.chatId);
      final sortedMessages = messages.toList()
        ..sort((a, b) => DateTime.parse(a['createdAt']).compareTo(DateTime.parse(b['createdAt'])));
      setState(() {
        _messages = sortedMessages;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки сообщений: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _apiService.sendMessage(widget.chatId, _messageController.text.trim());
      _messageController.clear();
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_opponentName != null ? 'Чат с $_opponentName' : 'Чат ${widget.chatId}'),
      ),
      body: Column(
        children: [
          Expanded(
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
                    onPressed: _loadMessages,
                    child: const Text('Повторить попытку'),
                  ),
                ],
              ),
            )
                : _messages.isEmpty
                ? const Center(child: Text('Нет сообщений'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSentByMe = message['senderId'] == _userId;
                final createdAt = message['createdAt'] != null
                    ? DateFormat('HH:mm, d MMM', 'ru').format(DateTime.parse(message['createdAt']))
                    : 'Не указано';

                return Align(
                  alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child:
                    ChatBubble(
                      clipper: ChatBubbleClipper6(type: isSentByMe ? BubbleType.sendBubble : BubbleType.receiverBubble),
                      alignment: isSentByMe? Alignment.topRight : Alignment.topLeft,
                      margin: EdgeInsets.only(top: 20),
                      backGroundColor: isSentByMe
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child:                     Column(
                          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: TextStyle(
                                color: isSentByMe
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              createdAt,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSentByMe
                                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Напишите сообщение...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none
                      ),
                      filled: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}