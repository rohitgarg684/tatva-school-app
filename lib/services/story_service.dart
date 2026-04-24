import 'dart:typed_data';
import '../models/story_post.dart';
import '../models/activity_event.dart';
import '../repositories/story_repository.dart';
import 'activity_service.dart';
import 'api_service.dart';

class StoryService {
  final StoryRepository _repo;
  final ActivityService _activitySvc;
  final ApiService _api;

  StoryService({
    StoryRepository? repo,
    ActivityService? activitySvc,
    ApiService? api,
  })  : _repo = repo ?? StoryRepository(),
        _activitySvc = activitySvc ?? ActivityService(),
        _api = api ?? ApiService();

  Future<String?> uploadImage(
      Uint8List bytes, String classId, String fileName) {
    return _api.uploadStoryImage(bytes, classId, fileName);
  }

  Future<bool> createPost(StoryPost post) async {
    final id = await _repo.add(post);
    if (id == null) return false;

    await _activitySvc.log(ActivityEvent(
      type: ActivityType.storyPost,
      actorUid: post.authorUid,
      actorName: post.authorName,
      actorRole: post.authorRole,
      classId: post.classId,
      title: 'New story post in ${post.className}',
      body: post.text.length > 80
          ? '${post.text.substring(0, 80)}...'
          : post.text,
    ));

    return true;
  }

  Future<List<StoryPost>> getClassStory(String classId) {
    return _repo.fetchByClass(classId);
  }

  Future<List<StoryPost>> getStoriesForClasses(List<String> classIds) {
    return _repo.fetchByClasses(classIds);
  }

  Future<void> toggleLike(String postId, String uid) {
    return _repo.toggleLike(postId, uid);
  }

  Future<void> deletePost(String id) {
    return _repo.delete(id);
  }
}
