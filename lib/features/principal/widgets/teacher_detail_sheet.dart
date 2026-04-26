import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../models/grade_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/theme/colors.dart';
import '../../messaging/messaging_screen.dart';
import 'report_stat_card.dart';

class TeacherDetailSheet {
  static void show(
    BuildContext context, {
    required UserModel teacher,
    required List<ClassModel> teacherClasses,
    required List<GradeModel> allGrades,
    required Color color,
    required void Function(ClassModel cls, Color color) onShowClassDetail,
  }) {
    final totalStudents = teacherClasses.fold<int>(
        0, (sum, c) => sum + c.studentUids.length);
    final teacherGrades =
        allGrades.where((g) => g.teacherUid == teacher.uid).toList();
    final subjects =
        teacherClasses.map((c) => c.subject).toSet().toList();

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8),
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
            SizedBox(height: 20),
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.12),
              child: Text(teacher.initial,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            SizedBox(height: 12),
            Text(teacher.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 4),
            Text(teacher.email,
                style: TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400)),
            SizedBox(height: 4),
            Text(subjects.join(', '),
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                reportStatCard('Classes', '${teacherClasses.length}',
                    Icons.class_rounded, color),
                SizedBox(width: 10),
                reportStatCard('Students', '$totalStudents',
                    Icons.people_rounded, TatvaColors.info),
                SizedBox(width: 10),
                reportStatCard('Grades', '${teacherGrades.length}',
                    Icons.grade_rounded, TatvaColors.accent),
              ]),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ...teacherClasses.map((cls) {
                    final classGrades = teacherGrades
                        .where((g) => g.classId == cls.id)
                        .toList();
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onShowClassDetail(cls, color);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgLight,
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Icon(Icons.class_rounded,
                                    color: color, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(cls.name,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: TatvaColors
                                                .neutral900))),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color:
                                          color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  child: Text(cls.subject,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight:
                                              FontWeight.w600)),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                    Icons
                                        .arrow_forward_ios_rounded,
                                    color: TatvaColors.neutral400,
                                    size: 12),
                              ]),
                              SizedBox(height: 8),
                              Text(
                                  '${cls.studentUids.length} students • ${classGrades.length} grades • Code: ${cls.classCode}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          TatvaColors.neutral400)),
                            ]),
                      ),
                    );
                  }),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessagingScreen(
                              otherUserId: teacher.uid,
                              otherUserName: teacher.name,
                              otherUserRole: 'Teacher',
                              otherUserEmail: teacher.email,
                              avatarColor: color,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: Text(
                          'Message ${teacher.name.split(' ').first}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(
                            color: color.withOpacity(0.3)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
