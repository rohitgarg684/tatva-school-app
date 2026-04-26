import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/grade_model.dart';

class TeacherGradesTab extends StatefulWidget {
  final List<ClassModel> classes;
  final List<GradeModel> allGrades;
  final List<UserModel> allSchoolStudents;
  final List<Map<String, dynamic>> testTitles;
  final VoidCallback onRefresh;

  const TeacherGradesTab({
    super.key,
    required this.classes,
    required this.allGrades,
    required this.allSchoolStudents,
    required this.testTitles,
    required this.onRefresh,
  });

  @override
  State<TeacherGradesTab> createState() => _TeacherGradesTabState();
}

class _TeacherGradesTabState extends State<TeacherGradesTab> {
  final _api = ApiService();
  String _gradeSelectedClassId = '';
  String _gradeSearch = '';

  @override
  Widget build(BuildContext context) {
    final selClass = widget.classes.firstWhere(
        (c) => c.id == _gradeSelectedClassId,
        orElse: () => widget.classes.isNotEmpty
            ? widget.classes.first
            : ClassModel.empty());
    if (_gradeSelectedClassId.isEmpty && widget.classes.isNotEmpty) {
      _gradeSelectedClassId = selClass.id;
    }

    final classGrades = widget.allGrades
        .where((g) => g.classId == _gradeSelectedClassId)
        .toList();
    final query = _gradeSearch.toLowerCase();
    final filteredGrades = query.isEmpty
        ? classGrades
        : classGrades
            .where((g) =>
                g.studentName.toLowerCase().contains(query) ||
                g.assessmentName.toLowerCase().contains(query))
            .toList();
    filteredGrades.sort((a, b) =>
        (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));

    final classStudentUids = selClass.studentUids;
    final classStudents = widget.allSchoolStudents
        .where((s) => classStudentUids.contains(s.uid))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Grade Book',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 60,
              child: Text(
                  selClass.name.isNotEmpty
                      ? '${selClass.name} · ${selClass.subject}'
                      : 'Select a class',
                  style: const TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 16),
          if (widget.classes.length > 1)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.classes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cls = widget.classes[i];
                  final isActive = cls.id == _gradeSelectedClassId;
                  final colors = [
                    TatvaColors.primary,
                    TatvaColors.info,
                    TatvaColors.accent,
                    TatvaColors.purple,
                    TatvaColors.success
                  ];
                  final c =
                      colors[cls.subject.hashCode.abs() % colors.length];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _gradeSelectedClassId = cls.id;
                      _gradeSearch = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: isActive
                              ? c.withOpacity(0.12)
                              : TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isActive ? c : Colors.grey.shade200,
                              width: isActive ? 1.5 : 1)),
                      child: Center(
                          child: Text(cls.subject,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? c
                                      : TatvaColors.neutral400))),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Icon(Icons.search_rounded,
                  size: 18, color: TatvaColors.neutral400),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _gradeSearch = v),
                  style: const TextStyle(
                      fontSize: 13, color: TatvaColors.neutral900),
                  decoration: InputDecoration(
                    hintText: 'Search student or test...',
                    hintStyle: TextStyle(
                        fontSize: 13,
                        color: TatvaColors.neutral400.withOpacity(0.5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _gradeStatChip(
                '${classGrades.length}', 'Grades', TatvaColors.primary),
            const SizedBox(width: 8),
            _gradeStatChip(
                '${classStudents.length}', 'Students', TatvaColors.info),
            const SizedBox(width: 8),
            if (classGrades.isNotEmpty)
              _gradeStatChip(
                  '${(classGrades.fold<double>(0, (s, g) => s + g.percentage) / classGrades.length).round()}%',
                  'Avg',
                  classGrades.fold<double>(
                                  0, (s, g) => s + g.percentage) /
                              classGrades.length >=
                          70
                      ? TatvaColors.success
                      : TatvaColors.accent),
            const Spacer(),
            GestureDetector(
              onTap: () => _showTestTitlesManager(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: TatvaColors.purple.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: TatvaColors.purple.withOpacity(0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.list_alt_rounded,
                      size: 14, color: TatvaColors.purple),
                  const SizedBox(width: 4),
                  Text('Tests',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.purple)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _showGradeEntrySheet(
              classId: _gradeSelectedClassId,
              subject: selClass.subject,
              students: classStudents,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: TatvaColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: TatvaColors.primary.withOpacity(0.15))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        color: TatvaColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('Add Grade',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.primary)),
                  ]),
            ),
          ),
          const SizedBox(height: 14),
          if (filteredGrades.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.grade_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('No grades yet',
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Text('Tap + to add grades for students',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade300)),
                ]),
              ),
            )
          else
            ...filteredGrades.asMap().entries.map((e) {
              final g = e.value;
              final pct = g.total > 0 ? g.score / g.total : 0.0;
              final c = pct >= 0.9
                  ? TatvaColors.success
                  : pct >= 0.7
                      ? TatvaColors.accent
                      : TatvaColors.error;
              return StaggeredItem(
                  index: e.key,
                  child: GestureDetector(
                    onTap: () => _showGradeEntrySheet(
                      classId: _gradeSelectedClassId,
                      subject: selClass.subject,
                      students: classStudents,
                      existingGrade: g,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey.shade100)),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                TatvaColors.primary.withOpacity(0.1),
                            child: Text(
                                g.studentName.isNotEmpty
                                    ? g.studentName[0]
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.primary))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                              Text(g.studentName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral900)),
                              Text(g.assessmentName,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: TatvaColors.neutral400)),
                            ])),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${g.score.toInt()}/${g.total.toInt()}',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: c))),
                      ]),
                    ),
                  ));
            }),
        ]));
  }

  Widget _gradeStatChip(String value, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: c)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(fontSize: 10, color: c.withOpacity(0.7))),
      ]),
    );
  }

  void _showGradeEntrySheet({
    required String classId,
    required String subject,
    required List<UserModel> students,
    GradeModel? existingGrade,
  }) {
    final isEdit = existingGrade != null;
    String selectedStudentUid = existingGrade?.studentUid ?? '';
    String selectedStudentName = existingGrade?.studentName ?? '';
    final scoreCtrl = TextEditingController(
        text: isEdit ? existingGrade.score.toInt().toString() : '');
    final totalCtrl = TextEditingController(
        text: isEdit ? existingGrade.total.toInt().toString() : '100');
    final assessCtrl = TextEditingController(
        text: existingGrade?.assessmentName ?? '');
    String assessQuery = existingGrade?.assessmentName ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final suggestions = assessQuery.isEmpty
            ? <Map<String, dynamic>>[]
            : widget.testTitles.where((t) {
                final title = (t['title'] as String? ?? '').toLowerCase();
                return title.contains(assessQuery.toLowerCase()) &&
                    title != assessQuery.toLowerCase();
              }).toList();

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            decoration: const BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
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
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Text(isEdit ? 'Edit Grade' : 'Add Grade',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 4),
                    Text(subject,
                        style: const TextStyle(
                            fontSize: 12,
                            color: TatvaColors.neutral400)),
                    const SizedBox(height: 20),

                    const Text('Student',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral400)),
                    const SizedBox(height: 6),
                    if (isEdit)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(selectedStudentName,
                            style: const TextStyle(
                                fontSize: 14,
                                color: TatvaColors.neutral900)),
                      )
                    else
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgLight,
                            borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStudentUid.isEmpty
                                ? null
                                : selectedStudentUid,
                            hint: Text('Select student',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: TatvaColors.neutral400
                                        .withOpacity(0.5))),
                            isExpanded: true,
                            style: const TextStyle(
                                fontSize: 14,
                                color: TatvaColors.neutral900),
                            items: students
                                .map((s) => DropdownMenuItem(
                                    value: s.uid,
                                    child: Text(s.name)))
                                .toList(),
                            onChanged: (v) => setSheet(() {
                              selectedStudentUid = v ?? '';
                              selectedStudentName = students
                                  .firstWhere((s) => s.uid == v,
                                      orElse: () => students.first)
                                  .name;
                            }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    const Text('Test / Assessment',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral400)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: assessCtrl,
                      onChanged: (v) =>
                          setSheet(() => assessQuery = v),
                      style: const TextStyle(
                          fontSize: 14,
                          color: TatvaColors.neutral900),
                      decoration: InputDecoration(
                        hintText: 'e.g. Unit Test 1, Mid-Term',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color:
                                TatvaColors.neutral400.withOpacity(0.5)),
                        filled: true,
                        fillColor: TatvaColors.bgLight,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    if (suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            color: TatvaColors.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                suggestions.take(5).map((t) {
                              final title =
                                  t['title'] as String? ?? '';
                              final ttTotal =
                                  (t['total'] as num?)?.toDouble() ??
                                      100;
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  assessCtrl.text = title;
                                  assessQuery = title;
                                  totalCtrl.text =
                                      ttTotal.toInt().toString();
                                }),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color:
                                                  Colors.grey.shade100,
                                              width: 0.5))),
                                  child: Row(children: [
                                    Icon(Icons.history_rounded,
                                        size: 14,
                                        color: TatvaColors.neutral400),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(title,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: TatvaColors
                                                    .neutral900))),
                                    Text('/${ttTotal.toInt()}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: TatvaColors
                                                .neutral400)),
                                  ]),
                                ),
                              );
                            }).toList()),
                      ),
                    if (assessQuery.isEmpty &&
                        widget.testTitles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              widget.testTitles.take(8).map((t) {
                            final title =
                                t['title'] as String? ?? '';
                            final ttTotal =
                                (t['total'] as num?)?.toDouble() ??
                                    100;
                            return GestureDetector(
                              onTap: () => setSheet(() {
                                assessCtrl.text = title;
                                assessQuery = title;
                                totalCtrl.text =
                                    ttTotal.toInt().toString();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: TatvaColors.info
                                        .withOpacity(0.06),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: TatvaColors.info
                                            .withOpacity(0.15))),
                                child: Text(title,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: TatvaColors.info)),
                              ),
                            );
                          }).toList()),
                    ],
                    const SizedBox(height: 16),

                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Score',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral400)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: scoreCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                      color: TatvaColors.neutral400
                                          .withOpacity(0.3)),
                                  filled: true,
                                  fillColor: TatvaColors.bgLight,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12),
                                ),
                              ),
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Text(' / ',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.neutral400)),
                      ),
                      Expanded(
                        child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral400)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: totalCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.neutral900),
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: TextStyle(
                                      color: TatvaColors.neutral400
                                          .withOpacity(0.3)),
                                  filled: true,
                                  fillColor: TatvaColors.bgLight,
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12),
                                ),
                              ),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    Row(children: [
                      if (isEdit)
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              try {
                                await _api
                                    .deleteGrade(existingGrade.id);
                                widget.allGrades.removeWhere(
                                    (g) => g.id == existingGrade.id);
                                setState(() {});
                                if (context.mounted) {
                                  TatvaSnackbar.show(
                                      context, 'Grade deleted');
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  TatvaSnackbar.show(
                                      context, 'Failed to delete');
                                }
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  color: TatvaColors.error
                                      .withOpacity(0.06),
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                      color: TatvaColors.error
                                          .withOpacity(0.2))),
                              child: Center(
                                  child: Text('Delete',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: TatvaColors.error))),
                            ),
                          ),
                        ),
                      if (isEdit) const SizedBox(width: 12),
                      Expanded(
                        flex: isEdit ? 2 : 1,
                        child: GestureDetector(
                          onTap: () async {
                            if (selectedStudentUid.isEmpty) {
                              TatvaSnackbar.show(
                                  context, 'Select a student');
                              return;
                            }
                            if (assessCtrl.text.trim().isEmpty) {
                              TatvaSnackbar.show(
                                  context, 'Enter a test name');
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final assessName =
                                  assessCtrl.text.trim();
                              final score = double.tryParse(
                                      scoreCtrl.text.trim()) ??
                                  0;
                              final total = double.tryParse(
                                      totalCtrl.text.trim()) ??
                                  100;
                              await _api.enterGrade(
                                studentUid: selectedStudentUid,
                                classId: classId,
                                subject: subject,
                                assessmentName: assessName,
                                studentName: selectedStudentName,
                                score: score,
                                total: total,
                              );
                              if (!widget.testTitles.any((t) =>
                                  (t['title'] as String? ?? '')
                                      .toLowerCase() ==
                                  assessName.toLowerCase())) {
                                await _api.addTestTitle(
                                    title: assessName,
                                    subject: subject,
                                    total: total);
                              }
                              widget.onRefresh();
                              if (context.mounted) {
                                TatvaSnackbar.show(
                                    context,
                                    isEdit
                                        ? 'Grade updated'
                                        : 'Grade saved');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                TatvaSnackbar.show(
                                    context, 'Failed: $e');
                              }
                            }
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                                color: TatvaColors.primary,
                                borderRadius:
                                    BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: TatvaColors.primary
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4))
                                ]),
                            child: Center(
                                child: Text(
                                    isEdit ? 'Update' : 'Save',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                          ),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        );
      }),
    );
  }

  void _showTestTitlesManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('Saved Test Titles',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                const SizedBox(height: 4),
                const Text(
                    'These appear as suggestions when entering grades',
                    style: TextStyle(
                        fontSize: 12,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 16),
                if (widget.testTitles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                        child: Text('No saved test titles yet',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade400))),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.testTitles.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final t = widget.testTitles[i];
                        final title = t['title'] as String? ?? '';
                        final ttSubject =
                            t['subject'] as String? ?? '';
                        final ttTotal =
                            (t['total'] as num?)?.toInt() ?? 100;
                        final ttId = t['id'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(children: [
                            Icon(Icons.description_outlined,
                                size: 16,
                                color: TatvaColors.purple),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(title,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              TatvaColors.neutral900)),
                                  if (ttSubject.isNotEmpty)
                                    Text('$ttSubject · /$ttTotal',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: TatvaColors
                                                .neutral400)),
                                ])),
                            GestureDetector(
                              onTap: () async {
                                if (ttId.isEmpty) return;
                                try {
                                  await _api
                                      .deleteTestTitle(ttId);
                                  setSheet(() {
                                    widget.testTitles.removeWhere(
                                        (tt) =>
                                            tt['id'] == ttId);
                                  });
                                  setState(() {});
                                  if (context.mounted) {
                                    TatvaSnackbar.show(context,
                                        '"$title" removed');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    TatvaSnackbar.show(context,
                                        'Failed to delete');
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: TatvaColors.error
                                        .withOpacity(0.06),
                                    shape: BoxShape.circle),
                                child: Icon(Icons.close_rounded,
                                    size: 14,
                                    color: TatvaColors.error),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
              ]),
        );
      }),
    );
  }
}
