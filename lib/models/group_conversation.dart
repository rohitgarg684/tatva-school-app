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

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'createdBy': createdBy,
      'memberUids': memberUids,
      'lastMessage': lastMessage,
      'lastSenderName': lastSenderName,
      'lastMessageAt': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
