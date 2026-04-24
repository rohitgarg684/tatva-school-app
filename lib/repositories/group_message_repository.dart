import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/group_conversation.dart';
import '../models/message_model.dart';

class GroupMessageRepository extends BaseRepository {
  CollectionReference get _groups => db.collection('group_conversations');

  Future<GroupConversation?> createGroup(GroupConversation group) async {
    try {
      final ref = await _groups.add(group.toMap());
      return GroupConversation(
        id: ref.id,
        classId: group.classId,
        className: group.className,
        createdBy: group.createdBy,
        memberUids: group.memberUids,
      );
    } catch (_) {
      return null;
    }
  }

  Future<GroupConversation?> getByClassId(String classId) async {
    try {
      final snap =
          await _groups.where('classId', isEqualTo: classId).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return GroupConversation.fromFirestore(snap.docs.first);
    } catch (_) {
      return null;
    }
  }

  Future<List<GroupConversation>> getByMember(String uid) async {
    try {
      final snap = await _groups
          .where('memberUids', arrayContains: uid)
          .orderBy('lastMessageAt', descending: true)
          .get();
      return snap.docs
          .map((d) => GroupConversation.fromFirestore(d))
          .toList();
    } catch (_) {
      return [];
    }
  }

  CollectionReference _messagesRef(String groupId) =>
      _groups.doc(groupId).collection('messages');

  Future<bool> sendMessage(
      String groupId, MessageModel msg, String senderName) async {
    try {
      await _messagesRef(groupId).add(msg.toMap());
      await _groups.doc(groupId).update({
        'lastMessage': msg.text,
        'lastSenderName': senderName,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<List<MessageModel>> getMessages(String groupId) {
    return _messagesRef(groupId)
        .orderBy('createdAt', descending: false)
        .limit(200)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromFirestore(d)).toList());
  }

  Future<void> addMember(String groupId, String uid) {
    return _groups.doc(groupId).update({
      'memberUids': FieldValue.arrayUnion([uid]),
    });
  }
}
