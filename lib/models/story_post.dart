enum StoryMediaType {
  none,
  image,
  video;

  factory StoryMediaType.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'image':
        return StoryMediaType.image;
      case 'video':
        return StoryMediaType.video;
      default:
        return StoryMediaType.none;
    }
  }
}

class StoryPost {
  final String id;
  final String authorUid;
  final String authorName;
  final String authorRole;
  final String classId;
  final String className;
  final String text;
  final List<String> mediaUrls;
  final StoryMediaType mediaType;
  final List<String> likedBy;
  final int commentCount;
  final DateTime? createdAt;

  const StoryPost({
    this.id = '',
    required this.authorUid,
    required this.authorName,
    this.authorRole = '',
    required this.classId,
    this.className = '',
    this.text = '',
    this.mediaUrls = const [],
    this.mediaType = StoryMediaType.none,
    this.likedBy = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);
  int get likeCount => likedBy.length;

  StoryPost copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? authorRole,
    String? classId,
    String? className,
    String? text,
    List<String>? mediaUrls,
    StoryMediaType? mediaType,
    List<String>? likedBy,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return StoryPost(
      id: id ?? this.id,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      text: text ?? this.text,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StoryPost.fromJson(Map<String, dynamic> data) {
    return StoryPost(
      id: data['id'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      text: data['text'] as String? ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      mediaType: StoryMediaType.fromString(data['mediaType'] as String? ?? ''),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'authorRole': authorRole,
      'classId': classId,
      'className': className,
      'text': text,
      'mediaUrls': mediaUrls,
      'mediaType': mediaType.name,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
