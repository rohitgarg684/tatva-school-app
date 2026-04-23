import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_repository.dart';
import '../models/vote_model.dart';

class VoteRepository extends BaseRepository {
  CollectionReference get _votes => db.collection('votes');

  Future<bool> create(VoteModel vote) async {
    try {
      await _votes.add(vote.toMap());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> castVote({
    required String voteId,
    required String option,
    required String voterUid,
  }) async {
    try {
      await _votes.doc(voteId).update({
        'votes.$option': FieldValue.increment(1),
        'voters': FieldValue.arrayUnion([voterUid]),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> close(String voteId) async {
    try {
      await _votes.doc(voteId).update({'active': false});
      return true;
    } catch (_) {
      return false;
    }
  }

  Stream<QuerySnapshot> getActive() {
    return _votes
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
