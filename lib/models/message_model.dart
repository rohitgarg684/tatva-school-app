class MessageModel {
  final String text;
  final bool isMe;
  final String time;

  const MessageModel({
    required this.text,
    required this.isMe,
    required this.time,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data) {
    return MessageModel(
      text: data['text'] as String? ?? '',
      isMe: data['isMe'] as bool? ?? false,
      time: data['time'] as String? ?? '',
    );
  }
}
