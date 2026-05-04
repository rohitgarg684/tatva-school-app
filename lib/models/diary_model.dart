class DiaryAttachment {
  final String url;
  final String fileName;
  final String mimeType;
  final String storagePath;

  const DiaryAttachment({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.storagePath,
  });

  factory DiaryAttachment.fromJson(Map<String, dynamic> data) {
    return DiaryAttachment(
      url: data['url'] as String? ?? '',
      fileName: data['fileName'] as String? ?? '',
      mimeType: data['mimeType'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'fileName': fileName,
    'mimeType': mimeType,
    'storagePath': storagePath,
  };

  String get fileType {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.contains('pdf')) return 'pdf';
    return 'document';
  }
}

class DiaryEntry {
  final String id;
  final String classId;
  final String studentUid;
  final String studentName;
  final String teacherUid;
  final String teacherName;
  final String date;
  final String title;
  final String body;
  final List<DiaryAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DiaryEntry({
    required this.id,
    this.classId = '',
    required this.studentUid,
    this.studentName = '',
    required this.teacherUid,
    required this.teacherName,
    required this.date,
    required this.title,
    required this.body,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> data) {
    return DiaryEntry(
      id: data['id'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      studentUid: data['studentUid'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      teacherUid: data['teacherUid'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      date: data['date'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((e) => DiaryAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'] as String) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'classId': classId,
    'studentUid': studentUid,
    'studentName': studentName,
    'teacherUid': teacherUid,
    'teacherName': teacherName,
    'date': date,
    'title': title,
    'body': body,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  DiaryEntry copyWith({
    String? id,
    String? classId,
    String? studentUid,
    String? studentName,
    String? teacherUid,
    String? teacherName,
    String? date,
    String? title,
    String? body,
    List<DiaryAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      teacherUid: teacherUid ?? this.teacherUid,
      teacherName: teacherName ?? this.teacherName,
      date: date ?? this.date,
      title: title ?? this.title,
      body: body ?? this.body,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class DiaryComment {
  final String id;
  final String entryId;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final String body;
  final List<DiaryAttachment> attachments;
  final DateTime? createdAt;

  const DiaryComment({
    required this.id,
    required this.entryId,
    required this.authorUid,
    required this.authorName,
    required this.authorRole,
    required this.body,
    this.attachments = const [],
    this.createdAt,
  });

  factory DiaryComment.fromJson(Map<String, dynamic> data) {
    return DiaryComment(
      id: data['id'] as String? ?? '',
      entryId: data['entryId'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      body: data['body'] as String? ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((e) => DiaryAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entryId': entryId,
    'authorUid': authorUid,
    'authorName': authorName,
    'authorRole': authorRole,
    'body': body,
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  DiaryComment copyWith({
    String? id,
    String? entryId,
    String? authorUid,
    String? authorName,
    String? authorRole,
    String? body,
    List<DiaryAttachment>? attachments,
    DateTime? createdAt,
  }) {
    return DiaryComment(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      body: body ?? this.body,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
