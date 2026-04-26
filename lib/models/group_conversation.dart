class GroupConversation {
  final String id;
  final String classId;
  final String className;
  final String createdBy;
  final List<String> memberUids;
  final String lastMessage;
  final String lastSenderName;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const GroupConversation({
    this.id = '',
    required this.classId,
    required this.className,
    required this.createdBy,
    this.memberUids = const [],
    this.lastMessage = '',
    this.lastSenderName = '',
    this.lastMessageAt,
    this.createdAt,
  });

  factory GroupConversation.fromJson(Map<String, dynamic> data) {
    return GroupConversation(
      id: data['id'] as String? ?? '',
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] ?? []),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderName: data['lastSenderName'] as String? ?? '',
      lastMessageAt: data['lastMessageAt'] != null
          ? DateTime.tryParse(data['lastMessageAt'] as String)
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  GroupConversation copyWith({
    String? id,
    String? classId,
    String? className,
    String? createdBy,
    List<String>? memberUids,
    String? lastMessage,
    String? lastSenderName,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return GroupConversation(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      createdBy: createdBy ?? this.createdBy,
      memberUids: memberUids ?? this.memberUids,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'className': className,
      'createdBy': createdBy,
      'memberUids': memberUids,
      'lastMessage': lastMessage,
      'lastSenderName': lastSenderName,
      'lastMessageAt': DateTime.now().toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
