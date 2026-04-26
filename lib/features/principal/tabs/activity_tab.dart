import 'package:flutter/material.dart';
import '../../../models/activity_event.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class ActivityTab extends StatelessWidget {
  final List<ActivityEvent> activityFeed;
  final VoidCallback onRefresh;

  const ActivityTab({
    super.key,
    required this.activityFeed,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity Feed',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900,
                        letterSpacing: -0.8)),
                SizedBox(height: 4),
                Text('School-wide events and updates',
                    style: TextStyle(
                        fontSize: 13, color: TatvaColors.neutral400)),
              ],
            ),
          ),
        ),
        SizedBox(height: 20),
        Expanded(
          child: activityFeed.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timeline_outlined,
                            color: TatvaColors.neutral400, size: 48),
                        SizedBox(height: 12),
                        Text('No recent activity',
                            style: TextStyle(
                                fontSize: 15,
                                color: TatvaColors.neutral400)),
                        SizedBox(height: 6),
                        Text(
                            'Events will appear here as they happen',
                            style: TextStyle(
                                fontSize: 12,
                                color: TatvaColors.neutral400)),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: TatvaColors.purple,
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemCount: activityFeed.length,
                    itemBuilder: (_, index) {
                      final event = activityFeed[index];
                      final color = _activityColor(event.type);
                      final icon = _activityIcon(event.type);
                      final isLast =
                          index == activityFeed.length - 1;
                      return StaggeredItem(
                        index: index,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 40,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                          color: color
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  10)),
                                      child: Icon(icon,
                                          color: color, size: 18),
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          margin: EdgeInsets
                                              .symmetric(
                                                  vertical: 4),
                                          color:
                                              Colors.grey.shade200,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  margin:
                                      EdgeInsets.only(bottom: 16),
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: TatvaColors.bgCard,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: Border.all(
                                          color: Colors
                                              .grey.shade100)),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                          child:
                                              Row(children: [
                                            Text(event.actorName,
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                    color: TatvaColors
                                                        .neutral900)),
                                            SizedBox(width: 6),
                                            if (event.actorRole
                                                .isNotEmpty)
                                              Container(
                                                padding: EdgeInsets
                                                    .symmetric(
                                                        horizontal:
                                                            6,
                                                        vertical:
                                                            2),
                                                decoration: BoxDecoration(
                                                    color: color
                                                        .withOpacity(
                                                            0.1),
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                                4)),
                                                child: Text(
                                                    event
                                                        .actorRole,
                                                    style: TextStyle(
                                                        fontSize:
                                                            9,
                                                        fontWeight:
                                                            FontWeight
                                                                .w700,
                                                        color:
                                                            color)),
                                              ),
                                          ]),
                                        ),
                                        Text(
                                            _timeAgo(
                                                event.createdAt),
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: TatvaColors
                                                    .neutral400)),
                                      ]),
                                      SizedBox(height: 4),
                                      Row(children: [
                                        Container(
                                          padding: EdgeInsets
                                              .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                              color: color
                                                  .withOpacity(
                                                      0.08),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          4)),
                                          child: Text(
                                              event.type.label,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                  color: color)),
                                        ),
                                      ]),
                                      SizedBox(height: 6),
                                      Text(event.title,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: TatvaColors
                                                  .neutral900,
                                              height: 1.3)),
                                      if (event
                                          .body.isNotEmpty) ...[
                                        SizedBox(height: 4),
                                        Text(event.body,
                                            maxLines: 2,
                                            overflow: TextOverflow
                                                .ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: TatvaColors
                                                    .neutral600,
                                                height: 1.4)),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  static IconData _activityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.behaviorPoint:
        return Icons.star_rounded;
      case ActivityType.attendance:
        return Icons.check_circle_rounded;
      case ActivityType.homeworkAssigned:
      case ActivityType.homeworkSubmitted:
        return Icons.assignment_rounded;
      case ActivityType.gradeEntered:
        return Icons.grade_rounded;
      case ActivityType.announcement:
        return Icons.campaign_rounded;
      case ActivityType.storyPost:
        return Icons.photo_camera_rounded;
      case ActivityType.voteCreated:
        return Icons.how_to_vote_rounded;
      case ActivityType.studentEnrolled:
        return Icons.person_add_rounded;
    }
  }

  static Color _activityColor(ActivityType type) {
    switch (type) {
      case ActivityType.behaviorPoint:
        return TatvaColors.success;
      case ActivityType.attendance:
        return TatvaColors.info;
      case ActivityType.homeworkAssigned:
      case ActivityType.homeworkSubmitted:
        return TatvaColors.purple;
      case ActivityType.gradeEntered:
        return TatvaColors.accent;
      case ActivityType.announcement:
        return TatvaColors.primary;
      case ActivityType.storyPost:
        return Color(0xFF00897B);
      case ActivityType.voteCreated:
        return TatvaColors.purple;
      case ActivityType.studentEnrolled:
        return TatvaColors.info;
    }
  }
}
