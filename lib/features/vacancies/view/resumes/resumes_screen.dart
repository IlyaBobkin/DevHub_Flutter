import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/resume.dart';
import '../../../authorization/view/login_screen.dart';
import 'resume_detail_screen.dart';

class ResumesScreen extends StatefulWidget {
  const ResumesScreen({super.key});

  @override
  State<ResumesScreen> createState() => _ResumesScreenState();
}

class _ResumesScreenState extends State<ResumesScreen> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  List<Resume> _resumesList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final resumes = await _apiService.getAllResumes();
      if (mounted) {
        setState(() {
          _resumesList = resumes.map((r) => Resume.fromJson(r as Map<String, dynamic>)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('Токен авторизации отсутствует') || e.toString().contains('Сессия истекла') || e.toString().contains('Доступ запрещён')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  List<Resume> get _filteredResumes {
    return _resumesList.where((resume) {
      final titleMatch = resume.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final specializationMatch = resume.specializationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final applicantNameMatch = resume.applicantName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return titleMatch || specializationMatch || applicantNameMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Row(
            children: [
              SizedBox(width: 8),
              Text(
                'Все резюме',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Поиск резюме',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _filteredResumes.isEmpty
                  ? const Center(child: Text('Нет доступных резюме'))
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredResumes.length,
                itemBuilder: (context, index) {
                  final resume = _filteredResumes[index];
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(15.0),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.yMMMd('ru').format(resume.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            resume.specializationName ?? 'Не указана',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary, size: 18),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  'Имя: ${resume.applicantName ?? 'Не указано'}',
                                  style: const TextStyle(color: Colors.blue, fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.star_border, color: Theme.of(context).colorScheme.primary, size: 18),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  "Уровень опыта: ${resume.experienceLevel ?? 'Не указан'}",
                                  style: const TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  resume.location ?? 'Не указано',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward, color: Colors.grey),
                      isThreeLine: true,
                      subtitleTextStyle: const TextStyle(color: Colors.grey),
                      onTap: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ResumeDetailScreen(resumeId: resume.id),
                          ),
                        );
                        if (result == true) {
                          await _loadResumes();
                        }
                      },
                      horizontalTitleGap: 16.0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}