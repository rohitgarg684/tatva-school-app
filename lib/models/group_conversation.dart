import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory GroupConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GroupConversation(
      id: doc.id,
      classId: data['classId'] as String? ?? '',
      className: data['className'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      memberUids: List<String>.from(data['memberUids'] ?? []),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderName: data['lastSenderName'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
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
      'lastMessageAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
