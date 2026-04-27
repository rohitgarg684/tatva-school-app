import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../models/grade_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'report_stat_card.dart';

class ClassDetailSheet {
  static void show(
    BuildContext context, {
    required ClassModel cls,
    required Color color,
    required List<UserModel> studentUsers,
    required List<GradeModel> allGrades,
    required List<UserModel> parents,
    required void Function(UserModel student, Color color)
        onShowStudentDetail,
  }) {
    final classStudents = studentUsers
        .where((u) => cls.studentUids.contains(u.uid))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final classGrades =
        allGrades.where((g) => g.classId == cls.id).toList();
    final classParents =
        parents.where((p) => cls.parentUids.contains(p.uid)).toList();

    final gradeAvg = classGrades.isEmpty
        ? 0.0
        : classGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
            classGrades.length;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82),
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
            Text(cls.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 4),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(cls.subject,
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: 8),
                  Text('Code: ${cls.classCode}',
                      style: TextStyle(
                          fontSize: 12,
                          color: TatvaColors.neutral400)),
                ]),
            SizedBox(height: 4),
            Text('Teacher: ${cls.teacherName}',
                style: TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400)),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                reportStatCard('Students', '${classStudents.length}',
                    Icons.people_rounded, color),
                SizedBox(width: 10),
                reportStatCard('Parents', '${classParents.length}',
                    Icons.family_restroom_rounded, TatvaColors.info),
                SizedBox(width: 10),
                reportStatCard(
                    'Avg',
                    '${gradeAvg.toStringAsFixed(1)}%',
                    Icons.grade_rounded,
                    gradeAvg >= 80
                        ? TatvaColors.success
                        : gradeAvg >= 60
                            ? TatvaColors.accent
                            : TatvaColors.error),
              ]),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Students',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: classStudents.isEmpty
                  ? Center(
                      child: Text('No students enrolled',
                          style:
                              TextStyle(color: TatvaColors.neutral400)))
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: classStudents.length,
                      itemBuilder: (ctx, i) {
                        final s = classStudents[i];
                        final studentGrades = classGrades
                            .where((g) => g.studentUid == s.uid)
                            .toList();
                        final sAvg = studentGrades.isEmpty
                            ? null
                            : studentGrades
                                    .map((g) => g.percentage)
                                    .reduce((a, b) => a + b) /
                                studentGrades.length;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            onShowStudentDetail(s, color);
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: TatvaColors.bgLight,
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: Row(children: [
                              UserAvatar(
                                name: s.name,
                                radius: 18,
                                bgColor: color.withOpacity(0.1),
                                textColor: color,
                                photoUrl: s.photoUrl,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: TatvaColors
                                                  .neutral900)),
                                      Text(s.email,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: TatvaColors
                                                  .neutral400)),
                                    ]),
                              ),
                              if (sAvg != null) ...[
                                Text('${sAvg.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: sAvg >= 80
                                            ? TatvaColors.success
                                            : sAvg >= 60
                                                ? TatvaColors.accent
                                                : TatvaColors.error)),
                                SizedBox(width: 6),
                              ],
                              Icon(Icons.arrow_forward_ios_rounded,
                                  color: TatvaColors.neutral400,
                                  size: 12),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
