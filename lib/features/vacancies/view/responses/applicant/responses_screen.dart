import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/features/vacancies/view/responses/applicant/response_detail_screen.dart';
import 'package:my_new_project/features/vacancies/view/chats/chat_detail_screen.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResponsesScreen extends StatefulWidget {
  const ResponsesScreen({super.key});

  @override
  State<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends State<ResponsesScreen> with RouteAware, SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _responses = [];
  List<dynamic> _invitations = [];
  bool _isLoadingResponses = true;
  bool _isLoadingInvitations = true;
  String? _errorMessageResponses;
  String? _errorMessageInvitations;
  Timer? _pollingTimer;
  late TabController _tabController;

  @override
  void initState() {
    initializeDateFormatting('ru');
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    _loadResponses();
    _loadInvitations();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoadingResponses = true;
      _errorMessageResponses = null;
    });
    try {
      debugPrint('Loading responses');
      final responses = await _apiService.getMyVacancyResponses();
      debugPrint('Responses: $responses');
      if (mounted) {
        setState(() {
          _responses = responses;
          _isLoadingResponses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageResponses = 'Ошибка загрузки откликов: $e';
          _isLoadingResponses = false;
        });
      }
    }
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoadingInvitations = true;
      _errorMessageInvitations = null;
    });
    try {
      debugPrint('Loading invitations');
      final invitations = await _apiService.getMyVacancyInvitations();
      debugPrint('Invitations: $invitations');
      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoadingInvitations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageInvitations = 'Ошибка загрузки приглашений: $e';
          _isLoadingInvitations = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation(String vacancyId, String invitationId, String companyOwnerId) async {
    try {
      // Accept the invitation
      await _apiService.updateVacancyInvitationStatus(vacancyId, invitationId, 'accepted');

      // Automatically create a chat
      final prefs = await SharedPreferences.getInstance();
      final applicantId = prefs.getString('user_id');
      if (applicantId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка: Пользователь не авторизован')),
          );
        }
        return;
      }

      final response = await _apiService.createChat(
        applicantId: applicantId,
        companyOwnerId: companyOwnerId,
        vacancyId: vacancyId,
      );
      final chatId = response['id']?.toString(); // Assuming 'id' is the chat ID

      if (chatId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение принято и чат создан')),
        );
      }

      _loadInvitations(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _declineInvitation(String vacancyId, String invitationId) async {
    try {
      await _apiService.updateVacancyInvitationStatus(vacancyId, invitationId, 'declined');
      _loadInvitations(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Приглашение отклонено')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  void didPopNext() {
    _loadResponses();
    _loadInvitations();
    super.didPopNext();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заявки'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Отклики'),
            Tab(text: 'Приглашения'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Responses Tab
          _isLoadingResponses
              ? const Center(child: CircularProgressIndicator())
              : _errorMessageResponses != null
              ? Center(child: Text(_errorMessageResponses!))
              : _responses.isEmpty
              ? const Center(child: Text('Нет откликов'))
              : RefreshIndicator(
                onRefresh: () async {
                  _loadResponses();
                },
                child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _responses.length,
                            itemBuilder: (context, index) {
                final response = _responses[index];
                final vacancyTitle = response['item_title'] ?? 'Не указана';
                final status = (response['status'] == 'accepted')
                    ? 'принято'
                    : (response['status'] == 'pending')
                    ? 'ожидание'
                    : 'отклонено';
                final createdAt = response['created_at'] != null
                    ? DateFormat.yMMMd('ru').format(DateTime.parse(response['created_at']))
                    : 'Не указано';
                return Card(
                  child: ListTile(
                    minVerticalPadding: 15,
                    leading: const Icon(Icons.mail),
                    trailing: (status == 'принято') ? Icon(Icons.check_circle_rounded, color: Colors.green)  : (status == 'отклонено') ? Icon(Icons.close, color: Colors.red) : Icon(Icons.pending_outlined, color: Colors.orange),
                    title: Text('Отклик ${index + 1}'),
                    subtitle: Text(
                        'Вакансия: $vacancyTitle\nСтатус: $status\nДата: $createdAt'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ResponseDetailScreen(
                            responseId: response['id'].toString(),
                          ),
                        ),
                      );
                    },
                  ),
                );
                            },
                          ),
              ),
          // Invitations Tab
          _isLoadingInvitations
              ? const Center(child: CircularProgressIndicator())
              : _errorMessageInvitations != null
              ? Center(child: Text(_errorMessageInvitations!))
              : _invitations.isEmpty
              ? const Center(child: Text('Нет приглашений'))
              : RefreshIndicator(
                onRefresh: () async {
                  _loadInvitations();
                },
                child: ListView.builder(
                            padding: const EdgeInsets.all(8.0),
                            itemCount: _invitations.length,
                            itemBuilder: (context, index) {
                final invitation = _invitations[index];
                final vacancyTitle = invitation['vacancy_title'] ?? 'Не указана';
                final employerName = invitation['employer_name'] ?? 'Не указан';
                final status = invitation['status'];
                final createdAt = invitation['created_at'] != null
                    ? DateFormat.yMMMd('ru').format(DateTime.parse(invitation['created_at']))
                    : 'Не указано';
                final message = invitation['message'] ?? 'Сообщение отсутствует';
                final vacancyId = invitation['vacancy_id']?.toString();
                final companyOwnerId = invitation['employer_id']?.toString();
                if (vacancyId == null || companyOwnerId == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Ошибка: vacancy_id или company_owner_id отсутствует'),
                    ),
                  );
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Приглашение от: $employerName',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Вакансия: $vacancyTitle'),
                        const SizedBox(height: 4),
                        Text('Дата: $createdAt'),
                        const SizedBox(height: 8),
                        Text('Сообщение: $message'),
                        const SizedBox(height: 16),
                        if (status == 'pending')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => _acceptInvitation(vacancyId, invitation['id'].toString(), companyOwnerId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Принять'),
                              ),
                              ElevatedButton(
                                onPressed: () => _declineInvitation(vacancyId, invitation['id'].toString()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text('Отказаться'),
                              ),
                            ],
                          )
                        else if (status == 'accepted')
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Принято ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Icon(Icons.check_circle_rounded, color: Colors.green)

                              ],
                            ),
                          )
                        else if (status == 'declined')
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Отклонено',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Icon(Icons.close, color: Colors.red)
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                );
                            },
                          ),
              ),
        ],
      ),
    );
  }
}