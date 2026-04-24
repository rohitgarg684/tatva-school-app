import '../models/content_item.dart';
import '../repositories/content_repository.dart';

class ContentService {
  final ContentRepository _repo;

  ContentService({ContentRepository? repo})
      : _repo = repo ?? ContentRepository();

  Future<List<ContentItem>> fetchAll() {
    return _repo.fetchAll();
  }

  Future<List<ContentItem>> fetchByCategory(ContentCategory category) {
    return _repo.fetchByCategory(category);
  }

  Future<void> markCompleted(String itemId, String uid) {
    return _repo.markCompleted(itemId, uid);
  }

  /// Returns grouped content for the "Beyond School" UI.
  Future<Map<ContentCategory, List<ContentItem>>> fetchGrouped() async {
    final all = await _repo.fetchAll();
    final grouped = <ContentCategory, List<ContentItem>>{};
    for (final item in all) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }
}
