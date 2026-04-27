import 'package:flutter/material.dart';
import '../../models/activity_event.dart';
import '../theme/colors.dart';

IconData activityIcon(ActivityType type) => switch (type) {
      ActivityType.behaviorPoint => Icons.star_rounded,
      ActivityType.attendance => Icons.check_circle_rounded,
      ActivityType.homeworkAssigned => Icons.assignment_rounded,
      ActivityType.homeworkSubmitted => Icons.assignment_rounded,
      ActivityType.gradeEntered => Icons.grade_rounded,
      ActivityType.announcement => Icons.campaign_rounded,
      ActivityType.storyPost => Icons.photo_camera_rounded,
      ActivityType.voteCreated => Icons.how_to_vote_rounded,
      ActivityType.studentEnrolled => Icons.person_add_rounded,
    };

Color activityColor(ActivityType type) => switch (type) {
      ActivityType.behaviorPoint => TatvaColors.success,
      ActivityType.attendance => TatvaColors.info,
      ActivityType.homeworkAssigned => TatvaColors.purple,
      ActivityType.homeworkSubmitted => TatvaColors.purple,
      ActivityType.gradeEntered => TatvaColors.accent,
      ActivityType.announcement => TatvaColors.primary,
      ActivityType.storyPost => const Color(0xFF00897B),
      ActivityType.voteCreated => TatvaColors.purple,
      ActivityType.studentEnrolled => TatvaColors.info,
    };

String formatTimeAgo(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final time =
      '${local.hour % 12 == 0 ? 12 : local.hour % 12}:${local.minute.toString().padLeft(2, '0')} ${local.hour < 12 ? 'AM' : 'PM'}';

  String relative;
  if (diff.inMinutes < 1) {
    relative = 'now';
  } else if (diff.inMinutes < 60) {
    relative = '${diff.inMinutes}m ago';
  } else if (diff.inHours < 24) {
    relative = '${diff.inHours}h ago';
  } else if (diff.inDays < 7) {
    relative = '${diff.inDays}d ago';
  } else {
    relative = '${(diff.inDays / 7).floor()}w ago';
  }

  if (diff.inHours < 24) {
    final isToday = local.day == now.day &&
        local.month == now.month &&
        local.year == now.year;
    return '${isToday ? 'Today' : 'Yesterday'}, $time · $relative';
  }
  if (local.year == now.year) {
    return '${months[local.month]} ${local.day}, $time · $relative';
  }
  return '${months[local.month]} ${local.day}, ${local.year} · $relative';
}

String shortTimeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
