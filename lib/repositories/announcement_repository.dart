import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository extends BaseRepository {
  CollectionReference get _announcements => db.collection('announcements');

  Future<bool> post(AnnouncementModel announcement) async {
    try {
      await _announcements.add(announcement.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot> getAll({int limit = 20}) {
    return _announcements
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<List<AnnouncementModel>> fetchAll({int limit = 20}) async {
    try {
      final snap = await _announcements
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((d) => AnnouncementModel.fromFirestore(d))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<AnnouncementModel>> getForAudience(String audience,
      {int limit = 20}) async {
    try {
      final all = await fetchAll(limit: 50);
      return all
          .where((a) =>
              a.audience == 'Everyone' ||
              a.audience == audience)
          .take(limit)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
