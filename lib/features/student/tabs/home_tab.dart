import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/greeting.dart';
import '../../../shared/widgets/attendance_detail_sheet.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/grade_model.dart';
import '../../../models/announcement_model.dart';
import '../../../models/vote_model.dart';
import '../../../models/behavior_point.dart';
import '../../../models/behavior_category.dart';
import '../../../models/attendance_record.dart';
import '../../../models/attendance_status.dart';
import '../../../models/activity_event.dart';
import '../../parent/parent_helpers.dart';

class StudentHomeTab extends StatelessWidget {
  final UserModel? user;
  final ClassModel? primaryClass;
  final int pendingHomeworkCount;
  final List<GradeModel> grades;
  final List<AnnouncementModel> announcements;
  final List<BehaviorPoint> behaviorPoints;
  final int behaviorScore;
  final List<AttendanceRecord> attendance;
  final List<ActivityEvent> activityFeed;
  final List<VoteModel> activeVotes;
  final String motivationalText;
  final Animation<double> greetingFade;
  final Animation<Offset> greetingSlide;
  final Animation<double> greetingScale;
  final String uid;
  final VoidCallback onSwitchToHomework;
  final Future<void> Function() onRefresh;
  final void Function(AnnouncementModel) onToggleAnnouncementLike;

  const StudentHomeTab({
    super.key,
    required this.user,
    required this.primaryClass,
    required this.pendingHomeworkCount,
    required this.grades,
    required this.announcements,
    required this.behaviorPoints,
    required this.behaviorScore,
    required this.attendance,
    required this.activityFeed,
    required this.activeVotes,
    required this.motivationalText,
    required this.greetingFade,
    required this.greetingSlide,
    required this.greetingScale,
    required this.onSwitchToHomework,
    required this.onRefresh,
    required this.uid,
    required this.onToggleAnnouncementLike,
  });

  @override
  Widget build(BuildContext context) {
    final pendingHw = pendingHomeworkCount;
    return RefreshIndicator(
      color: TatvaColors.info,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeTransition(
              opacity: greetingFade,
              child: SlideTransition(
                  position: greetingSlide,
                  child: ScaleTransition(
                      scale: greetingScale, child: _buildGreetingCard()))),
          const SizedBox(height: 20),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _miniStat(
                    '$pendingHw',
                    'Pending\nHomework',
                    Icons.assignment_outlined,
                    pendingHw > 0 ? TatvaColors.accent : TatvaColors.success),
                const SizedBox(width: 10),
                _miniStat('${grades.length}', 'Grades\nReceived',
                    Icons.grade_outlined, TatvaColors.info),
                const SizedBox(width: 10),
                _miniStat('${announcements.length}', 'New\nPosts',
                    Icons.campaign_outlined, TatvaColors.purple),
              ])),
          const SizedBox(height: 24),
          if (pendingHw > 0) ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: onSwitchToHomework,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: TatvaColors.accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: TatvaColors.accent.withOpacity(0.3))),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: TatvaColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.assignment_outlined,
                              color: TatvaColors.accent, size: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                '$pendingHw homework assignment${pendingHw > 1 ? 's' : ''} due',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900)),
                            const Text('Tap to view and mark as done',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: TatvaColors.neutral400)),
                          ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: TatvaColors.accent),
                    ]),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          _buildBehaviorSection(),
          const SizedBox(height: 16),
          _buildAttendanceSection(context),
          const SizedBox(height: 24),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Announcements',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3))),
          const SizedBox(height: 12),
          _buildAnnouncements(),
          const SizedBox(height: 28),
          _buildRecentActivity(),
          const SizedBox(height: 28),
          _buildVoteResults(),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildBehaviorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TatvaColors.accent.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: TatvaColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.star_rounded, color: TatvaColors.accent, size: 18)),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Behavior Points',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: behaviorScore >= 0
                      ? TatvaColors.success.withOpacity(0.1)
                      : TatvaColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.star_rounded,
                    size: 14,
                    color: behaviorScore >= 0 ? TatvaColors.success : TatvaColors.error),
                const SizedBox(width: 4),
                Text('$behaviorScore pts',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: behaviorScore >= 0 ? TatvaColors.success : TatvaColors.error)),
              ]),
            ),
          ]),
          if (behaviorPoints.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...(behaviorPoints.length > 3
                    ? behaviorPoints.sublist(0, 3)
                    : behaviorPoints)
                .map((bp) {
              final cat = BehaviorCategory.fromId(bp.categoryId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(cat.icon, size: 14, color: TatvaColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(cat.name,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral900)),
                        if (bp.note.isNotEmpty)
                          Text(bp.note,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: TatvaColors.neutral400)),
                      ])),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: bp.isPositive
                            ? TatvaColors.success.withOpacity(0.1)
                            : TatvaColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                        '${bp.isPositive ? '+' : '-'}${bp.points}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: bp.isPositive ? TatvaColors.success : TatvaColors.error)),
                  ),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }

  Widget _buildAttendanceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => AttendanceDetailSheet.show(
          context,
          records: attendance,
          studentName: user?.name ?? 'Student',
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TatvaColors.info.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: TatvaColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_rounded,
                      color: TatvaColors.info, size: 16)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Attendance',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: TatvaColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Details',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.info)),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_ios_rounded, color: TatvaColors.info, size: 10),
                ]),
              ),
            ]),
            const SizedBox(height: 14),
            Builder(builder: (_) {
              final presentCount = attendance
                  .where((r) => r.status == AttendanceStatus.present)
                  .length;
              final absentCount = attendance
                  .where((r) => r.status == AttendanceStatus.absent)
                  .length;
              final tardyCount = attendance
                  .where((r) => r.status == AttendanceStatus.tardy)
                  .length;
              return Row(children: [
                _attendanceStat(
                    '${AttendanceStatus.present.emoji} Present',
                    '$presentCount',
                    TatvaColors.success),
                const SizedBox(width: 10),
                _attendanceStat(
                    '${AttendanceStatus.absent.emoji} Absent',
                    '$absentCount',
                    TatvaColors.error),
                const SizedBox(width: 10),
                _attendanceStat(
                    '${AttendanceStatus.tardy.emoji} Tardy',
                    '$tardyCount',
                    TatvaColors.accent),
              ]);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.5)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  color: TatvaColors.neutral400,
                  height: 1.3)),
        ]),
      ));

  Widget _attendanceStat(String label, String value, Color color) => Expanded(
          child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: TatvaColors.neutral600)),
        ]),
      ));

  Widget _buildAnnouncements() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: announcements.length,
      itemBuilder: (context, index) {
        return StaggeredItem(
          index: index,
          child: AnnouncementCard(
            announcement: announcements[index],
            currentUid: uid,
            isFirst: index == 0,
            onLike: () => onToggleAnnouncementLike(announcements[index]),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    if (activityFeed.isEmpty) return const SizedBox.shrink();
    final events = activityFeed.length > 5
        ? activityFeed.sublist(0, 5)
        : activityFeed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Recent Activity',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.3))),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100)),
          child: Column(
            children: events.asMap().entries.map((entry) {
              final idx = entry.key;
              final event = entry.value;
              final icon = _activityIcon(event.type.name);
              final timeAgo = event.createdAt != null
                  ? formatTimeAgo(event.createdAt!)
                  : '';
              return Column(children: [
                if (idx > 0)
                  Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: EdgeInsets.only(
                      top: idx == 0 ? 0 : 10,
                      bottom: idx == events.length - 1 ? 0 : 10),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: TatvaColors.info.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 16, color: TatvaColors.info)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(event.title,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral900))),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              fontSize: 10,
                              color: TatvaColors.neutral400)),
                  ]),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'behavior':
        return Icons.star;
      case 'attendance':
        return Icons.check_circle;
      case 'homework':
        return Icons.assignment;
      case 'grades':
        return Icons.grade;
      case 'announcements':
        return Icons.campaign;
      case 'story':
        return Icons.photo_camera;
      default:
        return Icons.circle;
    }
  }

  Widget _buildVoteResults() {
    if (activeVotes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Current Votes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.3))),
      const SizedBox(height: 4),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Parents are voting on these now',
              style: TextStyle(
                  fontSize: 12, color: TatvaColors.neutral400))),
      const SizedBox(height: 12),
      ...List.generate(activeVotes.length, (i) {
        final v = activeVotes[i];
        final total = v.votes.total;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TatvaColors.info.withOpacity(0.2), width: 1.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: TatvaColors.info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(v.type,
                        style: const TextStyle(
                            fontSize: 11,
                            color: TatvaColors.info,
                            fontWeight: FontWeight.w700))),
                const Spacer(),
                const Icon(Icons.how_to_vote_outlined,
                    color: TatvaColors.neutral400, size: 13),
                const SizedBox(width: 4),
                Text('$total votes',
                    style: const TextStyle(
                        fontSize: 11, color: TatvaColors.neutral400)),
              ]),
              const SizedBox(height: 10),
              Text(v.question,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      height: 1.4)),
              const SizedBox(height: 12),
              _simpleVoteBar('🏫 School', v.votes.school, total, TatvaColors.success),
              const SizedBox(height: 6),
              _simpleVoteBar(
                  '🏠 No School', v.votes.noSchool, total, TatvaColors.error),
              const SizedBox(height: 6),
              _simpleVoteBar(
                  '🤷 Undecided', v.votes.undecided, total, TatvaColors.accent),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _simpleVoteBar(String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0;
    return Row(children: [
      SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, color: TatvaColors.neutral400))),
      Expanded(
          child: AnimatedProgressBar(
              value: pct, color: color, height: 5, delayMs: 0)),
      const SizedBox(width: 8),
      Text('${(pct * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: const [
          Color(0xFF1565C0),
          Color(0xFF1E88E5),
          Color(0xFF42A5F5)
        ],
        boxShadow: [
          BoxShadow(
              color: TatvaColors.info.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: TatvaColors.info.withOpacity(0.15),
              blurRadius: 48,
              offset: const Offset(0, 20)),
        ],
        child: Stack(children: [
          Positioned(
              top: -20,
              right: 60,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
          Positioned(
              top: 10,
              right: -20,
              child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
          Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(Greeting.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(Greeting.text,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500)),
                            ]),
                            const SizedBox(height: 6),
                            TypewriterText(
                                text: user?.name ?? '',
                                delayMs: 400,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 6),
                            Text('${primaryClass?.name ?? ''} · ${primaryClass?.subject ?? ''}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'student_avatar',
                          initial: user?.initial ?? '?',
                          radius: 26,
                          bgColor: Colors.white.withOpacity(0.15),
                          textColor: Colors.white,
                          borderColor: Colors.white.withOpacity(0.3)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            color: TatvaColors.accent, size: 16),
                        const SizedBox(width: 8),
                        Text(motivationalText,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ])),
        ]),
      ),
    );
  }

}
