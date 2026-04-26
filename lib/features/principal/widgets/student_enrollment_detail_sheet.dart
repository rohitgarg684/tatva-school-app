import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../models/grade_model.dart';
import '../../../models/student_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import 'report_stat_card.dart';

class StudentEnrollmentDetailSheet {
  static void show(
    BuildContext context, {
    required StudentModel student,
    required List<ClassModel> allClasses,
    required List<GradeModel> allGrades,
    required Color color,
    required void Function(ClassModel cls, Color color) onShowClassDetail,
    required void Function(StudentModel student) onGenerateReport,
  }) {
    final studentClasses =
        allClasses.where((c) => student.classIds.contains(c.id)).toList();
    final studentGrades =
        allGrades.where((g) => g.studentUid == student.id).toList();

    final bySubject = <String, List<GradeModel>>{};
    for (final g in studentGrades) {
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    }

    final overallAvg = studentGrades.isEmpty
        ? 0.0
        : studentGrades.map((g) => g.percentage).reduce((a, b) => a + b) /
            studentGrades.length;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85),
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
            CircleAvatar(
              radius: 32,
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                  student.name.isNotEmpty
                      ? student.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            SizedBox(height: 10),
            Text(student.name,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            SizedBox(height: 4),
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (student.rollNumber.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(student.rollNumber,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (student.displayGradeSection.isNotEmpty)
                    Text(student.displayGradeSection,
                        style: TextStyle(
                            fontSize: 13,
                            color: TatvaColors.neutral400)),
                ]),
            if (student.parentName.isNotEmpty) ...[
              SizedBox(height: 4),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.family_restroom_rounded,
                        size: 14, color: TatvaColors.neutral400),
                    SizedBox(width: 4),
                    Text('Parent: ${student.parentName}',
                        style: TextStyle(
                            fontSize: 13,
                            color: TatvaColors.neutral400)),
                    if (student.parentPhone.isNotEmpty)
                      Text(' • ${student.parentPhone}',
                          style: TextStyle(
                              fontSize: 13,
                              color: TatvaColors.neutral400)),
                  ]),
            ],
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                reportStatCard('Classes', '${studentClasses.length}',
                    Icons.class_rounded, color),
                SizedBox(width: 10),
                reportStatCard('Grades', '${studentGrades.length}',
                    Icons.grade_rounded, TatvaColors.info),
                SizedBox(width: 10),
                reportStatCard(
                    'Avg',
                    studentGrades.isEmpty
                        ? 'N/A'
                        : '${overallAvg.toStringAsFixed(1)}%',
                    Icons.trending_up_rounded,
                    overallAvg >= 80
                        ? TatvaColors.success
                        : overallAvg >= 60
                            ? TatvaColors.accent
                            : TatvaColors.error),
              ]),
            ),
            SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(children: [
                  TabBar(
                    labelColor: color,
                    unselectedLabelColor: TatvaColors.neutral400,
                    indicatorColor: color,
                    labelStyle: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: 'Classes'),
                      Tab(text: 'Grades'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(children: [
                      studentClasses.isEmpty
                          ? Center(
                              child: Text(
                                  'Not enrolled in any classes',
                                  style: TextStyle(
                                      color:
                                          TatvaColors.neutral400)))
                          : ListView.builder(
                              padding: EdgeInsets.all(20),
                              itemCount: studentClasses.length,
                              itemBuilder: (ctx, i) {
                                final cls = studentClasses[i];
                                final classGrades = studentGrades
                                    .where(
                                        (g) => g.classId == cls.id)
                                    .toList();
                                final cAvg = classGrades.isEmpty
                                    ? null
                                    : classGrades
                                            .map((g) => g.percentage)
                                            .reduce(
                                                (a, b) => a + b) /
                                        classGrades.length;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onShowClassDetail(cls, color);
                                  },
                                  child: Container(
                                    margin:
                                        EdgeInsets.only(bottom: 10),
                                    padding: EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                        color: TatvaColors.bgLight,
                                        borderRadius:
                                            BorderRadius.circular(
                                                14)),
                                    child: Row(children: [
                                      Icon(Icons.class_rounded,
                                          color: color, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(cls.name,
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                      color: TatvaColors
                                                          .neutral900)),
                                              SizedBox(height: 2),
                                              Text(
                                                  '${cls.subject} • ${cls.teacherName} • ${classGrades.length} grades',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: TatvaColors
                                                          .neutral400)),
                                            ]),
                                      ),
                                      if (cAvg != null)
                                        Text(
                                            '${cAvg.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.bold,
                                                color: cAvg >= 80
                                                    ? TatvaColors
                                                        .success
                                                    : cAvg >= 60
                                                        ? TatvaColors
                                                            .accent
                                                        : TatvaColors
                                                            .error)),
                                      SizedBox(width: 6),
                                      Icon(
                                          Icons
                                              .arrow_forward_ios_rounded,
                                          color:
                                              TatvaColors.neutral400,
                                          size: 12),
                                    ]),
                                  ),
                                );
                              },
                            ),
                      bySubject.isEmpty
                          ? Center(
                              child: Text('No grades recorded yet',
                                  style: TextStyle(
                                      color:
                                          TatvaColors.neutral400)))
                          : ListView(
                              padding: EdgeInsets.all(20),
                              children:
                                  bySubject.entries.map((entry) {
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
                                  margin:
                                      EdgeInsets.only(bottom: 12),
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: TatvaColors.bgLight,
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Expanded(
                                              child: Text(entry.key,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'Raleway',
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight
                                                              .bold,
                                                      color: TatvaColors
                                                          .neutral900))),
                                          Text(
                                              '${subjectAvg.toStringAsFixed(0)}%',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold,
                                                  color: avgColor)),
                                        ]),
                                        SizedBox(height: 4),
                                        AnimatedProgressBar(
                                            value:
                                                subjectAvg / 100,
                                            color: avgColor,
                                            height: 4,
                                            delayMs: 200),
                                        SizedBox(height: 8),
                                        ...entry.value.map(
                                            (g) => Padding(
                                                  padding:
                                                      EdgeInsets.only(
                                                          bottom: 4),
                                                  child: Row(
                                                      children: [
                                                    Expanded(
                                                        child: Text(
                                                            g.assessmentName,
                                                            style: TextStyle(
                                                                fontFamily: 'Raleway',
                                                                fontSize: 12,
                                                                color: TatvaColors.neutral400))),
                                                    Text(
                                                        '${g.score.toInt()}/${g.total.toInt()}',
                                                        style: TextStyle(
                                                            fontFamily: 'Raleway',
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: TatvaColors.neutral900)),
                                                  ]),
                                                )),
                                      ]),
                                );
                              }).toList(),
                            ),
                    ]),
                  ),
                ]),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onGenerateReport(student);
                  },
                  icon: Icon(Icons.summarize_rounded, size: 16),
                  label: Text('Generate Weekly Report',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
