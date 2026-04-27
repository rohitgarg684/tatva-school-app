class VoteModel {
  final String id;
  final String question;
  final String type;
  final List<String> options;
  final String createdBy;
  final String createdByName;
  final String createdByRole;
  final Map<String, int> votes;
  final List<String> voters;
  final bool active;
  final DateTime votingDeadline;
  final DateTime resultsVisibleUntil;
  final DateTime? createdAt;

  const VoteModel({
    required this.id,
    required this.question,
    required this.type,
    this.options = const ['school', 'no_school', 'undecided'],
    required this.createdBy,
    required this.createdByName,
    this.createdByRole = '',
    this.votes = const {},
    this.voters = const [],
    this.active = true,
    required this.votingDeadline,
    required this.resultsVisibleUntil,
    this.createdAt,
  });

  int get totalVotes => votes.values.fold(0, (a, b) => a + b);
  bool hasVoted(String uid) => voters.contains(uid);
  bool get isVotingOpen => active && DateTime.now().isBefore(votingDeadline);
  bool get areResultsVisible => DateTime.now().isBefore(resultsVisibleUntil);

  factory VoteModel.fromJson(Map<String, dynamic> data) {
    final rawVotes = data['votes'] as Map<String, dynamic>?;
    final votesMap = <String, int>{};
    if (rawVotes != null) {
      for (final e in rawVotes.entries) {
        votesMap[e.key] = (e.value as num?)?.toInt() ?? 0;
      }
    }

    return VoteModel(
      id: data['id'] as String? ?? '',
      question: data['question'] as String? ?? '',
      type: data['type'] as String? ?? '',
      options: List<String>.from(data['options'] ?? ['school', 'no_school', 'undecided']),
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      createdByRole: data['createdByRole'] as String? ?? '',
      votes: votesMap,
      voters: List<String>.from(data['voters'] ?? []),
      active: data['active'] as bool? ?? true,
      votingDeadline: DateTime.tryParse(data['votingDeadline'] as String? ?? '') ?? DateTime.now(),
      resultsVisibleUntil: DateTime.tryParse(data['resultsVisibleUntil'] as String? ?? '') ?? DateTime.now(),
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  VoteModel copyWith({
    String? id,
    String? question,
    String? type,
    List<String>? options,
    String? createdBy,
    String? createdByName,
    String? createdByRole,
    Map<String, int>? votes,
    List<String>? voters,
    bool? active,
    DateTime? votingDeadline,
    DateTime? resultsVisibleUntil,
    DateTime? createdAt,
  }) {
    return VoteModel(
      id: id ?? this.id,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByRole: createdByRole ?? this.createdByRole,
      votes: votes ?? this.votes,
      voters: voters ?? this.voters,
      active: active ?? this.active,
      votingDeadline: votingDeadline ?? this.votingDeadline,
      resultsVisibleUntil: resultsVisibleUntil ?? this.resultsVisibleUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'type': type,
      'options': options,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByRole': createdByRole,
      'votes': votes,
      'voters': voters,
      'active': active,
      'votingDeadline': votingDeadline.toIso8601String(),
      'resultsVisibleUntil': resultsVisibleUntil.toIso8601String(),
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }
}
