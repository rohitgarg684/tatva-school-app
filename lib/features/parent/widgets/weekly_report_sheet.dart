import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/theme/colors.dart';
import '../../../models/weekly_report.dart';
import '../parent_helpers.dart';

class WeeklyReportSheet {
  static void show(BuildContext context, WeeklyReport report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('📊 Weekly Report',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            const SizedBox(height: 4),
            Text('${report.studentName} · ${report.weekLabel}',
                style: const TextStyle(
                    fontSize: 12, color: TatvaColors.neutral400)),
            const SizedBox(height: 20),
            _row('📚 Grade Average',
                '${report.gradeAverage.toStringAsFixed(1)}%'),
            _row('✅ Attendance Rate',
                '${report.attendanceRate.toStringAsFixed(0)}%'),
            _row('📅 Present / Absent / Tardy',
                '${report.daysPresent} / ${report.daysAbsent} / ${report.daysTardy}'),
            _row('⭐ Behavior Points', '${report.behaviorPointsTotal}'),
            _row('👍 Positive', '${report.positivePoints}'),
            _row('👎 Needs Work', '${report.negativePoints}'),
            _row('📝 Homework',
                '${report.homeworkCompleted}/${report.homeworkTotal}'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final csv = exportReportToCsv(report);
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Report copied to clipboard',
                      style: TextStyle()),
                  backgroundColor: TatvaColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    color: TatvaColors.info,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: TatvaColors.info.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      const Text('Export CSV to Clipboard',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static Widget _row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral600))),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: TatvaColors.neutral900)),
      ]));
}
