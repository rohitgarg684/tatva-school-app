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

  factory MessageModel.fromJson(Map<String, dynamic> data) {
    return MessageModel(
      id: data['id'] as String? ?? '',
      text: data['text'] as String? ?? '',
      senderUid: data['senderUid'] as String? ?? '',
      receiverUid: data['receiverUid'] as String? ?? '',
      conversationId: data['conversationId'] as String? ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'conversationId': conversationId,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
