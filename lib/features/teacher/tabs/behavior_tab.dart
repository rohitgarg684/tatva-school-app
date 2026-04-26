import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/behavior_point.dart';
import '../../../models/behavior_category.dart';
import '../../parent/parent_helpers.dart';

class TeacherBehaviorTab extends StatelessWidget {
  final List<BehaviorPoint> classBehavior;
  final List<UserModel> students;
  final List<ClassModel> classes;
  final String uid;
  final UserModel? user;
  final void Function(BehaviorPoint) onBehaviorAdded;
  final void Function(String) onBehaviorDeleted;

  const TeacherBehaviorTab({
    super.key,
    required this.classBehavior,
    required this.students,
    required this.classes,
    required this.uid,
    required this.user,
    required this.onBehaviorAdded,
    required this.onBehaviorDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final classId = classes.isNotEmpty ? classes.first.id : '';
    final studentScores = <String, int>{};
    for (final bp in classBehavior) {
      studentScores.update(bp.studentUid, (v) => v + bp.points,
          ifAbsent: () => bp.points);
    }
    final recentPoints = List<BehaviorPoint>.from(classBehavior)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Behavior Points',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text(
                classes.isNotEmpty
                    ? '${classes.first.name} · Tap a student to award points'
                    : 'No classes available',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85),
          itemCount: students.length,
          itemBuilder: (_, i) {
            final s = students[i];
            final score = studentScores[s.uid] ?? 0;
            final scoreColor = score > 0
                ? TatvaColors.success
                : score < 0
                    ? TatvaColors.error
                    : TatvaColors.neutral400;
            return GestureDetector(
              onTap: () =>
                  _showBehaviorSheet(context, s.uid, s.name, classId),
              child: Container(
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              TatvaColors.primary.withOpacity(0.1),
                          child: Text(s.initial,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.primary))),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(s.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral900)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              '${score >= 0 ? '+' : ''}$score pts',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor))),
                    ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (recentPoints.isNotEmpty) ...[
          const Text('Recent Activity',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 12),
          ...recentPoints.take(20).map((bp) {
            final cat = BehaviorCategory.fromId(bp.categoryId);
            final c = bp.isPositive ? TatvaColors.success : TatvaColors.error;
            final timeAgo = bp.createdAt != null
                ? formatTimeAgo(bp.createdAt!)
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.withOpacity(0.15))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(cat.icon, color: c, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(bp.studentName,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.neutral900)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${bp.isPositive ? '+' : ''}${bp.points}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: c)),
                          ),
                        ]),
                        Text(cat.name,
                            style: const TextStyle(
                                fontSize: 11,
                                color: TatvaColors.neutral400)),
                        if (bp.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(bp.note,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: TatvaColors.neutral600)),
                          ),
                        if (timeAgo.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(timeAgo,
                                style: const TextStyle(
                                    fontSize: 10, color: TatvaColors.neutral400)),
                          ),
                      ]),
                ),
                GestureDetector(
                  onTap: () => _deleteBehaviorPoint(context, bp),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: TatvaColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.delete_outline_rounded,
                        color: TatvaColors.error.withOpacity(0.5),
                        size: 16),
                  ),
                ),
              ]),
            );
          }),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }


  void _deleteBehaviorPoint(BuildContext context, BehaviorPoint bp) {
    if (bp.id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete behavior point?',
            style: TextStyle(fontSize: 16)),
        content: Text(
            '${bp.isPositive ? '+' : ''}${bp.points} ${BehaviorCategory.fromId(bp.categoryId).name} for ${bp.studentName}',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteBehaviorPoint(bp.id);
                onBehaviorDeleted(bp.id);
                TatvaSnackbar.show(context, 'Behavior point deleted');
              } catch (e) {
                TatvaSnackbar.show(context, 'Failed to delete');
              }
            },
            child:
                Text('Delete', style: TextStyle(color: TatvaColors.error)),
          ),
        ],
      ),
    );
  }

  void _showBehaviorSheet(BuildContext context, String studentUid,
      String studentName, String classId) {
    final categories = BehaviorCategory.defaults;
    final positive = categories.where((c) => c.isPositive).toList();
    final negative = categories.where((c) => !c.isPositive).toList();
    final noteCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              const SizedBox(height: 16),
              Text(studentName,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900)),
              const SizedBox(height: 4),
              const Text('Select a behavior category',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400)),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral900),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: TatvaColors.bgLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: TatvaColors.primary.withOpacity(0.5),
                          width: 1.5)),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Positive',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TatvaColors.neutral900))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: positive
                    .map((cat) => _behaviorChip(context, cat, true,
                        studentUid, studentName, classId, noteCtrl))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Needs Work',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: TatvaColors.neutral900))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: negative
                    .map((cat) => _behaviorChip(context, cat, false,
                        studentUid, studentName, classId, noteCtrl))
                    .toList(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _behaviorChip(
      BuildContext context,
      BehaviorCategory cat,
      bool isPositive,
      String studentUid,
      String studentName,
      String classId,
      TextEditingController noteCtrl) {
    final chipColor = isPositive ? TatvaColors.success : TatvaColors.error;
    return GestureDetector(
      onTap: () async {
        final note = noteCtrl.text.trim();
        Navigator.pop(context);
        final resp = await ApiService().awardBehaviorPoint(
          studentUid: studentUid,
          classId: classId,
          categoryId: cat.id,
          studentName: studentName,
          points: isPositive ? 1 : -1,
          note: note,
        );
        final newId = resp['id'] as String? ?? '';
        onBehaviorAdded(BehaviorPoint(
          id: newId,
          studentUid: studentUid,
          studentName: studentName,
          classId: classId,
          categoryId: cat.id,
          points: isPositive ? 1 : -1,
          awardedBy: uid,
          awardedByName: user?.name ?? '',
          note: note,
          createdAt: DateTime.now(),
        ));
        TatvaSnackbar.show(context,
            '${isPositive ? '+1' : '-1'} ${cat.name} for $studentName');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(cat.icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(cat.name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipColor)),
        ]),
      ),
    );
  }
}
