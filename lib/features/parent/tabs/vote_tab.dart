import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/vote_model.dart';

class ParentVoteTab extends StatelessWidget {
  final List<VoteModel> activeVotes;
  final String uid;
  final void Function(int index, String option) onCastVote;

  const ParentVoteTab({
    super.key,
    required this.activeVotes,
    required this.uid,
    required this.onCastVote,
  });

  @override
  Widget build(BuildContext context) {
    final visibleVotes = activeVotes.where((v) => v.areResultsVisible).toList();
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Active Vote',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Your vote matters for school decisions',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 24),
          if (visibleVotes.isEmpty)
            FadeSlideIn(
                delayMs: 80,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.how_to_vote_outlined,
                        color: TatvaColors.neutral400, size: 40),
                    const SizedBox(height: 12),
                    const Text('No active votes right now',
                        style: TextStyle(
                            fontSize: 14, color: TatvaColors.neutral400)),
                  ])),
                ))
          else
            ...visibleVotes.asMap().entries.map((entry) {
              final i = entry.key;
              final voteData = entry.value;
              final total = voteData.totalVotes;
              final hasVoted = voteData.hasVoted(uid);
              final canVote = voteData.isVotingOpen && !hasVoted;
              final originalIdx = activeVotes.indexOf(voteData);
              return FadeSlideIn(
                  delayMs: 80 + i * 60,
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: i < visibleVotes.length - 1 ? 16 : 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: TatvaColors.info.withOpacity(0.2),
                            width: 1.5)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color:
                                        TatvaColors.info.withOpacity(0.08),
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                child: Text(voteData.type.replaceAll('_', ' '),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: TatvaColors.info,
                                        fontWeight: FontWeight.w700))),
                            const Spacer(),
                            if (!voteData.isVotingOpen)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                      color: TatvaColors.neutral400.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Voting Closed',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: TatvaColors.neutral400,
                                          fontWeight: FontWeight.w700))),
                            Text('$total votes',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ]),
                          const SizedBox(height: 14),
                          Text(voteData.question,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.neutral900,
                                  height: 1.4)),
                          const SizedBox(height: 20),
                          if (canVote)
                            ...voteData.options.map((opt) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                    onTap: () => onCastVote(originalIdx, opt),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                          color: TatvaColors.info.withOpacity(0.06),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                              color: TatvaColors.info.withOpacity(0.2))),
                                      child: Row(children: [
                                        Icon(_optionIcon(opt),
                                            color: TatvaColors.info, size: 18),
                                        const SizedBox(width: 12),
                                        Text(_optionLabel(opt),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: TatvaColors.neutral900)),
                                      ]),
                                    ))))
                          else
                            ...voteData.options.map((opt) {
                              final count = voteData.votes[opt] ?? 0;
                              final pct = total > 0 ? count / total : 0.0;
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 110,
                                        child: Text(_optionLabel(opt),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: TatvaColors.neutral400))),
                                    Expanded(
                                        child: AnimatedProgressBar(
                                            value: pct,
                                            color: _optionColor(opt),
                                            height: 6,
                                            delayMs: 0)),
                                    const SizedBox(width: 8),
                                    Text('${(pct * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _optionColor(opt),
                                            fontWeight: FontWeight.bold)),
                                  ]));
                            }),
                          if (hasVoted)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: TatvaColors.success.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        color: TatvaColors.success, size: 14),
                                    const SizedBox(width: 6),
                                    const Text('Your vote has been submitted',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: TatvaColors.success))
                                  ]),
                            ),
                        ]),
                  ));
            }),
        ]));
  }

  IconData _optionIcon(String opt) {
    switch (opt) {
      case 'school':
        return Icons.school_outlined;
      case 'no_school':
        return Icons.home_outlined;
      case 'undecided':
        return Icons.help_outline_rounded;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _optionLabel(String opt) {
    switch (opt) {
      case 'school':
        return 'School as usual';
      case 'no_school':
        return 'No school tomorrow';
      case 'undecided':
        return 'Undecided';
      default:
        return opt.replaceAll('_', ' ');
    }
  }

  Color _optionColor(String opt) {
    switch (opt) {
      case 'school':
        return TatvaColors.success;
      case 'no_school':
        return TatvaColors.error;
      case 'undecided':
        return TatvaColors.accent;
      default:
        return TatvaColors.info;
    }
  }
}
