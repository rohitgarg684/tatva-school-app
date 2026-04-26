import 'package:flutter/material.dart';
import '../../../models/class_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class TeacherWorkloadTab extends StatelessWidget {
  final int teacherCount;
  final int classCount;
  final List<UserModel> teachers;
  final List<ClassModel> allClasses;
  final void Function(UserModel teacher, List<ClassModel> teacherClasses,
      Color color) onShowTeacherDetail;

  const TeacherWorkloadTab({
    super.key,
    required this.teacherCount,
    required this.classCount,
    required this.teachers,
    required this.allClasses,
    required this.onShowTeacherDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Teacher Workload',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text('Grading backlog and staff capacity',
                  style: TextStyle(
                      fontSize: 13,
                      color: TatvaColors.neutral400))),
          SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 100,
            child: Row(children: [
              Expanded(
                  child: _miniStatCard(
                      '$teacherCount', 'Teachers', TatvaColors.primary)),
              SizedBox(width: 10),
              Expanded(
                  child: _miniStatCard(
                      '$classCount', 'Classes', TatvaColors.info)),
              SizedBox(width: 10),
              Expanded(
                  child: _miniStatCard(
                      '—', 'Submissions', TatvaColors.accent)),
            ]),
          ),
          SizedBox(height: 24),
          FadeSlideIn(
              delayMs: 120,
              child: Text('Staff Overview',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.3))),
          SizedBox(height: 16),
          ...List.generate(teachers.length, (index) {
            final t = teachers[index];
            final colors = [
              TatvaColors.success,
              TatvaColors.info,
              TatvaColors.accent,
              TatvaColors.purple,
              TatvaColors.error,
              TatvaColors.primary
            ];
            final tColor = colors[index % colors.length];
            final teacherClasses =
                allClasses.where((c) => c.teacherUid == t.uid).toList();
            final studentCount = teacherClasses.fold<int>(
                0, (sum, c) => sum + c.studentUids.length);
            final classLen = teacherClasses.length;
            final int submitted = classLen * 5;
            final int graded = submitted;
            final int ungraded = submitted - graded;
            final double workloadPct = classLen > 0
                ? (graded / submitted).clamp(0.0, 1.0)
                : 0.0;
            Color workloadColor = TatvaColors.success;
            return StaggeredItem(
              index: index,
              child: FlipCard(
                delayMs: index * 80,
                child: GestureDetector(
                  onTap: () => onShowTeacherDetail(
                      t, teacherClasses, tColor),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 14),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade100)),
                    child: Column(children: [
                      Row(children: [
                        CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                tColor.withOpacity(0.12),
                            child: Text(t.initial,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: tColor))),
                        SizedBox(width: 14),
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(t.name,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          TatvaColors.neutral900,
                                      letterSpacing: -0.2)),
                              Text(
                                  teacherClasses.isNotEmpty
                                      ? teacherClasses
                                          .first.subject
                                      : 'N/A',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TatvaColors
                                          .neutral400)),
                            ])),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: TatvaColors.neutral400,
                            size: 14),
                      ]),
                      SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: _workloadStat(
                                '$classLen', 'Classes', tColor)),
                        Expanded(
                            child: _workloadStat(
                                '$studentCount',
                                'Students',
                                tColor)),
                        Expanded(
                            child: _workloadStat(
                                '$submitted',
                                'Submitted',
                                tColor)),
                        Expanded(
                            child: _workloadStat(
                                '$graded', 'Graded', tColor)),
                      ]),
                      SizedBox(height: 12),
                      Row(children: [
                        Text('Grading Backlog',
                            style: TextStyle(
                                fontSize: 11,
                                color: TatvaColors.neutral400)),
                        Spacer(),
                        Text(
                            '$ungraded of $submitted ungraded',
                            style: TextStyle(
                                fontSize: 11,
                                color: workloadColor,
                                fontWeight: FontWeight.bold)),
                      ]),
                      SizedBox(height: 6),
                      AnimatedProgressBar(
                          value: workloadPct,
                          color: workloadColor,
                          height: 6,
                          delayMs: 300 + index * 100),
                    ]),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniStatCard(String value, String label, Color color) {
    final numValue = double.tryParse(value);
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(children: [
        numValue != null
            ? SlotNumber(
                value: numValue,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color))
            : Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _workloadStat(String value, String label, Color color) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: TatvaColors.neutral400)),
      ]);
}
