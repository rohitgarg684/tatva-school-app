import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/student_model.dart';
import '../../../shared/theme/colors.dart';
import 'report_stat_card.dart';

class ReportSheet {
  static void show(
    BuildContext context, {
    required StudentModel student,
    required Map<String, dynamic> report,
  }) {
    final grades = (report['grades'] as List?) ?? [];
    final behavior = (report['behaviorPoints'] as List?) ?? [];
    final attendance = (report['attendance'] as List?) ?? [];

    final present =
        attendance.where((a) => a['status'] == 'Present').length;
    final total = attendance.length;
    final attendancePct = total > 0 ? (present / total * 100).round() : 0;

    final totalPoints = behavior.fold<int>(
        0, (sum, b) => sum + ((b['points'] as num?)?.toInt() ?? 0));

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
            Text('Weekly Report',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 4),
            Text(student.name,
                style: TextStyle(
                    fontSize: 14,
                    color: TatvaColors.primary,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      reportStatCard('Attendance', '$attendancePct%',
                          Icons.calendar_today_rounded, TatvaColors.primary),
                      SizedBox(width: 12),
                      reportStatCard(
                          'Behavior',
                          '$totalPoints pts',
                          Icons.emoji_events_rounded,
                          Colors.amber.shade700),
                      SizedBox(width: 12),
                      reportStatCard('Grades', '${grades.length}',
                          Icons.grade_rounded, TatvaColors.purple),
                    ]),
                    SizedBox(height: 20),
                    if (grades.isNotEmpty) ...[
                      Text('Grades',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      SizedBox(height: 8),
                      ...grades.map((g) => Padding(
                            padding: EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(
                                  '${g['subject'] ?? ''} — ${g['assessmentName'] ?? ''}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: TatvaColors.neutral900),
                                )),
                                Text(
                                  '${g['score'] ?? 0}/${g['total'] ?? 100}',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: TatvaColors.primary),
                                ),
                              ],
                            ),
                          )),
                      SizedBox(height: 16),
                    ],
                    if (attendance.isNotEmpty) ...[
                      Text('Attendance ($present/$total days present)',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: attendance.map((a) {
                          final status = a['status'] ?? 'Absent';
                          final aColor = status == 'Present'
                              ? TatvaColors.success
                              : status == 'Tardy'
                                  ? Colors.amber
                                  : TatvaColors.error;
                          return Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: aColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              '${a['date'] ?? ''}: $status',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: aColor,
                                  fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (behavior.isNotEmpty) ...[
                      Text('Behavior Points',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      SizedBox(height: 8),
                      ...behavior.map((b) => Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.amber, size: 16),
                              SizedBox(width: 6),
                              Expanded(
                                  child: Text(
                                '${b['categoryId'] ?? 'Point'}: +${b['points'] ?? 1}',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: TatvaColors.neutral900),
                              )),
                            ]),
                          )),
                      SizedBox(height: 16),
                    ],
                    if (grades.isEmpty &&
                        attendance.isEmpty &&
                        behavior.isEmpty)
                      Center(
                          child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No data for this week.',
                            style: TextStyle(
                                color: TatvaColors.neutral400,
                                fontSize: 14)),
                      )),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final csv = _buildCsvReport(
                              student, grades, attendance, behavior);
                          Clipboard.setData(ClipboardData(text: csv));
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                            content: Text('Report CSV copied to clipboard',
                                style: TextStyle()),
                            backgroundColor: TatvaColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ));
                        },
                        icon: Icon(Icons.copy_rounded, size: 18),
                        label: Text('Copy CSV to Clipboard',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TatvaColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _buildCsvReport(StudentModel student, List grades,
      List attendance, List behavior) {
    final buf = StringBuffer();
    buf.writeln('Weekly Report: ${student.name}');
    buf.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buf.writeln('');
    buf.writeln('GRADES');
    buf.writeln('Subject,Assessment,Score,Total');
    for (final g in grades) {
      buf.writeln(
          '${g['subject']},${g['assessmentName']},${g['score']},${g['total']}');
    }
    buf.writeln('');
    buf.writeln('ATTENDANCE');
    buf.writeln('Date,Status');
    for (final a in attendance) {
      buf.writeln('${a['date']},${a['status']}');
    }
    buf.writeln('');
    buf.writeln('BEHAVIOR POINTS');
    buf.writeln('Category,Points,Note');
    for (final b in behavior) {
      buf.writeln(
          '${b['categoryId']},${b['points']},${b['note'] ?? ''}');
    }
    return buf.toString();
  }
}
