import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String text;
  final String senderUid;
  final String receiverUid;
  final String conversationId;
  final DateTime? createdAt;

  const MessageModel({
    this.id = '',
    required this.text,
    required this.senderUid,
    required this.receiverUid,
    required this.conversationId,
    this.createdAt,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      text: data['text'] as String? ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      receiverUid: data['receiverUid'] as String? ?? '',
      conversationId: data['conversationId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'conversationId': conversationId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
