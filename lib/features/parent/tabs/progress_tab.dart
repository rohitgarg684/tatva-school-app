import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/child_info.dart';
import '../../../models/grade_model.dart';

class ParentProgressTab extends StatelessWidget {
  final ChildDashboardData? currentChild;

  const ParentProgressTab({super.key, required this.currentChild});

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    final grades = child?.grades ?? [];
    final bySubject = <String, List<GradeModel>>{};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }
    double total = grades.fold(
        0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
    final overallAvg = grades.isEmpty ? 0.0 : total / grades.length;
    final colors = [
      TatvaColors.info,
      TatvaColors.success,
      TatvaColors.accent,
      TatvaColors.purple,
      TatvaColors.error
    ];

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: Text("${child?.info.childName ?? ''}'s Progress",
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('This Academic Term',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 20),
          FadeSlideIn(
              delayMs: 80,
              child: WaveCard(
                gradientColors: const [
                  Color(0xFF6A1B9A),
                  Color(0xFF8E24AA),
                  Color(0xFFAB47BC)
                ],
                boxShadow: [
                  BoxShadow(
                      color: TatvaColors.purple.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ],
                child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Overall Average',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7))),
                            const SizedBox(height: 4),
                            SlotNumber(
                                value: overallAvg,
                                decimals: 1,
                                suffix: '%',
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 6),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                    overallAvg >= 90
                                        ? '🏆 Excellent'
                                        : overallAvg >= 75
                                            ? '👍 Good'
                                            : '📈 Improving',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))),
                          ]),
                      const Spacer(),
                      Column(children: [
                        Text('${grades.length}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Assessments',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.6))),
                      ]),
                    ])),
              )),
          const SizedBox(height: 24),
          const Text('By Subject',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 12),
          ...bySubject.entries.toList().asMap().entries.map((entry) {
            final i = entry.key;
            final subName = entry.value.key;
            final subGrades = entry.value.value;
            final color = colors[i % colors.length];
            double subAvg = subGrades.isEmpty
                ? 0.0
                : subGrades.fold(
                        0.0,
                        (s, g) =>
                            s +
                            (g.total > 0
                                ? g.score / g.total * 100
                                : 0.0)) /
                    subGrades.length;
            final grade = subAvg >= 90
                ? 'A+'
                : subAvg >= 80
                    ? 'A'
                    : subAvg >= 70
                        ? 'B'
                        : subAvg >= 60
                            ? 'C'
                            : 'D';
            return StaggeredItem(
                index: i,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Column(children: [
                    Row(children: [
                      Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: Text(grade,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: color)))),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(subName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: TatvaColors.neutral900)),
                            Text('${subGrades.length} assessments',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: TatvaColors.neutral400)),
                          ])),
                      SlotNumber(
                          value: subAvg,
                          decimals: 1,
                          suffix: '%',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color),
                          delayMs: 200 + i * 80),
                    ]),
                    const SizedBox(height: 10),
                    AnimatedProgressBar(
                        value: subAvg / 100,
                        color: color,
                        height: 6,
                        delayMs: 300 + i * 80),
                    const SizedBox(height: 12),
                    ...subGrades.map((g) {
                      final pct = g.total > 0 ? g.score / g.total : 0.0;
                      final c = pct >= 0.9
                          ? TatvaColors.success
                          : pct >= 0.75
                              ? TatvaColors.accent
                              : TatvaColors.error;
                      return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: c, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(g.assessmentName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: TatvaColors.neutral600))),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: c.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                    '${g.score.toInt()}/${g.total.toInt()}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: c,
                                        fontWeight: FontWeight.bold))),
                          ]));
                    }),
                  ]),
                ));
          }),
        ]));
  }
}
