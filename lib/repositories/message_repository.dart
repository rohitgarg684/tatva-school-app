import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/message_model.dart';

class MessageRepository extends BaseRepository {
  CollectionReference get _messages => db.collection('messages');

  Future<bool> send(MessageModel msg) async {
    try {
      await _messages.add(msg.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _messages
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }
}
