class HomeworkAttachment {
  final String url;
  final String name;
  final String type; // 'link', 'pdf', 'image'

  const HomeworkAttachment({
    required this.url,
    this.name = '',
    this.type = 'link',
  });

  factory HomeworkAttachment.fromJson(Map<String, dynamic> data) {
    return HomeworkAttachment(
      url: data['url'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? 'link',
    );
  }

  HomeworkAttachment copyWith({
    String? url,
    String? name,
    String? type,
  }) {
    return HomeworkAttachment(
      url: url ?? this.url,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'name': name, 'type': type};
}

class HomeworkSubmission {
  final String id;
  final String homeworkId;
  final String studentUid;
  final String studentName;
  final List<HomeworkAttachment> files;
  final String note;
  final String status;
  final int commentCount;
  final DateTime? submittedAt;

  const HomeworkSubmission({
    required this.id,
    required this.homeworkId,
    required this.studentUid,
    this.studentName = '',
    this.files = const [],
    this.note = '',
    this.status = 'pending',
    this.commentCount = 0,
    this.submittedAt,
  });

  factory HomeworkSubmission.fromJson(Map<String, dynamic> data) {
    return HomeworkSubmission(
      id: data['id'] as String? ?? '',
      homeworkId: data['homeworkId'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      files: (data['files'] as List?)
              ?.map((a) => HomeworkAttachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      note: data['note'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      commentCount: data['commentCount'] as int? ?? 0,
      submittedAt: data['submittedAt'] != null
          ? DateTime.tryParse(data['submittedAt'] as String)
          : null,
    );
  }
}

class HomeworkComment {
  final String id;
  final String submissionId;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final String text;
  final DateTime? createdAt;

  const HomeworkComment({
    required this.id,
    required this.submissionId,
    required this.authorUid,
    this.authorName = '',
    this.authorRole = '',
    required this.text,
    this.createdAt,
  });

  factory HomeworkComment.fromJson(Map<String, dynamic> data) {
    return HomeworkComment(
      id: data['id'] as String? ?? '',
      submissionId: data['submissionId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }
}

class HomeworkModel {
  final String id;
  final String title;
  final String description;
  final String subject;
  final String classId;
  final String className;
  final String teacherUid;
  final String teacherName;
  final String dueDate;
  final List<String> submittedBy;
  final List<HomeworkAttachment> attachments;
  final DateTime? createdAt;

  const HomeworkModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.subject,
    required this.classId,
    this.className = '',
    this.teacherUid = '',
    this.teacherName = '',
    required this.dueDate,
    this.submittedBy = const [],
    this.attachments = const [],
    this.createdAt,
  });

  bool isSubmittedBy(String uid) => submittedBy.contains(uid);

  int get submissionCount => submittedBy.length;

  factory HomeworkModel.fromJson(Map<String, dynamic> data) {
    return HomeworkModel(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      dueDate: data['dueDate'] as String? ?? '',
      submittedBy: List<String>.from(data['submittedBy'] ?? []),
      attachments: (data['attachments'] as List?)
              ?.map((a) =>
                  HomeworkAttachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  HomeworkModel copyWith({
    String? id,
    String? title,
    String? description,
    String? subject,
    String? classId,
    String? className,
    String? teacherUid,
    String? teacherName,
    String? dueDate,
    List<String>? submittedBy,
    List<HomeworkAttachment>? attachments,
    DateTime? createdAt,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      dueDate: dueDate ?? this.dueDate,
      submittedBy: submittedBy ?? this.submittedBy,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'subject': subject,
      'classId': classId,
      'className': className,
      'teacherUid': teacherUid,
      'teacherName': teacherName,
      'dueDate': dueDate,
      'submittedBy': submittedBy,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
