import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/attendance_record.dart';
import '../../../models/attendance_status.dart';

class TeacherAttendanceTab extends StatefulWidget {
  final List<UserModel> allSchoolStudents;
  final List<UserModel> students;
  final List<ClassModel> classes;
  final List<AttendanceRecord> todayAttendance;
  final String uid;
  final void Function(List<AttendanceRecord>) onAttendanceSaved;

  const TeacherAttendanceTab({
    super.key,
    required this.allSchoolStudents,
    required this.students,
    required this.classes,
    required this.todayAttendance,
    required this.uid,
    required this.onAttendanceSaved,
  });

  @override
  State<TeacherAttendanceTab> createState() => _TeacherAttendanceTabState();
}

class _TeacherAttendanceTabState extends State<TeacherAttendanceTab> {
  String _attSearchQuery = '';
  final _api = ApiService();
  late DateTime _selectedDate;
  List<AttendanceRecord> _attendance = [];
  bool _loading = false;
  bool _isToday = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _attendance = List.of(widget.todayAttendance);
  }

  String _formatDateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime d) =>
      '${_monthName(d.month)} ${d.day}, ${d.year}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: TatvaColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: TatvaColors.neutral900,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || _isSameDay(picked, _selectedDate)) return;
    setState(() {
      _selectedDate = picked;
      _isToday = _isSameDay(picked, DateTime.now());
    });
    await _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    if (_isToday) {
      setState(() => _attendance = List.of(widget.todayAttendance));
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await _api.getAttendanceByDate(_formatDateKey(_selectedDate));
      final list = (resp['records'] as List?)
              ?.map((r) => AttendanceRecord.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [];
      setState(() => _attendance = list);
    } catch (_) {
      if (mounted) TatvaSnackbar.show(context, 'Failed to load attendance');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserModel> get _allStudents {
    final result = List<UserModel>.from(widget.allSchoolStudents);
    if (result.isEmpty) {
      final seenUids = <String>{};
      for (final cls in widget.classes) {
        for (final uid in cls.studentUids) {
          if (seenUids.add(uid)) {
            final match = widget.students.where((s) => s.uid == uid);
            if (match.isNotEmpty) result.add(match.first);
          }
        }
      }
      for (final s in widget.students) {
        if (!seenUids.contains(s.uid)) {
          seenUids.add(s.uid);
          result.add(s);
        }
      }
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatDateKey(_selectedDate);
    final allStudents = _allStudents;

    final preMarked = <String, AttendanceStatus>{};
    for (final r in _attendance) {
      preMarked[r.studentUid] = r.status;
    }

    return StatefulBuilder(builder: (ctx, setLocal) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(builder: (ctx2, setInner) {
          final filtered = _attSearchQuery.isEmpty
              ? allStudents
              : allStudents
                  .where((s) => s.name
                      .toLowerCase()
                      .contains(_attSearchQuery.toLowerCase()))
                  .toList();

          final presentCount = allStudents
              .where((s) =>
                  (preMarked[s.uid] ?? AttendanceStatus.present) ==
                  AttendanceStatus.present)
              .length;
          final absentCount = allStudents
              .where((s) => preMarked[s.uid] == AttendanceStatus.absent)
              .length;
          final tardyCount = allStudents
              .where((s) => preMarked[s.uid] == AttendanceStatus.tardy)
              .length;

          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeSlideIn(
                    child: const Text('Attendance',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900,
                            letterSpacing: -0.8))),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delayMs: 60,
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: TatvaColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatDisplayDate(_selectedDate),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TatvaColors.primary),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded,
                            size: 18, color: TatvaColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${allStudents.length} students in school',
                          style: const TextStyle(
                              fontSize: 13, color: TatvaColors.neutral400),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  _attSummaryChip(
                      'Present', presentCount, TatvaColors.success),
                  const SizedBox(width: 8),
                  _attSummaryChip('Absent', absentCount, TatvaColors.error),
                  const SizedBox(width: 8),
                  _attSummaryChip('Tardy', tardyCount, TatvaColors.accent),
                ]),
                const SizedBox(height: 16),
                if (_attendance.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: TatvaColors.success.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: TatvaColors.success.withOpacity(0.2))),
                    child: Row(children: [
                      Icon(Icons.check_circle_outline,
                          color: TatvaColors.success, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              'Attendance already marked for ${_formatDisplayDate(_selectedDate)}. You can update it.',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: TatvaColors.neutral600))),
                    ]),
                  ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                        child: CircularProgressIndicator(
                            color: TatvaColors.primary, strokeWidth: 2)),
                  )
                else ...[
                  Row(children: [
                    _attBulkBtn('All Present', TatvaColors.success, () {
                      setInner(() {
                        for (final s in allStudents) {
                          preMarked[s.uid] = AttendanceStatus.present;
                        }
                      });
                    }),
                    const SizedBox(width: 8),
                    _attBulkBtn('All Absent', TatvaColors.error, () {
                      setInner(() {
                        for (final s in allStudents) {
                          preMarked[s.uid] = AttendanceStatus.absent;
                        }
                      });
                    }),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) =>
                        setInner(() => _attSearchQuery = v),
                    style: const TextStyle(
                        fontSize: 13, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'Search students...',
                      hintStyle: TextStyle(
                          fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: TatvaColors.bgCard,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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
                                  TatvaColors.primary.withOpacity(0.4))),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...filtered.map((s) {
                    final current =
                        preMarked[s.uid] ?? AttendanceStatus.present;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade100)),
                      child: Row(children: [
                        CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                TatvaColors.primary.withOpacity(0.1),
                            child: Text(s.initial,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.primary))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(s.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: TatvaColors.neutral900))),
                        ...AttendanceStatus.values.map((st) => Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: GestureDetector(
                                onTap: () =>
                                    setInner(() => preMarked[s.uid] = st),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: current == st
                                          ? _attendanceColor(st)
                                              .withOpacity(0.15)
                                          : Colors.transparent,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                          color: current == st
                                              ? _attendanceColor(st)
                                              : Colors.grey.shade200)),
                                  child: Text(st.label,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: current == st
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: current == st
                                              ? _attendanceColor(st)
                                              : TatvaColors.neutral400)),
                                ),
                              ),
                            )),
                      ]),
                    );
                  }),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final finalStatuses = <String, AttendanceStatus>{};
                      final names = <String, String>{};
                      for (final s in allStudents) {
                        finalStatuses[s.uid] =
                            preMarked[s.uid] ?? AttendanceStatus.present;
                        names[s.uid] = s.name;
                      }
                      final records = finalStatuses.entries
                          .map((e) => {
                                'studentUid': e.key,
                                'studentName': names[e.key] ?? '',
                                'date': dateStr,
                                'status': e.value.label,
                              })
                          .toList();
                      _api.markAttendanceBatch(records);
                      final saved = finalStatuses.entries
                          .map((e) => AttendanceRecord(
                                studentUid: e.key,
                                studentName: names[e.key] ?? '',
                                date: dateStr,
                                status: e.value,
                                markedBy: widget.uid,
                                createdAt: DateTime.now(),
                              ))
                          .toList();
                      setState(() => _attendance = saved);
                      if (_isToday) widget.onAttendanceSaved(saved);
                      if (mounted) {
                        TatvaSnackbar.show(context,
                            'Attendance saved for ${allStudents.length} students');
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
                                offset: const Offset(0, 4))
                          ]),
                      child: Center(
                          child: Text(
                              _attendance.isNotEmpty
                                  ? 'Update Attendance'
                                  : 'Save Attendance',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ]);
        }),
      );
    });
  }

  Widget _attSummaryChip(String label, int count, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: c.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ]),
      );

  Widget _attBulkBtn(String label, Color c, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c))),
          ),
        ),
      );

  Color _attendanceColor(AttendanceStatus st) {
    switch (st) {
      case AttendanceStatus.present:
        return TatvaColors.success;
      case AttendanceStatus.absent:
        return TatvaColors.error;
      case AttendanceStatus.tardy:
        return TatvaColors.accent;
    }
  }

  static String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}
