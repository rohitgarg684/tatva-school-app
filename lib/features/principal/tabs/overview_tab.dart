import 'package:flutter/material.dart';
import '../../../models/activity_event.dart';
import '../../../models/user_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/utils/greeting.dart';
import '../widgets/line_chart_painter.dart';

class OverviewTab extends StatelessWidget {
  final UserModel? user;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final Map<String, double> subjectAverages;
  final List<ActivityEvent> activityFeed;
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
                        child: _statCard('$teacherCount', 'Teachers',
                            Icons.people_outline, TatvaColors.primary))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 100,
                        child: _statCard('$studentCount', 'Students',
                            Icons.school_outlined, TatvaColors.info))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 200,
                        child: _statCard(
                            '${schoolAvg.toStringAsFixed(1)}%',
                            'Avg',
                            Icons.bar_chart_rounded,
                            TatvaColors.success))),
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
                            child: _statCard(
                                '${activityFeed.length}',
                                'Activity',
                                Icons.timeline_rounded,
                                TatvaColors.accent)))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 400,
                        child: _statCard('$classCount', 'Classes',
                            Icons.class_outlined, TatvaColors.purple))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 500,
                        child: _statCard(
                            '—',
                            'Tasks',
                            Icons.assignment_outlined,
                            TatvaColors.error))),
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
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: [
          Color(0xFF4A148C),
          Color(0xFF7B1FA2),
          Color(0xFF9C27B0)
        ],
        boxShadow: [
          BoxShadow(
              color: TatvaColors.purple.withOpacity(0.35),
              blurRadius: 24,
              offset: Offset(0, 10)),
          BoxShadow(
              color: TatvaColors.purple.withOpacity(0.15),
              blurRadius: 48,
              offset: Offset(0, 20)),
        ],
        child: Stack(
          children: [
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
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(Greeting.emoji,
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text(Greeting.text,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white
                                          .withOpacity(0.7),
                                      fontWeight: FontWeight.w500)),
                            ]),
                            SizedBox(height: 6),
                            TypewriterText(
                                text: user?.name ?? '',
                                delayMs: 400,
                                style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            SizedBox(height: 6),
                            Text('Tatva Academy · Principal',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white
                                        .withOpacity(0.6))),
                          ]),
                    ),
                    HeroAvatar(
                        heroTag: 'principal_avatar',
                        initial: user?.initial ?? 'P',
                        radius: 26,
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.white,
                        borderColor:
                            Colors.white.withOpacity(0.3)),
                  ]),
                  SizedBox(height: 20),
                  Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.1)),
                  SizedBox(height: 16),
                  Row(children: [
                    _greetingStatItem('$teacherCount', 'Teachers'),
                    _greetingDivider(),
                    _greetingStatItem('$studentCount', 'Students'),
                    _greetingDivider(),
                    _greetingStatItem('$classCount', 'Classes'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _statCard(
          String value, String label, IconData icon, Color color) =>
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16)),
              SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.5)),
              SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: TatvaColors.neutral400,
                      fontWeight: FontWeight.w500)),
            ]),
      );
}
