import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_new_project/repositories/main/api_service.dart';
import 'package:my_new_project/repositories/main/model/vacancy.dart';
import '../../../../authorization/view/login_screen.dart';
import 'company_vacancies_detail_screen.dart';
import 'actions/create_vacancy_screen.dart';

class CompanyVacanciesScreen extends StatefulWidget {
  const CompanyVacanciesScreen({super.key});

  @override
  State<CompanyVacanciesScreen> createState() => _CompanyVacanciesScreenState();
}

class _CompanyVacanciesScreenState extends State<CompanyVacanciesScreen> {
  final ApiService _apiService = ApiService();
  String _searchQuery = '';
  List<Vacancy> _vacanciesList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVacancies();
  }

  Future<void> _loadVacancies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final vacancies = await _apiService.getMyVacancies();
      if (mounted) {
        setState(() {
          _vacanciesList = vacancies.map((v) {
            debugPrint('Vacancy JSON: $v');
            return Vacancy.fromJson(v);
          }).toList();
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

  List<Vacancy> get _filteredVacancies {
    return _vacanciesList.where((vacancy) {
      final titleMatch = vacancy.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final specializationMatch = vacancy.specializationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return titleMatch || specializationMatch;
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
                'Мои вакансии',
              ),
            ],
          ),
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
                  hintText: 'Поиск моих вакансий',
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
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
                  : _filteredVacancies.isEmpty
                  ? const Center(child: Text('Нет созданных вакансий'))
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _filteredVacancies.length,
                itemBuilder: (context, index) {
                  final vacancy = _filteredVacancies[index];
                  return Card(
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
                            DateFormat.yMMMd('ru').format(vacancy.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            vacancy.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            '${vacancy.salaryFrom ?? 'Зарплата не указана'} ${vacancy.salaryTo != null ? '- ${vacancy.salaryTo}' : ''} ₽ в месяц',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 15),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  vacancy.location ?? 'Местоположение не указано',
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
                            builder: (context) => CompanyVacancyDetailScreen(vacancyId: vacancy.id),
                          ),
                        );
                        if (result == true) {
                          await _loadVacancies();
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
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateVacancyScreen()),
            );
            if (result == true) {
              await _loadVacancies();
            }
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}