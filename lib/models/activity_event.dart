enum ActivityType {
  behaviorPoint,
  attendance,
  homeworkAssigned,
  homeworkSubmitted,
  gradeEntered,
  announcement,
  storyPost,
  voteCreated,
  studentEnrolled;

  String get label {
    switch (this) {
      case ActivityType.behaviorPoint:
        return 'Behavior';
      case ActivityType.attendance:
        return 'Attendance';
      case ActivityType.homeworkAssigned:
        return 'Homework';
      case ActivityType.homeworkSubmitted:
        return 'Submission';
      case ActivityType.gradeEntered:
        return 'Grade';
      case ActivityType.announcement:
        return 'Announcement';
      case ActivityType.storyPost:
        return 'Story';
      case ActivityType.voteCreated:
        return 'Vote';
      case ActivityType.studentEnrolled:
        return 'Enrollment';
    }
  }

  factory ActivityType.fromString(String value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return ActivityType.announcement;
  }
}

class ActivityEvent {
  final String id;
  final ActivityType type;
  final String actorUid;
  final String actorName;
  final String actorRole;
  final String targetUid;
  final String classId;
  final String title;
  final String body;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const ActivityEvent({
    this.id = '',
    required this.type,
    required this.actorUid,
    required this.actorName,
    this.actorRole = '',
    this.targetUid = '',
    this.classId = '',
    required this.title,
    this.body = '',
    this.metadata = const {},
    this.createdAt,
  });

  factory ActivityEvent.fromJson(Map<String, dynamic> data) {
    return ActivityEvent(
      id: data['id'] as String? ?? '',
      type: ActivityType.fromString(data['type'] as String? ?? ''),
      actorUid: data['actorUid'] as String? ?? '',
      actorName: data['actorName'] as String? ?? '',
      actorRole: data['actorRole'] as String? ?? '',
      targetUid: data['targetUid'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'actorUid': actorUid,
      'actorName': actorName,
      'actorRole': actorRole,
      'targetUid': targetUid,
      'classId': classId,
      'title': title,
      'body': body,
      'metadata': metadata,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
