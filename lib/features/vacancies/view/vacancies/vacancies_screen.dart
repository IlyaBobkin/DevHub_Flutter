// Экран "Вакансии" в стиле изображения
import 'package:flutter/material.dart';
import 'package:my_new_project/features/vacancies/view/vacancies/vacancies_detail_screen.dart';

import '../../../../repositories/main/repository.dart';

class VacanciesScreen extends StatefulWidget {
  const VacanciesScreen({super.key});

  @override
  State<VacanciesScreen> createState() => _VacanciesScreenState();
}

class _VacanciesScreenState extends State<VacanciesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Frontend';

  @override
  void initState() {
    Repository().getVacancies();
    super.initState();
  }

  final List<Map<String, dynamic>> _vacancies = [
    {
      'title': 'UI/UX Designer',
      'company': 'Badoo Inc.',
      'location': 'г. Санкт-Петербург',
      'zp': '30.000 - 45.000 ₽',
      'type': ['Full-time', 'Intern'],
      'timeAgo': '2 hours ago',
      'isSponsored': true,
    },
    {
      'title': 'Sr. UI/UX Designer',
      'company': 'Meta Inc.',
      'location': 'г. Москва',
      'zp': '30.000 - 45.000 ₽',
      'type': ['Full-time', 'Remote'],
      'timeAgo': '5 hours ago',
      'isSponsored': true,
    },
    {
      'title': 'Sr. UI Developer',
      'company': 'Netflix Inc.',
      'location': 'г. Санкт-Петербург',
      'zp': '30.000 - 45.000 ₽',
      'type': ['Full-time', 'Shift'],
      'timeAgo': '30 min ago',
      'isSponsored': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              'DevHub',
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
                hintText: 'Поиск вакансий',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: const Icon(Icons.tune, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
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
                _buildFilterChip('Java', _selectedFilter == 'Java'),
                _buildFilterChip('UI/UX', _selectedFilter == 'UI/UX'),
                _buildFilterChip('Flutter', _selectedFilter == 'Flutter'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _vacancies.length,
              itemBuilder: (context, index) {
                final vacancy = _vacancies[index];
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15.0),
                    title: Text(
                      vacancy['title']!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      spacing: 5,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 2,),
                        Text(
                          vacancy['zp']! + " в месяц",
                          style: const TextStyle(color: Colors.blue, fontSize: 15),
                        ),
                        Text(
                          vacancy['company']!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          vacancy['location']!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.favorite_border, color: Colors.black),
                    isThreeLine: true,
                    subtitleTextStyle: const TextStyle(color: Colors.grey),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => VacancyDetailScreen(vacancyId: index + 1),
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
          _selectedFilter = label;
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
        //backgroundColor: isSelected ? Colors.blue : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? Colors.blue : Colors.grey, width: 2),
        ),
      ),
    );
  }}

// Поиск вакансий
class VacancySearchDelegate extends SearchDelegate<String> {
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
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Результат поиска ${index + 1} для "$query"'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VacancyDetailScreen(vacancyId: index + 1),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('Подсказка ${index + 1}'),
          onTap: () {
            query = 'Подсказка ${index + 1}';
            showResults(context);
          },
        );
      },
    );
  }
}

