import 'audience.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final Audience audience;
  final List<String> classIds;
  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final DateTime? createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.classIds = const [],
    required this.createdBy,
    required this.createdByName,
    required this.createdByRole,
    this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> data) {
    return AnnouncementModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      audience: Audience.fromString(data['audience'] as String? ?? ''),
      classIds: List<String>.from(data['classIds'] ?? []),
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? body,
    Audience? audience,
    List<String>? classIds,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    DateTime? createdAt,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      audience: audience ?? this.audience,
      classIds: classIds ?? this.classIds,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'audience': audience.label,
      'classIds': classIds,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
