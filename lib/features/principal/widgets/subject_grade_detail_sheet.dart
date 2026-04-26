import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/grade_model.dart';
import '../../../shared/theme/colors.dart';

class SubjectGradeDetailSheet {
  static void show(
    BuildContext context, {
    required String subject,
    required List<GradeModel> allGrades,
    required Color color,
  }) {
    final subjectGrades = allGrades.where((g) => g.subject == subject).toList()
      ..sort((a, b) => b.percentage.compareTo(a.percentage));

    final avg = subjectGrades.isEmpty
        ? 0.0
        : subjectGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
            subjectGrades.length;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 16),
            Text(subject,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 4),
            Text(
                '${subjectGrades.length} grades • ${avg.toStringAsFixed(1)}% average',
                style:
                    TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
            SizedBox(height: 16),
            Expanded(
              child: subjectGrades.isEmpty
                  ? Center(
                      child: Text('No grades recorded for $subject',
                          style:
                              TextStyle(color: TatvaColors.neutral400)))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: subjectGrades.length,
                      itemBuilder: (_, i) {
                        final g = subjectGrades[i];
                        final pct = g.percentage;
                        final pctColor = pct >= 80
                            ? TatvaColors.success
                            : pct >= 60
                                ? TatvaColors.accent
                                : TatvaColors.error;
                        return Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: color.withOpacity(0.1),
                              child: Text(
                                  g.studentName.isNotEmpty
                                      ? g.studentName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        g.studentName.isNotEmpty
                                            ? g.studentName
                                            : g.studentUid,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: TatvaColors.neutral900)),
                                    SizedBox(height: 2),
                                    Text(g.assessmentName,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: TatvaColors.neutral400)),
                                  ]),
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                      '${g.score.toInt()}/${g.total.toInt()}',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: pctColor)),
                                  Text('${pct.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: TatvaColors.neutral400)),
                                ]),
                          ]),
                        );
                      },
                    ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
