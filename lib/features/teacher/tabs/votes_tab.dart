import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/vote_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../widgets/create_vote_sheet.dart';
import '../widgets/vote_history_sheet.dart';

class TeacherVotesTab extends StatelessWidget {
  final List<VoteModel> votes;
  final String uid;
  final ApiService api;
  final void Function(VoteModel vote) onVoteCreated;
  final void Function(VoteModel vote) onVoteUpdated;
  final void Function(String voteId) onVoteDeleted;
  final void Function(VoteModel vote) onVoteClosed;

  const TeacherVotesTab({
    super.key,
    required this.votes,
    required this.uid,
    required this.api,
    required this.onVoteCreated,
    required this.onVoteUpdated,
    required this.onVoteDeleted,
    required this.onVoteClosed,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
          child: const Text('Vote Management',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.8)),
        ),
        FadeSlideIn(
          delayMs: 60,
          child: const Text('Create and manage votes for parents',
              style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          delayMs: 80,
          child: Row(children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: 'Create Vote',
                color: TatvaColors.purple,
                onTap: () => TeacherCreateVoteSheet.show(
                  context,
                  api: api,
                  uid: uid,
                  onVoteCreated: onVoteCreated,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.history_rounded,
                label: 'Vote History',
                color: TatvaColors.info,
                onTap: () => VoteHistorySheet.show(context, api: api),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Text('Current Votes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.3)),
          const SizedBox(width: 8),
          if (votes.isNotEmpty)
            PulseBadge(count: votes.length, color: TatvaColors.purple),
        ]),
        const SizedBox(height: 12),
        if (votes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade100)),
            child: Column(children: [
              Icon(Icons.how_to_vote_outlined,
                  color: TatvaColors.neutral400, size: 40),
              const SizedBox(height: 12),
              const Text('No active votes',
                  style: TextStyle(fontSize: 14, color: TatvaColors.neutral400)),
              const SizedBox(height: 4),
              const Text('Tap "Create Vote" to start one',
                  style: TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
            ]),
          )
        else
          ...votes.asMap().entries.map((entry) {
            final i = entry.key;
            final vote = entry.value;
            return FadeSlideIn(
              delayMs: 100 + i * 60,
              child: _VoteCard(
                vote: vote,
                uid: uid,
                api: api,
                onUpdated: onVoteUpdated,
                onDeleted: () => onVoteDeleted(vote.id),
                onClosed: () => onVoteClosed(vote),
              ),
            );
          }),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  final VoteModel vote;
  final String uid;
  final ApiService api;
  final void Function(VoteModel) onUpdated;
  final VoidCallback onDeleted;
  final VoidCallback onClosed;

  const _VoteCard({
    required this.vote,
    required this.uid,
    required this.api,
    required this.onUpdated,
    required this.onDeleted,
    required this.onClosed,
  });

  @override
  Widget build(BuildContext context) {
    final total = vote.totalVotes;
    final isOpen = vote.isVotingOpen;
    final deadline = vote.votingDeadline;
    final resultsUntil = vote.resultsVisibleUntil;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isOpen
                  ? TatvaColors.purple.withOpacity(0.2)
                  : Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: TatvaColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6)),
            child: Text(vote.type,
                style: const TextStyle(
                    fontSize: 10,
                    color: TatvaColors.purple,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: isOpen
                    ? TatvaColors.success.withOpacity(0.08)
                    : TatvaColors.neutral400.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6)),
            child: Text(isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                    fontSize: 10,
                    color: isOpen ? TatvaColors.success : TatvaColors.neutral400,
                    fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: TatvaColors.neutral400, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (val) => _handleAction(context, val),
              itemBuilder: (_) => [
                if (isOpen)
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (isOpen)
                  const PopupMenuItem(value: 'close', child: Text('Close Voting')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: TatvaColors.error))),
              ],
            ),
        ]),
        const SizedBox(height: 10),
        Text(vote.question,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TatvaColors.neutral900,
                height: 1.4)),
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.people_outline, color: TatvaColors.neutral400, size: 13),
          const SizedBox(width: 4),
          Text('$total voted',
              style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
          const SizedBox(width: 16),
          Icon(Icons.timer_outlined, color: TatvaColors.neutral400, size: 13),
          const SizedBox(width: 4),
          Text(_formatDate(deadline),
              style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
        ]),
        const SizedBox(height: 4),
        Text('Results visible until ${_formatDate(resultsUntil)}',
            style: const TextStyle(fontSize: 10, color: TatvaColors.neutral400)),
        const SizedBox(height: 12),
        ...vote.options.map((opt) {
          final count = vote.votes[opt] ?? 0;
          final pct = total > 0 ? count / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              SizedBox(
                  width: 100,
                  child: Text(_optionLabel(opt),
                      style: const TextStyle(
                          fontSize: 12, color: TatvaColors.neutral400))),
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
            ]),
          );
        }),
      ]),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        TeacherCreateVoteSheet.show(
          context,
          api: api,
          uid: uid,
          existingVote: vote,
          onVoteCreated: onUpdated,
        );
      case 'close':
        _confirmClose(context);
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _confirmClose(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Close Voting', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('No more votes will be accepted. Results will remain visible until the results end date.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: TatvaColors.neutral400))),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await api.closeVote(vote.id);
                onClosed();
              },
              child: const Text('Close', style: TextStyle(color: TatvaColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Vote', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently remove this vote and all its data.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: TatvaColors.neutral400))),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await api.deleteVote(vote.id);
                onDeleted();
              },
              child: const Text('Delete', style: TextStyle(color: TatvaColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final l = dt.toLocal();
    return '${months[l.month - 1]} ${l.day}, ${l.year}';
  }

  String _optionLabel(String opt) {
    switch (opt) {
      case 'school':
        return '🏫 School';
      case 'no_school':
        return '🏠 No School';
      case 'undecided':
        return '🤷 Undecided';
      default:
        return opt;
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
