import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/student_model.dart';
import '../../services/class_service.dart';
import '../theme/colors.dart';

class PickStudentSheet extends StatefulWidget {
  final String classId;
  final List<String> excludeStudentIds;
  final VoidCallback? onStudentAdded;

  const PickStudentSheet({
    super.key,
    required this.classId,
    this.excludeStudentIds = const [],
    this.onStudentAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String classId,
    List<String> excludeStudentIds = const [],
    VoidCallback? onStudentAdded,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PickStudentSheet(
        classId: classId,
        excludeStudentIds: excludeStudentIds,
        onStudentAdded: onStudentAdded,
      ),
    );
  }

  @override
  State<PickStudentSheet> createState() => _PickStudentSheetState();
}

class _PickStudentSheetState extends State<PickStudentSheet> {
  final _searchCtrl = TextEditingController();
  final _service = ClassService();

  List<StudentModel> _allStudents = [];
  List<StudentModel> _filtered = [];
  bool _isLoading = true;
  String? _addingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await _service.getAllStudentRecords();
    if (!mounted) return;
    setState(() {
      _allStudents = all
          .where((s) => !widget.excludeStudentIds.contains(s.id))
          .toList();
      _filtered = _allStudents;
      _isLoading = false;
    });
  }

  void _filter(String query) {
    final lower = query.trim().toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filtered = _allStudents;
      } else {
        _filtered = _allStudents
            .where((s) =>
                s.name.toLowerCase().contains(lower) ||
                s.rollNumber.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  Future<void> _addToClass(StudentModel student) async {
    setState(() => _addingId = student.id);
    final ok = await _service.addStudentToClassById(
      classId: widget.classId,
      studentId: student.id,
    );
    if (!mounted) return;

    if (ok) {
      widget.onStudentAdded?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${student.name} added to class',
            style: const TextStyle(fontFamily: 'Raleway')),
        backgroundColor: TatvaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      setState(() => _addingId = null);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Failed to add student',
            style: TextStyle(fontFamily: 'Raleway')),
        backgroundColor: TatvaColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TatvaColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_search_outlined,
                  color: TatvaColors.info, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('Pick Existing Student',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
          ]),
          const SizedBox(height: 4),
          const Text('Search from students already enrolled in the school',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: TatvaColors.neutral400)),
          const SizedBox(height: 16),

          TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                color: TatvaColors.neutral900),
            decoration: InputDecoration(
              hintText: 'Search by name or roll number...',
              hintStyle: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search,
                  color: TatvaColors.neutral400, size: 20),
              filled: true,
              fillColor: TatvaColors.bgLight,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: TatvaColors.info.withOpacity(0.5), width: 1.5)),
            ),
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: CircularProgressIndicator(color: TatvaColors.primary),
              ),
            )
          else if (_filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(children: [
                  Icon(Icons.people_outline,
                      color: TatvaColors.neutral300, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _searchCtrl.text.isNotEmpty
                        ? 'No students match your search'
                        : 'No students enrolled yet',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: TatvaColors.neutral400),
                  ),
                ]),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  final isAdding = _addingId == s.id;
                  return GestureDetector(
                    onTap: isAdding ? null : () => _addToClass(s),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              TatvaColors.primary.withOpacity(0.1),
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: TatvaColors.neutral900)),
                              if (s.rollNumber.isNotEmpty ||
                                  s.displayGradeSection.isNotEmpty)
                                Text(
                                  [
                                    if (s.rollNumber.isNotEmpty) s.rollNumber,
                                    if (s.displayGradeSection.isNotEmpty)
                                      s.displayGradeSection,
                                  ].join(' · '),
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 12,
                                      color: TatvaColors.neutral400),
                                ),
                            ],
                          ),
                        ),
                        if (isAdding)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: TatvaColors.primary),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: TatvaColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: TatvaColors.primary.withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_rounded,
                                    color: TatvaColors.primary, size: 14),
                                SizedBox(width: 2),
                                Text('Add',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        color: TatvaColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
