import 'api_service.dart';

class MessageService {
  final ApiService _api;

  MessageService({ApiService? api}) : _api = api ?? ApiService();

  String makeConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) {
    return _api.getMessages(conversationId);
  }

  Future<void> send({
    required String conversationId,
    required String receiverUid,
    required String text,
  }) async {
    await _api.sendMessage(
      conversationId: conversationId,
      receiverUid: receiverUid,
      text: text,
    );
  }
}
