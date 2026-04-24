import 'api_service.dart';

class GroupMessageService {
  final ApiService _api;

  GroupMessageService({ApiService? api}) : _api = api ?? ApiService();

  Future<List<Map<String, dynamic>>> getMessages(String groupId) {
    return _api.getGroupMessages(groupId);
  }

  Future<void> sendMessage(
    String groupId,
    String text,
    String senderName,
  ) async {
    await _api.sendGroupMessage(
      groupId: groupId,
      text: text,
      senderName: senderName,
    );
  }
}
