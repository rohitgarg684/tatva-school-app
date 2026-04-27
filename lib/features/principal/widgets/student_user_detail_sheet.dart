import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/grade_model.dart';
import '../../../models/student_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../messaging/messaging_screen.dart';

class StudentUserDetailSheet {
  static void show(
    BuildContext context, {
    required UserModel student,
    required List<GradeModel> allGrades,
    required Color color,
    required void Function(StudentModel student) onGenerateReport,
  }) {
    final studentGrades =
        allGrades.where((g) => g.studentUid == student.uid).toList();
    final bySubject = <String, List<GradeModel>>{};
    for (final g in studentGrades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

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
            UserAvatar(
              name: student.name,
              radius: 28,
              bgColor: color.withOpacity(0.12),
              textColor: color,
              photoUrl: student.photoUrl,
            ),
            SizedBox(height: 10),
            Text(student.name,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 2),
            Text(student.email,
                style: TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400)),
            SizedBox(height: 16),
            Expanded(
              child: studentGrades.isEmpty
                  ? Center(
                      child: Text('No grades recorded yet',
                          style:
                              TextStyle(color: TatvaColors.neutral400)))
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      children: bySubject.entries.map((entry) {
                        final subjectAvg = entry.value
                                .map((g) => g.percentage)
                                .reduce((a, b) => a + b) /
                            entry.value.length;
                        final avgColor = subjectAvg >= 80
                            ? TatvaColors.success
                            : subjectAvg >= 60
                                ? TatvaColors.accent
                                : TatvaColors.error;
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(14)),
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(entry.key,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: TatvaColors.neutral900))),
                                  Text(
                                      '${subjectAvg.toStringAsFixed(0)}%',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: avgColor)),
                                ]),
                                SizedBox(height: 4),
                                AnimatedProgressBar(
                                    value: subjectAvg / 100,
                                    color: avgColor,
                                    height: 4,
                                    delayMs: 200),
                                SizedBox(height: 8),
                                ...entry.value.map((g) => Padding(
                                      padding:
                                          EdgeInsets.only(bottom: 4),
                                      child: Row(children: [
                                        Expanded(
                                            child: Text(
                                                g.assessmentName,
                                                style: TextStyle(
                                                    fontFamily:
                                                        'Raleway',
                                                    fontSize: 12,
                                                    color: TatvaColors
                                                        .neutral400))),
                                        Text(
                                            '${g.score.toInt()}/${g.total.toInt()}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: TatvaColors
                                                    .neutral900)),
                                      ]),
                                    )),
                              ]),
                        );
                      }).toList(),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MessagingScreen(
                            otherUserId: student.uid,
                            otherUserName: student.name,
                            otherUserRole: 'Student',
                            otherUserEmail: student.email,
                            otherPhotoUrl: student.photoUrl,
                            avatarColor: color,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.chat_bubble_outline_rounded,
                        size: 16),
                    label: Text('Message',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side:
                          BorderSide(color: color.withOpacity(0.3)),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onGenerateReport(StudentModel(
                        id: student.uid,
                        name: student.name,
                        rollNumber: '',
                        grade: '',
                        section: '',
                        parentName: '',
                        parentPhone: '',
                      ));
                    },
                    icon: Icon(Icons.summarize_rounded, size: 16),
                    label: Text('Report',
                        style:
                            TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
