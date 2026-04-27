import 'package:flutter/material.dart';
import '../../../models/vote_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class VoteHistorySheet {
  static void show(BuildContext context, {required ApiService api}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VoteHistoryContent(api: api),
    );
  }
}

class _VoteHistoryContent extends StatefulWidget {
  final ApiService api;
  const _VoteHistoryContent({required this.api});

  @override
  State<_VoteHistoryContent> createState() => _VoteHistoryContentState();
}

class _VoteHistoryContentState extends State<_VoteHistoryContent> {
  List<VoteModel> _votes = [];
  bool _loading = true;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (!loadMore) setState(() => _loading = true);
    try {
      final after = loadMore && _votes.isNotEmpty
          ? _votes.last.createdAt?.toIso8601String()
          : null;
      final data = await widget.api.getVoteHistory(limit: 20, after: after);
      final list = (data['votes'] as List?)
              ?.map((e) => VoteModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [];
      setState(() {
        if (loadMore) {
          _votes.addAll(list);
        } else {
          _votes = list;
        }
        _hasMore = data['hasMore'] as bool? ?? false;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(
            child: Container(
                width: 36,
                height: 3,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: TatvaColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.history_rounded,
                    color: TatvaColors.info, size: 18)),
            const SizedBox(width: 10),
            const Text('Vote History',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
          ]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: TatvaColors.purple))
              : _votes.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                        Icon(Icons.how_to_vote_outlined,
                            color: TatvaColors.neutral400, size: 40),
                        const SizedBox(height: 12),
                        const Text('No vote history yet',
                            style: TextStyle(
                                fontSize: 14, color: TatvaColors.neutral400)),
                      ]))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _votes.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _votes.length) {
                          return Center(
                            child: TextButton(
                              onPressed: () => _loadHistory(loadMore: true),
                              child: const Text('Load More',
                                  style: TextStyle(color: TatvaColors.purple)),
                            ),
                          );
                        }
                        final vote = _votes[i];
                        return _HistoryCard(vote: vote, index: i);
                      },
                    ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VoteModel vote;
  final int index;

  const _HistoryCard({required this.vote, required this.index});

  @override
  Widget build(BuildContext context) {
    final total = vote.totalVotes;
    final isActive = vote.isVotingOpen;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    String fmtDate(DateTime? dt) {
      if (dt == null) return '';
      final l = dt.toLocal();
      return '${months[l.month - 1]} ${l.day}, ${l.year}';
    }

    return FadeSlideIn(
      delayMs: index * 40,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: TatvaColors.purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(vote.type.replaceAll('_', ' '),
                  style: const TextStyle(
                      fontSize: 10,
                      color: TatvaColors.purple,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: isActive
                      ? TatvaColors.success.withOpacity(0.08)
                      : TatvaColors.neutral400.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(isActive ? 'Active' : 'Closed',
                  style: TextStyle(
                      fontSize: 10,
                      color:
                          isActive ? TatvaColors.success : TatvaColors.neutral400,
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text('$total votes',
                style: const TextStyle(
                    fontSize: 11, color: TatvaColors.neutral400)),
          ]),
          const SizedBox(height: 10),
          Text(vote.question,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  height: 1.4)),
          const SizedBox(height: 8),
          Text('Created ${fmtDate(vote.createdAt)} · Deadline ${fmtDate(vote.votingDeadline)}',
              style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
          const SizedBox(height: 10),
          ...vote.options.map((opt) {
            final count = vote.votes[opt] ?? 0;
            final pct = total > 0 ? count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(children: [
                SizedBox(
                    width: 90,
                    child: Text(opt.replaceAll('_', ' '),
                        style: const TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400))),
                Expanded(
                    child: AnimatedProgressBar(
                        value: pct,
                        color: TatvaColors.info,
                        height: 5,
                        delayMs: 0)),
                const SizedBox(width: 8),
                Text('${(pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 11,
                        color: TatvaColors.info,
                        fontWeight: FontWeight.bold)),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}
