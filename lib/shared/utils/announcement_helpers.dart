import '../../models/announcement_model.dart';

List<AnnouncementModel> toggleAnnouncementLike(
  List<AnnouncementModel> list,
  String announcementId,
  String uid,
) {
  if (announcementId.isEmpty) return list;
  final idx = list.indexWhere((a) => a.id == announcementId);
  if (idx < 0) return list;
  final current = list[idx];
  final liked = current.likedBy.contains(uid);
  final newLikedBy = List<String>.from(current.likedBy);
  liked ? newLikedBy.remove(uid) : newLikedBy.add(uid);
  return List.of(list)..[idx] = current.copyWith(likedBy: newLikedBy);
}
