import 'dart:async';
import 'package:DevHub/features/vacancies/view/responses/company/response_resume_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../repositories/main/api_service.dart';

class CompanyResponsesScreen extends StatefulWidget {
  const CompanyResponsesScreen({super.key});

  @override
  State<CompanyResponsesScreen> createState() => _CompanyResponsesScreenState();
}

class _CompanyResponsesScreenState extends State<CompanyResponsesScreen> with RouteAware, SingleTickerProviderStateMixin {
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
      debugPrint('Loading employer responses');
      final responses = await _apiService.getOwnerVacancyResponses();
      debugPrint('Employer responses: $responses');
      if (mounted) {
        setState(() {
          _responses = responses;
          _isLoadingResponses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageResponses = 'Ошибка загрузки откликов работодателя: $e';
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
      debugPrint('Loading sent invitations');
      final invitations = await _apiService.getSentVacancyInvitations();
      debugPrint('Sent invitations: $invitations');
      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoadingInvitations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessageInvitations = 'Ошибка загрузки отправленных приглашений: $e';
          _isLoadingInvitations = false;
        });
      }
    }
  }

  Future<void> _acceptResponse(String vacancyId, String responseId, String applicantId) async {
    try {
      await _apiService.updateVacancyResponseStatus(vacancyId, responseId, 'accepted');

      final prefs = await SharedPreferences.getInstance();
      final companyOwnerId = prefs.getString('user_id');
      if (companyOwnerId == null) {
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
      final chatId = response['id']?.toString();

      if (chatId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отклик принят и чат создан')),
        );
      }

      _loadResponses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _declineResponse(String vacancyId, String responseId) async {
    try {
      await _apiService.updateVacancyResponseStatus(vacancyId, responseId, 'declined');
      _loadResponses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Отклик отклонен')),
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
        title: const Text('Входящие отклики'),
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
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessageResponses!,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadResponses,
                  child: const Text('Повторить попытку'),
                ),
              ],
            ),
          )
              : _responses.isEmpty
              ? RefreshIndicator(onRefresh: () async {              await _loadResponses();
          },
              child: const Center(child: Text('Нет входящих откликов')))
              : RefreshIndicator(
            onRefresh: () async {
              await _loadResponses();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _responses.length,
              itemBuilder: (context, index) {
                final response = _responses[index];
                final vacancyTitle = response['vacancy_title'] ??
                    response['item_title'] ??
                    'Не указана';
                final applicantName =
                    response['applicant_name'] ?? 'Не указан';
                final status = response['status'];
                final createdAt = response['created_at'] != null
                    ? DateFormat.yMMMd('ru').format(
                    DateTime.parse(response['created_at']))
                    : 'Не указано';
                final message =
                    response['message'] ?? 'Сообщение отсутствует';
                final vacancyId =
                response['vacancy_id']?.toString();
                final applicantId =
                response['applicant_id']?.toString();

                if (vacancyId == null || applicantId == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                          'Ошибка: vacancy_id или applicant_id отсутствует'),
                    ),
                  );
                }

                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Отклик от: $applicantName',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Вакансия: $vacancyTitle'),
                        const SizedBox(height: 4),
                        Text('Дата: $createdAt'),
                        const SizedBox(height: 8),
                        Text('Сообщение: $message'),
                        const SizedBox(height: 8),
                        if (status == 'pending')...[
                            ElevatedButton(
                            onPressed: () {
                            Navigator.of(context).push(
                            MaterialPageRoute(
                            builder: (context) =>
                            ResponseResumeScreen(
                            resumeId: applicantId,
                            ),
                            ),
                            );
                            },
                            style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Посмотреть резюме'),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      _acceptResponse(
                                          vacancyId,
                                          response['id'].toString(),
                                          applicantId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8),
                                  ),
                                  child: const Text('Принять'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _declineResponse(
                                          vacancyId,
                                          response['id'].toString()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8),
                                  ),
                                  child: const Text('Отклонить'),
                                ),
                              ],
                            )]
                        else if (status == 'accepted')
                          Center(
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Принято ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.green)
                              ],
                            ),
                          )
                        else if (status == 'declined')
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: const [
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
          // Invitations Tab
          _isLoadingInvitations
              ? const Center(child: CircularProgressIndicator())
              : _errorMessageInvitations != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessageInvitations!,
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInvitations,
                  child: const Text('Повторить попытку'),
                ),
              ],
            ),
          )
              : _invitations.isEmpty
              ? const Center(child: Text('Нет отправленных приглашений'))
              : RefreshIndicator(
            onRefresh: () async {
              await _loadInvitations();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _invitations.length,
              itemBuilder: (context, index) {
                final invitation = _invitations[index];
                final vacancyTitle =
                    invitation['vacancy_title'] ?? 'Не указана';
                final applicantName =
                    invitation['applicant_name'] ?? 'Не указан';
                final status = invitation['status'];
                final createdAt = invitation['created_at'] != null
                    ? DateFormat.yMMMd('ru').format(
                    DateTime.parse(invitation['created_at']))
                    : 'Не указано';
                final message = invitation['message'] ??
                    'Сообщение отсутствует';
                final vacancyId =
                invitation['vacancy_id']?.toString();
                final applicantId =
                invitation['applicant_id']?.toString();

                if (vacancyId == null || applicantId == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                          'Ошибка: vacancy_id или applicant_id отсутствует'),
                    ),
                  );
                }

                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Приглашение для: $applicantName',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Вакансия: $vacancyTitle'),
                        const SizedBox(height: 4),
                        Text('Дата: $createdAt'),
                        const SizedBox(height: 8),
                        Text('Сообщение: $message'),
                        const SizedBox(height: 16),
                        if (status == 'pending')
                          const Center(
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ожидание ответа ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Icon(Icons.pending_outlined,
                                    color: Colors.orange)
                              ],
                            ),
                          )
                        else if (status == 'accepted')
                          Center(
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Принято ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Icon(Icons.check_circle_rounded,
                                    color: Colors.green)
                              ],
                            ),
                          )
                        else if (status == 'declined')
                            Center(
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: const [
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