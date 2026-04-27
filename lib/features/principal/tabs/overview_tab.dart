import 'package:flutter/material.dart';
import '../../../models/activity_event.dart';
import '../../../models/announcement_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/screens/announcements_list_screen.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/greeting.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../../shared/widgets/greeting_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../parent/parent_helpers.dart';
import '../widgets/line_chart_painter.dart';

class OverviewTab extends StatelessWidget {
  final UserModel? user;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final Map<String, double> subjectAverages;
  final List<ActivityEvent> activityFeed;
  final List<AnnouncementModel> announcements;
  final ApiService api;
  final String uid;
  final void Function(AnnouncementModel) onToggleAnnouncementLike;
  final Animation<double> greetingFade;
  final Animation<Offset> greetingSlide;
  final Animation<double> greetingScale;
  final VoidCallback onRefresh;
  final void Function(String subject, Color color) onShowSubjectDetail;
  final VoidCallback onShowStudentPickerForReport;
  final void Function(int index) onSwitchTab;

  const OverviewTab({
    super.key,
    required this.user,
    required this.teacherCount,
    required this.studentCount,
    required this.classCount,
    required this.subjectAverages,
    required this.activityFeed,
    this.announcements = const [],
    required this.api,
    required this.uid,
    required this.onToggleAnnouncementLike,
    required this.greetingFade,
    required this.greetingSlide,
    required this.greetingScale,
    required this.onRefresh,
    required this.onShowSubjectDetail,
    required this.onShowStudentPickerForReport,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    final schoolAvg = subjectAverages.isNotEmpty
        ? subjectAverages.values.reduce((a, b) => a + b) /
            subjectAverages.length
        : 0.0;
    return RefreshIndicator(
      color: TatvaColors.purple,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: greetingFade,
              child: SlideTransition(
                position: greetingSlide,
                child: ScaleTransition(
                    scale: greetingScale, child: _buildGreetingCard()),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: FlipCard(
                        delayMs: 0,
                        child: StatCard(value: '$teacherCount', label: 'Teachers',
                            icon: Icons.people_outline, color: TatvaColors.primary))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 100,
                        child: StatCard(value: '$studentCount', label: 'Students',
                            icon: Icons.school_outlined, color: TatvaColors.info))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 200,
                        child: StatCard(value: '${schoolAvg.toStringAsFixed(1)}%',
                            label: 'Avg',
                            icon: Icons.bar_chart_rounded,
                            color: TatvaColors.success))),
              ]),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: FlipCard(
                        delayMs: 300,
                        child: GestureDetector(
                            onTap: () => onSwitchTab(1),
                            child: StatCard(value: '${activityFeed.length}',
                                label: 'Activity',
                                icon: Icons.timeline_rounded,
                                color: TatvaColors.accent)))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 400,
                        child: StatCard(value: '$classCount', label: 'Classes',
                            icon: Icons.class_outlined, color: TatvaColors.purple))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 500,
                        child: StatCard(value: '—',
                            label: 'Tasks',
                            icon: Icons.assignment_outlined,
                            color: TatvaColors.error))),
              ]),
            ),
            SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('School Grade Trend',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3)),
            ),
            SizedBox(height: 12),
            FadeSlideIn(
              delayMs: 200,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(children: [
                  buildMiniLineChart(
                      const [], 'avg', TatvaColors.primary),
                  SizedBox(height: 12),
                  Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: const <Widget>[]),
                ]),
              ),
            ),
            SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('School-Wide Subject Grades',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3)),
            ),
            SizedBox(height: 12),
            ...List.generate(subjectAverages.length, (index) {
              final entry =
                  subjectAverages.entries.elementAt(index);
              final colors = [
                TatvaColors.success,
                TatvaColors.info,
                TatvaColors.accent,
                TatvaColors.purple,
                TatvaColors.error,
                TatvaColors.primary
              ];
              final c = colors[index % colors.length];
              return StaggeredItem(
                index: index,
                child: Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: RippleTap(
                    rippleColor: c,
                    onTap: () => onShowSubjectDetail(entry.key, c),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.grey.shade100)),
                      child: Column(children: [
                        Row(children: [
                          Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: c,
                                  borderRadius:
                                      BorderRadius.circular(2))),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(entry.key,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          TatvaColors.neutral900))),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: TatvaColors.neutral400,
                              size: 12),
                          SizedBox(width: 8),
                          SlotNumber(
                              value: entry.value,
                              decimals: 1,
                              suffix: '%',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: c)),
                        ]),
                        SizedBox(height: 10),
                        AnimatedProgressBar(
                            value: entry.value / 100,
                            color: c,
                            height: 5,
                            delayMs: 300 + (index * 80)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('School Reports',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3)),
            ),
            SizedBox(height: 12),
            FadeSlideIn(
              delayMs: 300,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: BouncyTap(
                  onTap: onShowStudentPickerForReport,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TatvaColors.purple
                                .withOpacity(0.2))),
                    child: Row(children: [
                      Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: TatvaColors.purple
                                  .withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(12)),
                          child: Icon(Icons.summarize_rounded,
                              color: TatvaColors.purple, size: 22)),
                      SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                            Text('Generate Reports',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900)),
                            SizedBox(height: 2),
                            Text(
                                'Weekly student reports with CSV export',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: TatvaColors.neutral400, size: 16),
                    ]),
                  ),
                ),
              ),
            ),
            if (announcements.isNotEmpty) ...[
              SizedBox(height: 28),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: Text('Announcements',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900,
                          letterSpacing: -0.3))),
                  if (announcements.length > 3)
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AnnouncementsListScreen(
                              api: api, currentUid: uid, currentRole: 'Principal'))),
                      child: Text('See All',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                    ),
                ]),
              ),
              SizedBox(height: 12),
              ...announcements.take(3).toList().asMap().entries.map((e) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AnnouncementCard(
                      announcement: e.value,
                      currentUid: uid,
                      currentRole: 'Principal',
                      isFirst: e.key == 0,
                      onLike: () => onToggleAnnouncementLike(e.value),
                    ),
                  )),
            ],
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return GreetingCard(
      gradientColors: const [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF9C27B0)],
      heroTag: 'principal_avatar',
      userName: user?.name ?? '',
      subtitle: 'Tatva Academy · Principal',
      bottomWidget: Column(children: [
        Container(height: 1, color: Colors.white.withOpacity(0.1)),
        const SizedBox(height: 16),
        Row(children: [
          _greetingStatItem('$teacherCount', 'Teachers'),
          _greetingDivider(),
          _greetingStatItem('$studentCount', 'Students'),
          _greetingDivider(),
          _greetingStatItem('$classCount', 'Classes'),
        ]),
      ]),
    );
  }

  Widget _greetingStatItem(String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.55)),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _greetingDivider() => Container(
      width: 1, height: 28, color: Colors.white.withOpacity(0.1));

}
