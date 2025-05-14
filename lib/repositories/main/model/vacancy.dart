class Vacancy {
  final String id;
  final String title;
  final String description;
  final double salaryFrom;
  final double salaryTo;
  final String specializationName;
  final String experienceLevel;
  final String location;
  final DateTime createdAt;
  final String companyId;
  final String companyName;

  Vacancy({
    required this.id,
    required this.title,
    required this.description,
    required this.salaryFrom,
    required this.salaryTo,
    required this.specializationName,
    required this.experienceLevel,
    required this.location,
    required this.createdAt,
    required this.companyId,
    required this.companyName,
  });

  factory Vacancy.fromJson(Map<String, dynamic> json) {
    return Vacancy(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      salaryFrom: double.parse(json['salary_from'] as String), // Преобразуем строку в double
      salaryTo: double.parse(json['salary_to'] as String),     // Преобразуем строку в double
      specializationName: json['specialization_name'] as String,
      experienceLevel: json['experience_level'] as String,
      location: json['location'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      companyId: json['company_id'] as String,
      companyName: json['company_name'] as String,
    );
  }
}