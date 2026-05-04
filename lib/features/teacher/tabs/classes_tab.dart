import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/add_student_sheet.dart';
import '../../../shared/widgets/pick_student_sheet.dart';
import '../../../shared/widgets/student_detail_sheet.dart';
import '../../../services/api_service.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';

class TeacherClassesTab extends StatelessWidget {
  final List<ClassModel> classes;
  final List<UserModel> students;
  final VoidCallback onRefresh;
  final ValueChanged<int> onSwitchTab;

  const TeacherClassesTab({
    super.key,
    required this.classes,
    required this.students,
    required this.onRefresh,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('My Classes',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: const Text('Manage your classes and students',
                style: TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        FadeSlideIn(
            delayMs: 80,
            child: GestureDetector(
              onTap: () => _showCreateClass(context),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TatvaColors.primary.withOpacity(0.2),
                          width: 1.5)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: TatvaColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Create New Class',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.primary)),
                      ])),
            )),
        const SizedBox(height: 16),
        ...classes
            .asMap()
            .entries
            .map((e) => _classCard(context, e.value, e.key)),
      ]),
    );
  }

  Widget _classCard(BuildContext context, ClassModel c, int index) {
    final studentCount = c.studentUids.length;
    return StaggeredItem(
        index: index,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TatvaColors.primary.withOpacity(0.12),
                    TatvaColors.primary.withOpacity(0.04)
                  ]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text(c.subject,
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                    ])),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: TatvaColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: TatvaColors.accent.withOpacity(0.3))),
                    child: Text(c.classCode,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.accent,
                            letterSpacing: 2))),
              ]),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Icon(Icons.people_outline,
                      color: TatvaColors.neutral400, size: 16),
                  const SizedBox(width: 4),
                  Text('$studentCount students',
                      style: const TextStyle(
                          fontSize: 12, color: TatvaColors.neutral400)),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => _showClassStudents(context, c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.info.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: TatvaColors.info.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.people_outline,
                                color: TatvaColors.info, size: 14),
                            const SizedBox(width: 4),
                            Text('${c.studentUids.length} Students',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.info,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => onSwitchTab(8),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      TatvaColors.primary.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                color: TatvaColors.primary, size: 14),
                            const SizedBox(width: 4),
                            const Text('Grades',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.primary,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => _confirmDeleteClass(context, c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: TatvaColors.error.withOpacity(0.2))),
                          child: Icon(Icons.delete_outline_rounded,
                              color: TatvaColors.error, size: 16))),
                ])),
          ]),
        ));
  }

  void _showClassStudents(BuildContext context, ClassModel cls) {
    HapticFeedback.lightImpact();
    final classStudents = students
        .where((s) => cls.studentUids.contains(s.uid))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text(
                          '${cls.subject} · ${classStudents.length} students',
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                    ]),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showAddStudentOptions(context, cls.id, cls.studentUids);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: TatvaColors.info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: TatvaColors.info.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_outlined,
                        color: TatvaColors.info, size: 16),
                    const SizedBox(width: 4),
                    const Text('Add',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.info)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (classStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline,
                    color: TatvaColors.neutral400, size: 40),
                const SizedBox(height: 8),
                const Text('No students in this class yet',
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral400)),
              ]),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: classStudents.length,
                itemBuilder: (_, i) {
                  final s = classStudents[i];
                  final colors = [
                    TatvaColors.primary,
                    TatvaColors.info,
                    TatvaColors.accent,
                    TatvaColors.purple,
                    TatvaColors.success
                  ];
                  final c = colors[i % colors.length];
                  return GestureDetector(
                    onTap: () => StudentDetailSheet.show(context, student: s),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: c.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.withOpacity(0.1))),
                      child: Row(children: [
                        UserAvatar(
                          name: s.name,
                          radius: 18,
                          bgColor: c.withOpacity(0.12),
                          textColor: c,
                          photoUrl: s.photoUrl,
                          useDoubleInitials: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: TatvaColors.neutral900)),
                                Text(s.email,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: TatvaColors.neutral400)),
                              ]),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: TatvaColors.neutral400),
                      ]),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showAddStudentOptions(
      BuildContext context, String classId, List<String> existingStudentUids) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TatvaColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_add_outlined,
                  color: TatvaColors.info, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Add Student to Class',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
          ]),
          const SizedBox(height: 20),
          _addStudentOption(
            context: context,
            icon: Icons.person_search_outlined,
            color: TatvaColors.info,
            title: 'Pick Existing Student',
            subtitle: 'Choose from students already enrolled in school',
            onTap: () {
              Navigator.pop(context);
              PickStudentSheet.show(context,
                  classId: classId,
                  excludeStudentIds: existingStudentUids,
                  onStudentAdded: () =>
                      TatvaSnackbar.show(context, 'Student added to class'));
            },
          ),
          const SizedBox(height: 10),
          _addStudentOption(
            context: context,
            icon: Icons.person_add_alt_1_outlined,
            color: TatvaColors.primary,
            title: 'Create New Student',
            subtitle: 'Enroll a new student and add to this class',
            onTap: () {
              Navigator.pop(context);
              AddStudentSheet.show(context,
                  classId: classId,
                  onStudentAdded: () => TatvaSnackbar.show(
                      context, 'Student created and added'));
            },
          ),
        ]),
      ),
    );
  }

  Widget _addStudentOption({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: TatvaColors.neutral400)),
                ]),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ]),
      ),
    );
  }

  void _showCreateClass(BuildContext context) {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isCreating = false;
            return Container(
              decoration: const BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: TatvaColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.class_outlined,
                          color: TatvaColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Create New Class',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('A unique class code will be generated',
                      style: TextStyle(
                          fontSize: 13, color: TatvaColors.neutral400)),
                  const SizedBox(height: 20),
                  const Text('Class Name',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grade 8 — Section A',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: TatvaColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  TatvaColors.primary.withOpacity(0.5),
                              width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Subject',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectCtrl,
                    style: const TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'e.g. Mathematics',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: TatvaColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color:
                                  TatvaColors.primary.withOpacity(0.5),
                              width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BouncyTap(
                    onTap: isCreating
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                subjectCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() => isCreating = true);
                            final code = String.fromCharCodes(
                              List.generate(
                                  6, (_) => Random().nextInt(26) + 65),
                            );
                            final name = nameCtrl.text.trim();
                            final result =
                                await ApiService().createClass(
                              name: name,
                              subject: subjectCtrl.text.trim(),
                              classCode: code,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (result != null) {
                              TatvaSnackbar.show(context,
                                  'Class "$name" created! Code: $code');
                            } else {
                              TatvaSnackbar.show(context,
                                  'Failed to create class. Try again.');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  TatvaColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : const Text('Create Class',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, ClassModel cls) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${cls.name}"?\n\n'
            'This will remove ${cls.studentUids.length} student(s) and '
            '${cls.parentUids.length} parent(s) from this class. '
            'This action cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: TatvaColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteClass(cls.id);
                TatvaSnackbar.show(context, '"${cls.name}" deleted');
                onRefresh();
              } catch (e) {
                TatvaSnackbar.show(context, 'Failed to delete class');
                debugPrint('Delete class error: $e');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: TatvaColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
