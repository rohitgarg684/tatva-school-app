import 'package:flutter/material.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/child_info.dart';
import '../../../models/content_item.dart';

class ParentLearnTab extends StatelessWidget {
  final ChildDashboardData? currentChild;
  final List<ContentItem> contentItems;
  final Widget childSwitcher;

  const ParentLearnTab({
    super.key,
    required this.currentChild,
    required this.contentItems,
    required this.childSwitcher,
  });

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    final childUid = child?.childUid ?? '';
    final Map<String, List<ContentItem>> byCategory = {};
    for (final item in contentItems) {
      final key = '${item.category.emoji} ${item.category.label}';
      byCategory.putIfAbsent(key, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        childSwitcher,
        FadeSlideIn(
            child: const Text('Beyond School',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text(
                "At-home learning for ${child?.info.childName ?? 'your child'}",
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        if (contentItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 48,
                    color: TatvaColors.neutral400.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No content yet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
              ]),
            ),
          )
        else
          ...byCategory.entries.toList().asMap().entries.map((entry) {
            final catIdx = entry.key;
            final catLabel = entry.value.key;
            final items = entry.value.value;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIdx > 0) const SizedBox(height: 20),
                  StaggeredItem(
                    index: catIdx,
                    child: Text(catLabel,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((itemEntry) {
                    final ci = itemEntry.value;
                    final completed = ci.isCompletedBy(childUid);
                    return StaggeredItem(
                      index: catIdx * 10 + itemEntry.key,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: completed
                                    ? TatvaColors.success.withOpacity(0.2)
                                    : Colors.grey.shade100)),
                        child: Row(children: [
                          Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: completed
                                      ? TatvaColors.success.withOpacity(0.08)
                                      : TatvaColors.info.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                  completed
                                      ? Icons.check_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  color: completed
                                      ? TatvaColors.success
                                      : TatvaColors.info,
                                  size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(ci.title,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.neutral900,
                                        decoration: completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor:
                                            TatvaColors.neutral400)),
                                if (ci.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(ci.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: TatvaColors.neutral600,
                                            height: 1.4)),
                                  ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 11,
                                      color: TatvaColors.neutral400),
                                  const SizedBox(width: 4),
                                  Text(ci.duration,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: TatvaColors.neutral400)),
                                  if (completed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: TatvaColors.success
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: const Text('Completed',
                                          style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: TatvaColors.success)),
                                    ),
                                  ],
                                ]),
                              ])),
                        ]),
                      ),
                    );
                  }),
                ]);
          }),
        const SizedBox(height: 24),
      ]),
    );
  }
}
