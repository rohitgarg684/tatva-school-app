import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/story_post.dart';

class StoryRepository extends BaseRepository {
  CollectionReference get _stories => db.collection('stories');

  Future<String?> add(StoryPost post) async {
    try {
      final ref = await _stories.add(post.toMap());
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  Future<List<StoryPost>> fetchByClass(String classId,
      {int limit = 30}) async {
    try {
      final snap = await _stories
          .where('classId', isEqualTo: classId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => StoryPost.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StoryPost>> fetchByClasses(List<String> classIds,
      {int limit = 30}) async {
    if (classIds.isEmpty) return [];
    try {
      final snap = await _stories
          .where('classId', whereIn: classIds.take(10).toList())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map((d) => StoryPost.fromFirestore(d)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> toggleLike(String postId, String uid) async {
    final ref = _stories.doc(postId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final liked = List<String>.from(
        (doc.data() as Map<String, dynamic>)['likedBy'] ?? []);
    if (liked.contains(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid])
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid])
      });
    }
  }

  Future<void> delete(String id) => _stories.doc(id).delete();
}
