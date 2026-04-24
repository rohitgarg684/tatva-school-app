import '../models/announcement_model.dart';
import '../models/audience.dart';
import '../repositories/announcement_repository.dart';

class AnnouncementService {
  final AnnouncementRepository _repo;

  AnnouncementService({AnnouncementRepository? repo})
      : _repo = repo ?? AnnouncementRepository();

  Future<bool> post(AnnouncementModel model) {
    return _repo.post(model);
  }

  Future<List<AnnouncementModel>> fetchAll({int limit = 20}) {
    return _repo.fetchAll(limit: limit);
  }

  /// Returns announcements visible to the given audience.
  Future<List<AnnouncementModel>> fetchForAudience(Audience roleAudience,
      {int limit = 20}) async {
    final all = await _repo.fetchAll(limit: 50);
    return all
        .where((a) => a.audience.isVisibleTo(roleAudience))
        .take(limit)
        .toList();
  }
}
