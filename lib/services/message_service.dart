import 'dart:async';
import '../models/message_model.dart';
import '../repositories/message_repository.dart';

class MessageService {
  final MessageRepository _repo;

  MessageService({MessageRepository? repo})
      : _repo = repo ?? MessageRepository();

  /// Generates a deterministic conversation ID from two user UIDs.
  String makeConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<bool> send(MessageModel msg) {
    return _repo.send(msg);
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _repo.getMessages(conversationId);
  }
}
