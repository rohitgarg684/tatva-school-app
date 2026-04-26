import 'package:flutter/material.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/utils/greeting.dart';
import '../../../shared/widgets/attendance_detail_sheet.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../../models/user_model.dart';
import '../../../models/child_info.dart';
import '../../../models/announcement_model.dart';
import '../../../models/activity_event.dart';
import '../parent_helpers.dart';

class ParentHomeTab extends StatelessWidget {
  final UserModel? user;
  final ChildDashboardData? currentChild;
  final List<ChildDashboardData> childrenData;
  final int selectedChildIndex;
  final List<AnnouncementModel> announcements;
  final List<ActivityEvent> activityFeed;
  final Animation<double> greetingFade;
  final Animation<Offset> greetingSlide;
  final Animation<double> greetingScale;
  final String uid;
  final VoidCallback onShowTeacherProfile;
  final ValueChanged<int> onSwitchTab;
  final Future<void> Function() onRefresh;
  final Widget childSwitcher;
  final void Function(AnnouncementModel) onToggleAnnouncementLike;

  const ParentHomeTab({
    super.key,
    required this.user,
    required this.currentChild,
    required this.childrenData,
    required this.selectedChildIndex,
    required this.announcements,
    required this.activityFeed,
    required this.greetingFade,
    required this.greetingSlide,
    required this.greetingScale,
    required this.onShowTeacherProfile,
    required this.onSwitchTab,
    required this.onRefresh,
    required this.childSwitcher,
    required this.uid,
    required this.onToggleAnnouncementLike,
  });

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    final grades = child?.grades ?? [];
    double total = grades.fold(
        0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
    final avg = grades.isEmpty ? 0.0 : total / grades.length;
    final attSummary = child != null
        ? computeAttendanceSummary(child.attendance)
        : (present: 0, absent: 0, tardy: 0, total: 0);
    return RefreshIndicator(
        color: TatvaColors.purple,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FadeTransition(
                opacity: greetingFade,
                child: SlideTransition(
                    position: greetingSlide,
                    child: ScaleTransition(
                        scale: greetingScale,
                        child: _greetingCard(avg)))),
            childSwitcher,
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TatvaColors.purple.withOpacity(0.15))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.class_outlined,
                            color: TatvaColors.purple, size: 15),
                        const SizedBox(width: 6),
                        Text("${child?.info.childName ?? ''}'s Class",
                            style: const TextStyle(
                                fontSize: 12,
                                color: TatvaColors.purple,
                                fontWeight: FontWeight.w700))
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(child?.info.className ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: TatvaColors.neutral900)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: onShowTeacherProfile,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${child?.info.subject ?? ''} · ',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: TatvaColors.neutral400)),
                                      Text(child?.info.teacherName ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: TatvaColors.info,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  TatvaColors.info)),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.open_in_new_rounded,
                                          size: 11, color: TatvaColors.info),
                                    ]),
                              ),
                            ])),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: TatvaColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        TatvaColors.accent.withOpacity(0.3))),
                            child: Text(child?.childClass?.classCode ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.accent,
                                    letterSpacing: 2))),
                      ]),
                    ])),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  if (child != null) {
                    AttendanceDetailSheet.show(
                      context,
                      records: child.attendance,
                      studentName: child.info.childName,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.calendar_today_rounded,
                              color: TatvaColors.info, size: 15),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text('Attendance',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.info,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: TatvaColors.info.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Details',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: TatvaColors.info)),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      color: TatvaColors.info, size: 10),
                                ]),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _attChip('${attSummary.present}', 'Present',
                              TatvaColors.success),
                          const SizedBox(width: 10),
                          _attChip('${attSummary.absent}', 'Absent',
                              TatvaColors.error),
                          const SizedBox(width: 10),
                          _attChip('${attSummary.tardy}', 'Tardy',
                              TatvaColors.accent),
                          const Spacer(),
                          if (attSummary.total > 0)
                            Text(
                                '${(attSummary.present / attSummary.total * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.success)),
                        ]),
                      ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: TatvaColors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.star_rounded,
                          color: TatvaColors.purple, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Behavior Score',
                            style: TextStyle(
                                fontSize: 12, color: TatvaColors.neutral400)),
                        const SizedBox(height: 2),
                        Text('${child?.behaviorScore ?? 0} points',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.neutral900)),
                      ])),
                  GestureDetector(
                    onTap: () => onSwitchTab(2),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: TatvaColors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Details',
                            style: TextStyle(
                                fontSize: 12,
                                color: TatvaColors.purple,
                                fontWeight: FontWeight.w600))),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _qaBtn('Message\nTeacher', Icons.chat_outlined,
                      TatvaColors.info, onShowTeacherProfile),
                  const SizedBox(width: 8),
                  _qaBtn('Progress\nReport', Icons.bar_chart_rounded,
                      TatvaColors.purple, () => onSwitchTab(1)),
                  const SizedBox(width: 8),
                  _qaBtn('Cast\nVote', Icons.how_to_vote_outlined,
                      TatvaColors.accent, () => onSwitchTab(5)),
                ])),
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
            ...announcements.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    announcement: e.value,
                    currentUid: uid,
                    isFirst: e.key == 0,
                    onLike: () => onToggleAnnouncementLike(e.value),
                  ),
                )),
            if (activityFeed.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text('Recent Activity',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900,
                          letterSpacing: -0.3))),
              const SizedBox(height: 12),
              ...activityFeed.take(5).toList().asMap().entries.map((entry) {
                final evt = entry.value;
                final timeAgo = evt.createdAt != null
                    ? formatTimeAgo(evt.createdAt!)
                    : '';
                IconData evtIcon;
                Color evtColor;
                switch (evt.type) {
                  case ActivityType.behaviorPoint:
                    evtIcon = Icons.star_rounded;
                    evtColor = TatvaColors.purple;
                    break;
                  case ActivityType.attendance:
                    evtIcon = Icons.calendar_today_rounded;
                    evtColor = TatvaColors.info;
                    break;
                  case ActivityType.homeworkAssigned:
                    evtIcon = Icons.assignment_outlined;
                    evtColor = TatvaColors.accent;
                    break;
                  case ActivityType.homeworkSubmitted:
                    evtIcon = Icons.assignment_turned_in_outlined;
                    evtColor = TatvaColors.success;
                    break;
                  case ActivityType.gradeEntered:
                    evtIcon = Icons.grading_rounded;
                    evtColor = TatvaColors.info;
                    break;
                  case ActivityType.announcement:
                    evtIcon = Icons.campaign_outlined;
                    evtColor = TatvaColors.error;
                    break;
                  case ActivityType.storyPost:
                    evtIcon = Icons.auto_stories_outlined;
                    evtColor = TatvaColors.purple;
                    break;
                  case ActivityType.voteCreated:
                    evtIcon = Icons.how_to_vote_outlined;
                    evtColor = TatvaColors.accent;
                    break;
                  case ActivityType.studentEnrolled:
                    evtIcon = Icons.person_add_outlined;
                    evtColor = TatvaColors.success;
                    break;
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: evtColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(evtIcon, color: evtColor, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(evt.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.neutral900)),
                          if (evt.body.isNotEmpty)
                            Text(evt.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TatvaColors.neutral600)),
                        ])),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              fontSize: 10, color: TatvaColors.neutral400)),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 24),
          ]),
        ));
  }

  Widget _attChip(String val, String label, Color color) =>
      Column(children: [
        Text(val,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: TatvaColors.neutral400)),
      ]);

  Widget _greetingCard(double avg) {
    final child = currentChild;
    final grades = child?.grades ?? [];
    final childNames = childrenData.map((c) => c.info.childName).toList();
    final parentOfLabel = childNames.length <= 1
        ? 'Parent of ${childNames.isNotEmpty ? childNames.first : ''}'
        : 'Parent of ${childNames.join(' & ')}';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: const [
          Color(0xFF6A1B9A),
          Color(0xFF8E24AA),
          Color(0xFFAB47BC)
        ],
        boxShadow: [
          BoxShadow(
              color: TatvaColors.purple.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10))
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
                                      color: Colors.white.withOpacity(0.7)))
                            ]),
                            const SizedBox(height: 6),
                            TypewriterText(
                                text: user?.name ?? '',
                                delayMs: 400,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 4),
                            Text(parentOfLabel,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'parent_avatar',
                          initial: user?.initial ?? '?',
                          radius: 26,
                          bgColor: Colors.white.withOpacity(0.15),
                          textColor: Colors.white,
                          borderColor: Colors.white.withOpacity(0.3)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _miniStat('${avg.toStringAsFixed(0)}%', 'Avg Grade',
                          TatvaColors.accent),
                      const SizedBox(width: 20),
                      _miniStat('${grades.length}', 'Tests', Colors.white),
                      const SizedBox(width: 20),
                      _miniStat(
                          '${grades.map((g) => g.subject).toSet().length}',
                          'Subjects',
                          Colors.white),
                    ]),
                  ])),
        ]),
      ),
    );
  }

  Widget _miniStat(String val, String label, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: Colors.white.withOpacity(0.5))),
      ]);

  Widget _qaBtn(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Column(children: [
                    Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: color, size: 18)),
                    const SizedBox(height: 7),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10,
                            color: TatvaColors.neutral600,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                  ]))));
}
