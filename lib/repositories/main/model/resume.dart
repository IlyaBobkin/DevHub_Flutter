// resume.dart
class Resume {
  final String id;
  final String? userId;
  final String? applicantName;
  final String? title;
  final String? description;
  final num? expectedSalary;
  final String? specializationName;
  final String? experienceLevel;
  final String? location;
  final DateTime createdAt;

  Resume({
    required this.id,
    this.userId,
    this.applicantName,
    this.title,
    this.description,
    this.expectedSalary,
    this.specializationName,
    this.experienceLevel,
    this.location,
    required this.createdAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      applicantName: json['applicant_name'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      expectedSalary: json['expected_salary'] != null
          ? (json['expected_salary'] is String
          ? num.parse(json['expected_salary'] as String)
          : json['expected_salary'] as num)
          : null,
      specializationName: json['specialization_name'] as String?,
      experienceLevel: json['experience_level'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}