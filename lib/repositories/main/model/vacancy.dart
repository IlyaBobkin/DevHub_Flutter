import 'package:flutter/cupertino.dart';

class Vacancy {
  final String id;
  final String title;
  final String? description;
  final String? salaryFrom; // Nullable, уберём required
  final String? salaryTo;   // Nullable, уберём required
  final String? specializationName; // Теперь nullable
  final String experienceLevel;
  final String? location;
  final DateTime createdAt;
  final String companyId;
  final String? companyName; // Теперь nullable

  Vacancy({
    required this.id,
    required this.title,
    this.description,
    this.salaryFrom, // Убрали required
    this.salaryTo,   // Убрали required
    this.specializationName,
    required this.experienceLevel,
    this.location,
    required this.createdAt,
    required this.companyId,
    this.companyName,
  });

  factory Vacancy.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing Vacancy from JSON: $json');
    // Проверки на null для обязательных полей
    if (json['id'] == null) throw Exception('Vacancy id cannot be null');
    if (json['title'] == null) throw Exception('Vacancy title cannot be null');
    if (json['experience_level'] == null) throw Exception('Vacancy experience_level cannot be null');
    if (json['created_at'] == null) throw Exception('Vacancy created_at cannot be null');
    if (json['company_id'] == null) throw Exception('Vacancy company_id cannot be null');

    return Vacancy(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      salaryFrom: json['salary_from'] as String?,
      salaryTo: json['salary_to'] as String?,
      specializationName: json['specialization_name'] as String?, // Теперь nullable
      experienceLevel: json['experience_level'] as String,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String?, // Теперь nullable
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'salary_from': salaryFrom,
      'salary_to': salaryTo,
      'specialization_name': specializationName,
      'experience_level': experienceLevel,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'company_id': companyId,
      'company_name': companyName,
    };
  }
}