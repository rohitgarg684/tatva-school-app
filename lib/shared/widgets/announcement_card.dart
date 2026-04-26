import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../models/audience.dart';
import '../../features/parent/parent_helpers.dart';
import '../theme/colors.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final String currentUid;
  final bool isFirst;
  final VoidCallback? onLike;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.currentUid,
    this.isFirst = false,
    this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final liked = a.isLikedBy(currentUid);
    final likeCount = a.likedBy.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? TatvaColors.info.withOpacity(0.2)
              : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: TatvaColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign_outlined,
                  color: TatvaColors.info, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(a.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                    ),
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: TatvaColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('New',
                            style: TextStyle(
                                fontSize: 10,
                                color: TatvaColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                  const SizedBox(height: 5),
                  Text(a.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: TatvaColors.neutral600,
                          height: 1.55)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _roleBadge(a.createdByRole),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                a.createdByName,
                style: const TextStyle(
                    fontSize: 10, color: TatvaColors.neutral400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (a.audience == Audience.grades && a.grades.isNotEmpty) ...[
              const SizedBox(width: 8),
              _gradeBadge(a.grades),
            ],
            const Spacer(),
            if (a.createdAt != null)
              Text(
                formatTimeAgo(a.createdAt!),
                style: const TextStyle(
                    fontSize: 10, color: TatvaColors.neutral400),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              onTap: onLike,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: liked ? TatvaColors.error : TatvaColors.neutral400,
                ),
                if (likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text('$likeCount',
                      style: TextStyle(
                          fontSize: 11,
                          color: liked
                              ? TatvaColors.error
                              : TatvaColors.neutral400,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  static Widget _roleBadge(String role) {
    final color = switch (role.toLowerCase()) {
      'principal' => TatvaColors.purple,
      'teacher' => TatvaColors.info,
      _ => TatvaColors.neutral400,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  static Widget _gradeBadge(List<String> grades) {
    final label = grades.length <= 2
        ? grades.map((g) => 'Gr $g').join(', ')
        : '${grades.length} Grades';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TatvaColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: TatvaColors.warning)),
    );
  }
}
