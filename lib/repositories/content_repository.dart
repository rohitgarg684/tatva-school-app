import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/content_item.dart';

class ContentRepository extends BaseRepository {
  CollectionReference get _content => db.collection('content');

  Future<String?> add(ContentItem item) async {
    try {
      final ref = await _content.add(item.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<ContentItem>> fetchAll({int limit = 50}) async {
    try {
      final snap = await _content
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ContentItem.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ContentItem>> fetchByCategory(ContentCategory cat,
      {int limit = 20}) async {
    try {
      final snap = await _content
          .where('category', isEqualTo: cat.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => ContentItem.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markCompleted(String itemId, String uid) {
    return _content.doc(itemId).update({
      'completedBy': FieldValue.arrayUnion([uid]),
      'viewCount': FieldValue.increment(1),
    });
  }
}
