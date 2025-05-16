import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_new_project/features/vacancies/view/vacancies/applicant/applicant_vacancies_detail_screen.dart';
import '../../../../../repositories/main/model/vacancy.dart';
import '../../../../../repositories/main/repository.dart';

class ApplicantVacanciesScreen extends StatefulWidget {
  const ApplicantVacanciesScreen({super.key});

  @override
  State<ApplicantVacanciesScreen> createState() => _ApplicantVacanciesScreenState();
}

class _ApplicantVacanciesScreenState extends State<ApplicantVacanciesScreen> {
  String _searchQuery = '';
  String _selectedFilter = ''; // Изменили начальное значение на пустую строку
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
      final vacancies = await Repository().getVacancies();
      setState(() {
        _vacanciesList = vacancies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Обновлённая фильтрация: отображать все вакансии, если фильтр не выбран
  List<Vacancy> get _filteredVacancies {
    return _vacanciesList.where((vacancy) {
      final matchesSearch = vacancy.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (vacancy.specializationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesFilter = _selectedFilter.isEmpty ||
          (vacancy.specializationName?.toLowerCase().contains(_selectedFilter.toLowerCase()) ?? false);
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            SizedBox(width: 8),
            Text(
              'DevHub',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
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
                hintText: 'Поиск вакансий',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune, color: Colors.grey),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: VacancySearchDelegate(
                        vacancies: _vacanciesList,
                        onSelect: (vacancyId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ApplicantVacancyDetailScreen(vacancyId: vacancyId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFilterChip('Frontend', _selectedFilter == 'Frontend'),
                _buildFilterChip('Backend', _selectedFilter == 'Backend'),
                _buildFilterChip('UI/UX', _selectedFilter == 'UI/UX'),
                _buildFilterChip('Flutter', _selectedFilter == 'Flutter'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _filteredVacancies.isEmpty
                ? const Center(child: Text('Нет доступных вакансий'))
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
                          '${vacancy.salaryFrom ?? 'Не указано'} - ${vacancy.salaryTo ?? 'Не указано'} ₽ в месяц',
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(CupertinoIcons.briefcase, color: Theme.of(context).colorScheme.primary, size: 18),
                            const SizedBox(width: 5),
                            Expanded(
                              child:                         Text(
                                vacancy.companyName ?? 'Не указано',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary, size: 18),
                            const SizedBox(width: 5),
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
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ApplicantVacancyDetailScreen(vacancyId: vacancy.id),
                        ),
                      );
                    },
                    horizontalTitleGap: 16.0,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? '' : label; // Сбрасываем фильтр, если тот же чип нажат повторно
        });
      },
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? Colors.blue : Colors.grey, width: 2),
        ),
      ),
    );
  }
}

// Поиск вакансий
class VacancySearchDelegate extends SearchDelegate<String> {
  final List<Vacancy> vacancies;
  final Function(String) onSelect;

  VacancySearchDelegate({required this.vacancies, required this.onSelect});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = vacancies.where((vacancy) {
      return vacancy.title.toLowerCase().contains(query.toLowerCase()) ||
          (vacancy.specializationName?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final vacancy = results[index];
        return ListTile(
          title: Text(vacancy.title),
          subtitle: Text(vacancy.specializationName ?? 'Не указано'),
          onTap: () {
            onSelect(vacancy.id);
            close(context, vacancy.id);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = vacancies.where((vacancy) {
      return vacancy.title.toLowerCase().contains(query.toLowerCase()) ||
          (vacancy.specializationName?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final vacancy = suggestions[index];
        return ListTile(
          title: Text(vacancy.title),
          subtitle: Text(vacancy.specializationName ?? 'Не указано'),
          onTap: () {
            query = vacancy.title;
            showResults(context);
          },
        );
      },
    );
  }
}