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

  MessageModel copyWith({
    String? id,
    String? text,
    String? senderUid,
    String? receiverUid,
    String? conversationId,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      senderUid: senderUid ?? this.senderUid,
      receiverUid: receiverUid ?? this.receiverUid,
      conversationId: conversationId ?? this.conversationId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'conversationId': conversationId,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
