import '../models/group_conversation.dart';
import '../models/message_model.dart';
import '../repositories/group_message_repository.dart';

class GroupMessageService {
  final GroupMessageRepository _repo;

  GroupMessageService({GroupMessageRepository? repo})
      : _repo = repo ?? GroupMessageRepository();

  /// Gets or creates a group chat for a class.
  Future<GroupConversation?> getOrCreateClassGroup({
    required String classId,
    required String className,
    required String creatorUid,
    required List<String> memberUids,
  }) async {
    var group = await _repo.getByClassId(classId);
    if (group != null) return group;

    return _repo.createGroup(GroupConversation(
      classId: classId,
      className: className,
      createdBy: creatorUid,
      memberUids: memberUids,
    ));
  }

  Future<List<GroupConversation>> getMyGroups(String uid) {
    return _repo.getByMember(uid);
  }

  Future<bool> sendMessage(
      String groupId, MessageModel msg, String senderName) {
    return _repo.sendMessage(groupId, msg, senderName);
  }

  Stream<List<MessageModel>> getMessages(String groupId) {
    return _repo.getMessages(groupId);
  }

  Future<void> addMember(String groupId, String uid) {
    return _repo.addMember(groupId, uid);
  }
}
