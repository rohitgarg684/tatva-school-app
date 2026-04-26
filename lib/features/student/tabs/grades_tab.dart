import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../models/grade_model.dart';

class StudentGradesTab extends StatelessWidget {
  final List<GradeModel> grades;

  const StudentGradesTab({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<GradeModel>> bySubject = {};
    for (final g in grades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }
    double totalPct = 0;
    for (final g in grades) totalPct += g.percentage;
    final overallAvg = grades.isEmpty ? 0.0 : totalPct / grades.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('My Grades',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        FadeSlideIn(
            delayMs: 80,
            child: const Text('Your academic performance this term',
                style: TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        FadeSlideIn(
            child: WaveCard(
          gradientColors: const [
            Color(0xFF1565C0),
            Color(0xFF1E88E5),
            Color(0xFF42A5F5)
          ],
          boxShadow: [
            BoxShadow(
                color: TatvaColors.info.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      overallAvg >= 90
                          ? '🏆 Excellent'
                          : overallAvg >= 75
                              ? '👍 Good'
                              : overallAvg >= 60
                                  ? '📈 Improving'
                                  : '💪 Needs Work',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
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
            ]),
          ),
        )),
        const SizedBox(height: 24),
        const Text('By Subject',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: TatvaColors.neutral900)),
        const SizedBox(height: 12),
        ...bySubject.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final subjectName = entry.value.key;
          final subjectGrades = entry.value.value;
          final colors = [TatvaColors.info, TatvaColors.success, TatvaColors.accent, TatvaColors.purple, TatvaColors.error];
          final color = colors[index % colors.length];
          double subAvg = subjectGrades
                  .map((g) => g.percentage)
                  .reduce((a, b) => a + b) /
              subjectGrades.length;
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
            index: index,
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
                        Text(subjectName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral900)),
                        Text(
                            '${subjectGrades.length} assessment${subjectGrades.length > 1 ? 's' : ''}',
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
                      delayMs: 200 + index * 80),
                ]),
                const SizedBox(height: 10),
                AnimatedProgressBar(
                    value: subAvg / 100,
                    color: color,
                    height: 6,
                    delayMs: 300 + index * 80),
                const SizedBox(height: 12),
                ...subjectGrades.map((g) {
                  final score = g.score;
                  final total = g.total;
                  final pct = total > 0 ? score / total : 0.0;
                  final gc = pct >= 0.9
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
                          decoration:
                              BoxDecoration(color: gc, shape: BoxShape.circle)),
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
                            color: gc.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${score.toInt()}/${total.toInt()}',
                            style: TextStyle(
                                fontSize: 11,
                                color: gc,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
          );
        }),
        const SizedBox(height: 24),
      ]),
    );
  }
}
