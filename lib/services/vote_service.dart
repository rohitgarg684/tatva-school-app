import '../models/vote_model.dart';
import '../repositories/vote_repository.dart';

class VoteService {
  final VoteRepository _repo;

  VoteService({VoteRepository? repo}) : _repo = repo ?? VoteRepository();

  Future<bool> create(VoteModel vote) {
    return _repo.create(vote);
  }

  Future<bool> castVote({
    required String voteId,
    required String option,
    required String voterUid,
  }) {
    return _repo.castVote(
      voteId: voteId,
      option: option,
      voterUid: voterUid,
    );
  }

  Future<bool> close(String voteId) {
    return _repo.close(voteId);
  }

  Future<List<VoteModel>> fetchActive() {
    return _repo.fetchActive();
  }
}
