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

  factory VoteCount.fromJson(Map<String, dynamic>? data) {
    if (data == null) return const VoteCount();
    return VoteCount(
      school: (data['school'] as num?)?.toInt() ?? 0,
      noSchool: (data['no_school'] as num?)?.toInt() ?? 0,
      undecided: (data['undecided'] as num?)?.toInt() ?? 0,
    );
  }

  VoteCount copyWith({
    int? school,
    int? noSchool,
    int? undecided,
  }) {
    return VoteCount(
      school: school ?? this.school,
      noSchool: noSchool ?? this.noSchool,
      undecided: undecided ?? this.undecided,
    );
  }

  Map<String, dynamic> toJson() {
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

  factory VoteModel.fromJson(Map<String, dynamic> data) {
    return VoteModel(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      type: data['type'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? '',
      votes: VoteCount.fromJson(data['votes'] as Map<String, dynamic>?),
      voters: List<String>.from(data['voters'] ?? []),
      active: data['active'] as bool? ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  VoteModel copyWith({
    String? id,
    String? question,
    String? type,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    VoteCount? votes,
    List<String>? voters,
    bool? active,
    DateTime? createdAt,
  }) {
    return VoteModel(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      votes: votes ?? this.votes,
      voters: voters ?? this.voters,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'votes': votes.toJson(),
      'voters': voters,
      'active': active,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
