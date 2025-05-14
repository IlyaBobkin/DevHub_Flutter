// Экран деталей вакансии
import 'package:flutter/material.dart';

class VacancyDetailScreen extends StatelessWidget {
  final int vacancyId;

  const VacancyDetailScreen({super.key, required this.vacancyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment:  CrossAxisAlignment.start,
              children: [
                Text(
                  'Вакансия $vacancyId',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Компания XYZ'),
                const SizedBox(height: 8),
                const Text('Зарплата: 100,000 ₽'),
                const SizedBox(height: 16),
                const Text('Описание: Lorem ipsum dolor sit amet, consectetur adipiscing elit.'),
                const SizedBox(height: 16),
              ],
            ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/vacancies');
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ), elevation: 10
                ),
                child: const Text(
                  'Откликнуться',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}