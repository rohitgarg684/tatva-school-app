import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentCategory {
  mindfulness,
  growthMindset,
  empathy,
  gratitude,
  perseverance,
  teamwork,
  creativity,
  responsibility;

  String get label {
    switch (this) {
      case ContentCategory.mindfulness:
        return 'Mindfulness';
      case ContentCategory.growthMindset:
        return 'Growth Mindset';
      case ContentCategory.empathy:
        return 'Empathy';
      case ContentCategory.gratitude:
        return 'Gratitude';
      case ContentCategory.perseverance:
        return 'Perseverance';
      case ContentCategory.teamwork:
        return 'Teamwork';
      case ContentCategory.creativity:
        return 'Creativity';
      case ContentCategory.responsibility:
        return 'Responsibility';
    }
  }

  String get emoji {
    switch (this) {
      case ContentCategory.mindfulness:
        return '🧘';
      case ContentCategory.growthMindset:
        return '🌱';
      case ContentCategory.empathy:
        return '💛';
      case ContentCategory.gratitude:
        return '🙏';
      case ContentCategory.perseverance:
        return '💪';
      case ContentCategory.teamwork:
        return '🤝';
      case ContentCategory.creativity:
        return '🎨';
      case ContentCategory.responsibility:
        return '⭐';
    }
  }

  factory ContentCategory.fromString(String value) {
    for (final c in values) {
      if (c.name == value) return c;
    }
    return ContentCategory.mindfulness;
  }
}

class ContentItem {
  final String id;
  final String title;
  final String description;
  final ContentCategory category;
  final String videoUrl;
  final String thumbnailUrl;
  final String duration;
  final String ageGroup;
  final int viewCount;
  final List<String> completedBy;
  final DateTime? createdAt;

  const ContentItem({
    this.id = '',
    required this.title,
    required this.description,
    required this.category,
    this.videoUrl = '',
    this.thumbnailUrl = '',
    this.duration = '',
    this.ageGroup = 'All',
    this.viewCount = 0,
    this.completedBy = const [],
    this.createdAt,
  });

  bool isCompletedBy(String uid) => completedBy.contains(uid);

  factory ContentItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ContentItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: ContentCategory.fromString(data['category'] as String? ?? ''),
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      ageGroup: data['ageGroup'] as String? ?? 'All',
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      completedBy: List<String>.from(data['completedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ContentItem.fromJson(Map<String, dynamic> data) {
    return ContentItem(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: ContentCategory.fromString(data['category'] as String? ?? ''),
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      duration: data['duration'] as String? ?? '',
      ageGroup: data['ageGroup'] as String? ?? 'All',
      viewCount: (data['viewCount'] as num?)?.toInt() ?? 0,
      completedBy: List<String>.from(data['completedBy'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category.name,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'ageGroup': ageGroup,
      'viewCount': viewCount,
      'completedBy': completedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
