import 'package:flutter/material.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/utils/greeting.dart';
import '../../../shared/widgets/attendance_detail_sheet.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../../shared/widgets/greeting_card.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../../models/user_model.dart';
import '../../../models/child_info.dart';
import '../../../models/announcement_model.dart';
import '../../../models/activity_event.dart';
import '../../../services/api_service.dart';
import '../../../shared/screens/announcements_list_screen.dart';
import '../../../shared/screens/activity_list_screen.dart';
import '../../../shared/utils/activity_helpers.dart' as activity_helpers;
import '../parent_helpers.dart';

class ParentHomeTab extends StatelessWidget {
  final UserModel? user;
  final ChildDashboardData? currentChild;
  final List<ChildDashboardData> currentChildEntries;
  final List<ChildDashboardData> childrenData;
  final int selectedChildIndex;
  final List<AnnouncementModel> announcements;
  final List<ActivityEvent> activityFeed;
  final Animation<double> greetingFade;
  final Animation<Offset> greetingSlide;
  final Animation<double> greetingScale;
  final String uid;
  final VoidCallback onShowTeacherProfile;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToBehavior;
  final VoidCallback onNavigateToProgress;
  final VoidCallback onNavigateToVote;
  final Future<void> Function() onRefresh;
  final Widget childSwitcher;
  final ApiService api;
  final String? grade;
  final String? childUid;
  final void Function(AnnouncementModel) onToggleAnnouncementLike;

  const ParentHomeTab({
    super.key,
    required this.user,
    required this.currentChild,
    this.currentChildEntries = const [],
    required this.childrenData,
    required this.selectedChildIndex,
    required this.announcements,
    required this.activityFeed,
    required this.greetingFade,
    required this.greetingSlide,
    required this.greetingScale,
    required this.onShowTeacherProfile,
    required this.onNavigateToProfile,
    required this.onNavigateToBehavior,
    required this.onNavigateToProgress,
    required this.onNavigateToVote,
    required this.onRefresh,
    required this.childSwitcher,
    required this.uid,
    required this.api,
    this.grade,
    this.childUid,
    required this.onToggleAnnouncementLike,
  });

  List<ChildDashboardData> _resolveEntries() =>
      currentChildEntries.isNotEmpty
          ? currentChildEntries
          : (currentChild != null ? [currentChild!] : []);

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    final entries = _resolveEntries();
    final grades = entries.expand((e) => e.grades).toList();
    double total = grades.fold(
        0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
    final avg = grades.isEmpty ? 0.0 : total / grades.length;
    final allAttendance = entries.expand((e) => e.attendance).toList();
    final attSummary = allAttendance.isNotEmpty
        ? computeAttendanceSummary(allAttendance)
        : (present: 0, absent: 0, tardy: 0, total: 0);
    return RefreshIndicator(
        color: TatvaColors.purple,
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            GestureDetector(
                onTap: onNavigateToProfile,
                child: FadeTransition(
                    opacity: greetingFade,
                    child: SlideTransition(
                        position: greetingSlide,
                        child: ScaleTransition(
                            scale: greetingScale,
                            child: _greetingCard(avg))))),
            childSwitcher,
            const SizedBox(height: 20),
            ...entries.map((e) => GestureDetector(
                onTap: onNavigateToProgress,
                child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TatvaColors.purple.withOpacity(0.15))),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(e.info.className,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900)),
                            const SizedBox(height: 4),
                            Text('${e.info.subject} · ${e.info.teacherName}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: TatvaColors.accent.withOpacity(0.3))),
                          child: Text(e.childClass?.classCode ?? '',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.accent,
                                  letterSpacing: 2))),
                    ])))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  if (child != null) {
                    AttendanceDetailSheet.show(
                      context,
                      records: allAttendance,
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
                        Text('${entries.fold(0, (sum, e) => sum + e.behaviorScore)} points',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.neutral900)),
                      ])),
                  GestureDetector(
                    onTap: onNavigateToBehavior,
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
                  Expanded(child: QuickActionButton(label: 'Message\nTeacher', icon: Icons.chat_outlined,
                      color: TatvaColors.info, onTap: onShowTeacherProfile)),
                  const SizedBox(width: 8),
                  Expanded(child: QuickActionButton(label: 'Progress\nReport', icon: Icons.bar_chart_rounded,
                      color: TatvaColors.purple, onTap: onNavigateToProgress)),
                  const SizedBox(width: 8),
                  Expanded(child: QuickActionButton(label: 'Cast\nVote', icon: Icons.how_to_vote_outlined,
                      color: TatvaColors.accent, onTap: onNavigateToVote)),
                ])),
            const SizedBox(height: 24),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Expanded(child: Text('Announcements',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900,
                          letterSpacing: -0.3))),
                  if (announcements.length > 3)
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AnnouncementsListScreen(
                              api: api, currentUid: uid, currentRole: 'Parent', grade: grade))),
                      child: const Text('See All',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                    ),
                ])),
            const SizedBox(height: 12),
            ...announcements.take(3).toList().asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    announcement: e.value,
                    currentUid: uid,
                    currentRole: 'Parent',
                    isFirst: e.key == 0,
                    onLike: () => onToggleAnnouncementLike(e.value),
                  ),
                )),
            if (activityFeed.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    const Expanded(child: Text('Recent Activity',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900,
                            letterSpacing: -0.3))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ActivityListScreen(
                              api: api, targetUid: childUid, title: 'Activity'))),
                      child: const Text('See All',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                    ),
                  ])),
              const SizedBox(height: 12),
              ...activityFeed.take(5).toList().asMap().entries.map((entry) {
                final evt = entry.value;
                final timeAgo = evt.createdAt != null
                    ? activity_helpers.formatTimeAgo(evt.createdAt!)
                    : '';
                final evtIcon = activity_helpers.activityIcon(evt.type);
                final evtColor = activity_helpers.activityColor(evt.type);
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
    final allEntries = _resolveEntries();
    final grades = allEntries.expand((e) => e.grades).toList();
    final childName = child?.info.childName ?? '';
    return GreetingCard(
      gradientColors: const [Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC)],
      heroTag: 'parent_avatar',
      userName: childName,
      subtitle: 'Parent: ${user?.name ?? ''}',
      photoUrl: child?.childPhotoUrl ?? '',
      bottomWidget: Row(children: [
        _miniStat('${avg.toStringAsFixed(0)}%', 'Avg Grade', TatvaColors.accent),
        const SizedBox(width: 20),
        _miniStat('${grades.length}', 'Tests', Colors.white),
        const SizedBox(width: 20),
        _miniStat('${grades.map((g) => g.subject).toSet().length}', 'Subjects', Colors.white),
      ]),
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

}
