import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import '../applicant/response_detail_screen.dart';
import 'company_response_detail_screen.dart';

class CompanyResponsesScreen extends StatefulWidget {
  const CompanyResponsesScreen({super.key});

  @override
  State<CompanyResponsesScreen> createState() => _CompanyResponsesScreenState();
}

class _CompanyResponsesScreenState extends State<CompanyResponsesScreen> with RouteAware {
  final ApiService _apiService = ApiService();
  List<dynamic> _responses = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollingTimer;

  @override
  void initState() {
    initializeDateFormatting('ru');
    super.initState();
    _loadResponses();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _loadResponses();
    });
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Loading employer responses');
      final responses = await _apiService.getOwnerVacancyResponses();
      debugPrint('Employer responses: $responses');
      if (mounted) {
        setState(() {
          _responses = responses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки откликов работодателя: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didPopNext() {
    // Called when returning to this screen
    _loadResponses();
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
        title: const Text('Входящие отклики'),
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
              onPressed: _loadResponses,
              child: const Text('Повторить попытку'),
            ),
          ],
        ),
      )
          : _responses.isEmpty
          ? const Center(child: Text('Нет входящих откликов'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _responses.length,
        itemBuilder: (context, index) {
          final response = _responses[index];
          final vacancyTitle = response['vacancy_title'] ??
              response['item_title'] ??
              'Не указана';
          final applicantName =
              response['applicant_name'] ?? 'Не указан';
          final createdAt = response['created_at'] != null
              ? DateFormat.yMMMd('ru')
              .format(DateTime.parse(response['created_at']))
              : 'Не указано';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              trailing: (response['status'] == 'accepted') ? Icon(Icons.check_circle_rounded, color: Colors.green)  : (response['status'] == 'rejected') ? Icon(Icons.close, color: Colors.red) : Icon(Icons.pending_outlined, color: Colors.orange),
              title:
              Text('Отклик на вакансию "$vacancyTitle"'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Соискатель: $applicantName'),
                  Text('Дата: $createdAt'),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CompanyResponseDetailScreen(
                      responseId: response['id'].toString(),
                    ),
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