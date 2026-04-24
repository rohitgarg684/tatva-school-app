import 'package:cloud_firestore/cloud_firestore.dart';

class VoteCount {
  final int school;
  final int noSchool;
  final int undecided;

  const VoteCount({
    this.school = 0,
    this.noSchool = 0,
    this.undecided = 0,
  });

  int get total => school + noSchool + undecided;

  factory VoteCount.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const VoteCount();
    return VoteCount(
      school: (data['school'] as num?)?.toInt() ?? 0,
      noSchool: (data['no_school'] as num?)?.toInt() ?? 0,
      undecided: (data['undecided'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'school': school,
      'no_school': noSchool,
      'undecided': undecided,
    };
  }
}

class VoteModel {
  final String id;
  final String question;
  final String type;
  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final VoteCount votes;
  final List<String> voters;
  final bool active;
  final DateTime? createdAt;

  const VoteModel({
    required this.id,
    required this.question,
    required this.type,
    required this.createdBy,
    required this.createdByName,
    this.createdByRole = '',
    this.votes = const VoteCount(),
    this.voters = const [],
    this.active = true,
    this.createdAt,
  });

  bool hasVoted(String uid) => voters.contains(uid);

  factory VoteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VoteModel(
      id: doc.id,
      question: data['question'] as String? ?? '',
      type: data['type'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? '',
      votes: VoteCount.fromMap(data['votes'] as Map<String, dynamic>?),
      voters: List<String>.from(data['voters'] ?? []),
      active: data['active'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory VoteModel.fromJson(Map<String, dynamic> data) {
    return VoteModel(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      type: data['type'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? '',
      votes: VoteCount.fromMap(data['votes'] as Map<String, dynamic>?),
      voters: List<String>.from(data['voters'] ?? []),
      active: data['active'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'type': type,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'votes': votes.toMap(),
      'voters': voters,
      'active': active,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
