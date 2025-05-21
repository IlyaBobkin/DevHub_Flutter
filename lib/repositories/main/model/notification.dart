class JobNotification {
  final String id;
  final String userId;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? vacancyId;
  final String? vacancyTitle;
  final String? responseId;
  final String? invitationId;

  JobNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.vacancyId,
    this.vacancyTitle,
    this.responseId,
    this.invitationId,
  });

  factory JobNotification.fromJson(Map<String, dynamic> json) {
    return JobNotification(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      type: json['type'],
      message: json['message'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      vacancyId: json['vacancy_id']?.toString(),
      vacancyTitle: json['vacancy_title'],
      responseId: json['response_id']?.toString(),
      invitationId: json['invitation_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'vacancy_id': vacancyId,
      'vacancy_title': vacancyTitle,
      'response_id': responseId,
      'invitation_id': invitationId,
    };
  }
}