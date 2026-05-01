import 'package:flutter/material.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/child_info.dart';
import '../../../models/behavior_category.dart';
import '../parent_helpers.dart';

class ParentBehaviorTab extends StatelessWidget {
  final ChildDashboardData? currentChild;
  final List<ChildDashboardData> currentChildEntries;

  const ParentBehaviorTab({
    super.key,
    required this.currentChild,
    this.currentChildEntries = const [],
  });

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    final entries = currentChildEntries.isNotEmpty
        ? currentChildEntries
        : (child != null ? [child] : <ChildDashboardData>[]);
    final points = entries.expand((e) => e.behaviorPoints).toList();
    final score = entries.fold(0, (sum, e) => sum + e.behaviorScore);

    final catSummary = <String, int>{};
    for (final p in points) {
      catSummary[p.categoryId] = ((catSummary[p.categoryId] ?? 0) + p.points).toInt();
    }
    final sortedCats = catSummary.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: Text("${child?.info.childName ?? ''}'s Behavior",
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Tracking positive & constructive moments',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 20),
          FadeSlideIn(
              delayMs: 80,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: score >= 0
                            ? [
                                const Color(0xFF6A1B9A),
                                const Color(0xFFAB47BC)
                              ]
                            : [
                                TatvaColors.error.withOpacity(0.8),
                                TatvaColors.error
                              ]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: (score >= 0
                                  ? TatvaColors.purple
                                  : TatvaColors.error)
                              .withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ]),
                child: Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Score',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7))),
                        Text('$score',
                            style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ]),
                  const Spacer(),
                  Column(children: [
                    Text('${points.where((p) => p.isPositive).length}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Positive',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 6),
                    Text('${points.where((p) => !p.isPositive).length}',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Needs Work',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6))),
                  ]),
                ]),
              )),
          if (sortedCats.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Top Categories',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            const SizedBox(height: 12),
            ...sortedCats.take(5).map((e) {
              final cat = BehaviorCategory.fromId(e.key);
              final isPos = e.value >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  Icon(cat.icon,
                      color:
                          isPos ? TatvaColors.success : TatvaColors.error,
                      size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(cat.name,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TatvaColors.neutral900))),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: (isPos
                                  ? TatvaColors.success
                                  : TatvaColors.error)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${isPos ? '+' : ''}${e.value}',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPos
                                  ? TatvaColors.success
                                  : TatvaColors.error))),
                ]),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text('Recent Activity',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 12),
          if (points.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Center(
                  child: Column(children: [
                Icon(Icons.emoji_events_outlined,
                    color: TatvaColors.neutral400, size: 40),
                const SizedBox(height: 12),
                const Text('No behavior points yet',
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral400)),
              ])),
            )
          else
            ...points.take(20).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final cat = BehaviorCategory.fromId(p.categoryId);
              final timeAgo = p.createdAt != null
                  ? formatTimeAgo(p.createdAt!)
                  : '';
              return StaggeredItem(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100)),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: (p.isPositive
                                      ? TatvaColors.success
                                      : TatvaColors.error)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(cat.icon,
                              color: p.isPositive
                                  ? TatvaColors.success
                                  : TatvaColors.error,
                              size: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text(cat.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TatvaColors.neutral900)),
                            Text('By ${p.awardedByName}',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TatvaColors.neutral400)),
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        Text(p.isPositive ? '+1' : '-1',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: p.isPositive
                                    ? TatvaColors.success
                                    : TatvaColors.error)),
                        if (timeAgo.isNotEmpty)
                          Text(timeAgo,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: TatvaColors.neutral400)),
                      ]),
                    ]),
                  ));
            }),
          const SizedBox(height: 24),
        ]));
  }
}
