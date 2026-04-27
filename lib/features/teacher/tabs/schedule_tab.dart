import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/class_model.dart';
import '../../../models/schedule_model.dart';
import '../../../models/schedule_event.dart';
import '../../../models/holiday.dart';

class _DayItem {
  final int startMin, endMin;
  final Map<String, dynamic> data;
  final bool isPeriod;
  _DayItem.period(this.data, this.startMin, this.endMin) : isPeriod = true;
  _DayItem.event(this.data, this.startMin, this.endMin) : isPeriod = false;
}

class TeacherScheduleTab extends StatefulWidget {
  final List<ClassModel> classes;
  final String uid;
  final VoidCallback? onRefresh;

  const TeacherScheduleTab({
    super.key,
    required this.classes,
    required this.uid,
    this.onRefresh,
  });

  @override
  State<TeacherScheduleTab> createState() => _TeacherScheduleTabState();
}

class _TeacherScheduleTabState extends State<TeacherScheduleTab> {
  final _api = ApiService();
  List<ScheduleModel> _tSchedData = [];
  bool _tSchedLoading = false;
  bool _tSchedLoaded = false;
  int _tSchedDay = 0;
  String _tSchedSelectedGS = '';
  int _schedViewMode = 0;
  List<Map<String, dynamic>> _calPeriods = [];
  List<Map<String, dynamic>> _calEvents = [];
  List<Map<String, dynamic>> _calCancellations = [];
  bool _calLoading = false;
  bool _calLoaded = false;
  DateTime _calWeekStart = DateTime.now();
  List<Holiday> _holidays = [];
  bool _holidaysLoading = false;
  bool _holidaysLoaded = false;
  String _firstDay = '';
  String _lastDay = '';
  bool _schoolDatesLoaded = false;
  List<Map<String, dynamic>> _dailyDefaultSlots = [];
  bool _dailyDefaultsLoaded = false;
  bool _dailyDefaultsSaving = false;
  String _dailyDefaultsGrade = '';

  Map<String, Map<String, String>> get _schedGsMap {
    final gsMap = <String, Map<String, String>>{};
    for (final cls in widget.classes) {
      final parts = cls.name.split('—').map((s) => s.trim()).toList();
      if (parts.length >= 2) {
        final gradePart = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
        final sectionPart = parts[1].replaceAll(RegExp(r'Section\s*', caseSensitive: false), '').trim();
        if (gradePart.isNotEmpty && sectionPart.isNotEmpty) {
          final key = 'Grade $gradePart - $sectionPart';
          if (!gsMap.containsKey(key)) {
            gsMap[key] = {'grade': gradePart, 'section': sectionPart};
          }
        }
      }
    }
    if (gsMap.isEmpty) gsMap['Default'] = {'grade': '0', 'section': 'A'};
    return gsMap;
  }

  Future<void> _loadTeacherSchedule() async {
    if (_tSchedLoading) return;
    final gsMap = _schedGsMap;
    if (_tSchedSelectedGS.isEmpty || !gsMap.containsKey(_tSchedSelectedGS)) {
      _tSchedSelectedGS = gsMap.keys.first;
    }
    final gs = gsMap[_tSchedSelectedGS]!;
    setState(() => _tSchedLoading = true);
    try {
      final raw = await _api.getSchedule(gs['grade']!, gs['section']!);
      _tSchedData = raw.map((m) => ScheduleModel.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Schedule load error: $e');
      _tSchedData = [];
    }
    if (mounted) setState(() { _tSchedLoading = false; _tSchedLoaded = true; });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  void _loadCalendar() async {
    if (_calLoading) return;
    setState(() => _calLoading = true);
    final ws = _mondayOf(_calWeekStart);
    final we = ws.add(const Duration(days: 6));
    try {
      final data = await _api.getTeacherCalendar(
          widget.uid, _dateStr(ws), _dateStr(we));
      _calPeriods =
          (data['periods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _calEvents =
          (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _calCancellations =
          (data['cancellations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Calendar load error: $e');
      _calPeriods = [];
      _calEvents = [];
      _calCancellations = [];
    }
    if (mounted) setState(() { _calLoading = false; _calLoaded = true; });
  }

  @override
  Widget build(BuildContext context) => _buildScheduleTab();

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Schedule',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: TatvaColors.bgLight, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _schedModeBtn('My Week', 0),
            _schedModeBtn('Timetable', 1),
            _schedModeBtn('Holidays', 2),
          ]),
        ),
        const SizedBox(height: 16),
        if (_schedViewMode == 0)
          _buildMyWeekCalendar()
        else if (_schedViewMode == 1)
          _buildTimetableEditor()
        else
          _buildHolidaysManager(),
      ]),
    );
  }

  Widget _schedModeBtn(String label, int mode) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _schedViewMode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: _schedViewMode == mode ? TatvaColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _schedViewMode == mode
                            ? Colors.white
                            : TatvaColors.neutral400))),
          ),
        ),
      );

  // ─── MY WEEK CALENDAR (Outlook-style) ─────────────────────────────────────

  Holiday? _holidayForDate(DateTime d) {
    final ds = _dateStr(d);
    for (final h in _holidays) {
      if (h.coversDate(ds)) return h;
    }
    return null;
  }

  List<Widget> _weekHolidayCards(DateTime ws) {
    final eventDates = _calEvents
        .where((ev) => ev['type'] == 'holiday')
        .map((ev) => ev['date'] as String? ?? '')
        .toSet();
    final shown = <String>{};
    final cards = <Widget>[];
    for (int i = 0; i < 5; i++) {
      final d = ws.add(Duration(days: i));
      final ds = _dateStr(d);
      final h = _holidayForDate(d);
      if (h != null && !eventDates.contains(ds) && shown.add(h.id.isEmpty ? h.name : h.id)) {
        cards.add(Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: TatvaColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TatvaColors.error.withOpacity(0.2))),
          child: Row(children: [
            Icon(h.typeIcon, size: 16, color: TatvaColors.error),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(h.name,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.error)),
                  Text('${h.startDate} · Holiday',
                      style: const TextStyle(
                          fontSize: 10,
                          color: TatvaColors.neutral400)),
                ])),
          ]),
        ));
      }
    }
    return cards;
  }

  Widget _buildMyWeekCalendar() {
    if (!_calLoaded && !_calLoading) {
      _calWeekStart = _mondayOf(DateTime.now());
      Future.microtask(_loadCalendar);
    }
    if (!_holidaysLoaded && !_holidaysLoading) {
      Future.microtask(_loadHolidays);
    }

    final ws = _mondayOf(_calWeekStart);
    final weekLabel =
        '${_monthName(ws.month)} ${ws.day} — ${_monthName(ws.add(const Duration(days: 4)).month)} ${ws.add(const Duration(days: 4)).day}';

    const startHour = 8;
    const endHour = 16;
    const hourHeight = 60.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        GestureDetector(
          onTap: () {
            _calWeekStart = ws.subtract(const Duration(days: 7));
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.chevron_left_rounded,
                  size: 20, color: TatvaColors.neutral400)),
        ),
        Expanded(
            child: Center(
                child: Text(weekLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)))),
        GestureDetector(
          onTap: () {
            _calWeekStart = ws.add(const Duration(days: 7));
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: TatvaColors.neutral400)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _calWeekStart = _mondayOf(DateTime.now());
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: TatvaColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Today',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TatvaColors.primary))),
        ),
      ]),
      const SizedBox(height: 12),
      if (_calEvents.isNotEmpty)
        ..._calEvents.map((ev) {
          final evDate = ev['date'] as String? ?? '';
          final evTitle = ev['title'] as String? ?? '';
          final evType = ev['type'] as String? ?? 'event';
          final cancels = ev['cancelsRegularSchedule'] == true;
          final c = evType == 'holiday'
              ? TatvaColors.error
              : evType == 'ptm'
                  ? TatvaColors.purple
                  : TatvaColors.accent;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Row(children: [
              Icon(
                  evType == 'holiday'
                      ? Icons.wb_sunny_outlined
                      : evType == 'ptm'
                          ? Icons.people_outline
                          : Icons.event_outlined,
                  size: 16,
                  color: c),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(evTitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c)),
                    Text(
                        '${evDate}${cancels ? ' · Regular schedule cancelled' : ''}',
                        style: const TextStyle(
                            fontSize: 10,
                            color: TatvaColors.neutral400)),
                  ])),
              GestureDetector(
                onTap: () async {
                  final id = ev['id'] as String? ?? '';
                  if (id.isEmpty) return;
                  await _api.deleteScheduleEvent(id);
                  _calLoaded = false;
                  _loadCalendar();
                },
                child: Icon(Icons.close_rounded, size: 16, color: TatvaColors.neutral400),
              ),
            ]),
          );
        }),
      ..._weekHolidayCards(ws),
      GestureDetector(
        onTap: () => _showAddEventSheet(ws),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: TatvaColors.accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TatvaColors.accent.withOpacity(0.15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, size: 16, color: TatvaColors.accent),
            const SizedBox(width: 4),
            Text('Add Special Event',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TatvaColors.accent)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (_calLoading && !_calLoaded)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2)))
      else
        SizedBox(
          height: (endHour - startHour) * hourHeight + 36,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 40,
              child: Column(children: [
                const SizedBox(height: 36),
                ...List.generate(endHour - startHour, (i) => SizedBox(
                      height: hourHeight,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                                '${(startHour + i).toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                    fontSize: 9,
                                    color: TatvaColors.neutral400)),
                          )),
                    )),
              ]),
            ),
            ...List.generate(5, (dayIdx) {
              final day = dayIdx + 1;
              final dateOfDay = ws.add(Duration(days: dayIdx));
              final isToday = _dateStr(dateOfDay) == _dateStr(DateTime.now());

              final dayPeriods = _calPeriods
                  .where((p) => (p['dayOfWeek'] as num?)?.toInt() == day)
                  .toList();

              final holiday = _holidayForDate(dateOfDay);
              final dayCancelled = holiday != null ||
                  _calEvents.any((ev) =>
                      ev['date'] == _dateStr(dateOfDay) &&
                      ev['cancelsRegularSchedule'] == true);

              final headerColor = holiday != null
                  ? TatvaColors.error
                  : isToday
                      ? TatvaColors.primary
                      : null;

              return Expanded(
                child: Column(children: [
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                        color: holiday != null
                            ? TatvaColors.error.withOpacity(0.08)
                            : isToday
                                ? TatvaColors.primary.withOpacity(0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(ScheduleModel.dayNames[day],
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: headerColor ?? TatvaColors.neutral400)),
                          Text('${dateOfDay.day}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: headerColor ?? TatvaColors.neutral900)),
                        ])),
                  ),
                  Container(
                    height: (endHour - startHour) * hourHeight,
                    decoration: BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                color: Colors.grey.shade100, width: 0.5))),
                    child: Stack(children: [
                      ...List.generate(
                          endHour - startHour,
                          (i) => Positioned(
                                top: i * hourHeight,
                                left: 0,
                                right: 0,
                                child: Container(
                                    height: 0.5,
                                    color: Colors.grey.shade100),
                              )),
                      ..._buildDayStackItems(
                        dayPeriods: dayPeriods,
                        dayCancelled: dayCancelled,
                        dateOfDay: dateOfDay,
                        hourHeight: hourHeight,
                        startHour: startHour,
                      ),
                    ]),
                  ),
                ]),
              );
            }),
          ]),
        ),
      const SizedBox(height: 24),
    ]);
  }

  // ─── PERIOD CANCEL / UNDO SHEETS ────────────────────────────────────────────

  void _showPeriodCancelSheet(Map<String, dynamic> period, DateTime dateOfDay, String? gsKey) {
    final subj = period['subject'] as String? ?? '';
    final grade = period['grade'] as String? ?? '';
    final section = period['section'] as String? ?? '';
    final st = period['startTime'] as String? ?? '';
    final classId = period['classId'] as String? ?? '';
    final dateStr = _dateStr(dateOfDay);
    final dayName = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateOfDay.weekday];
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Text('$subj · $grade-$section',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 4),
          Text('$st · $dayName, ${_monthName(dateOfDay.month)} ${dateOfDay.day}',
              style: const TextStyle(
fontSize: 13, color: TatvaColors.neutral400)),
          const SizedBox(height: 16),
          TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: TatvaColors.neutral400.withOpacity(0.5)),
              filled: true,
              fillColor: TatvaColors.bgLight,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            style: const TextStyle(
fontSize: 13, color: TatvaColors.neutral900),
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (gsKey != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _schedViewMode = 1;
                      _tSchedSelectedGS = gsKey;
                      _tSchedDay = dateOfDay.weekday;
                      _tSchedLoaded = false;
                      _loadTeacherSchedule();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: const Center(
                        child: Text('Edit Timetable',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral900))),
                  ),
                ),
              ),
            if (gsKey != null) const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _api.cancelPeriod(
                      grade: grade,
                      section: section,
                      date: dateStr,
                      startTime: st,
                      classId: classId,
                      reason: reasonCtrl.text.trim(),
                    );
                    _calLoaded = false;
                    _loadCalendar();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: TatvaColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TatvaColors.error.withOpacity(0.3))),
                  child: Center(
                      child: Text(
                          'Cancel for $dayName, ${_monthName(dateOfDay.month)} ${dateOfDay.day}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: TatvaColors.error))),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showUndoCancelSheet(String cancelId, String subj, String grade, String section, String dateStr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Icon(Icons.cancel_outlined, size: 36, color: TatvaColors.error),
          const SizedBox(height: 10),
          Text('$subj · $grade-$section',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 4),
          Text('This period is cancelled for $dateStr',
              style: const TextStyle(
fontSize: 13, color: TatvaColors.neutral400)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              if (cancelId.isEmpty) return;
              try {
                await _api.undoCancelPeriod(cancelId);
                _calLoaded = false;
                _loadCalendar();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: TatvaColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TatvaColors.success.withOpacity(0.3))),
              child: Center(
                  child: Text('Restore This Period',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.success))),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── Daily Defaults (Yoga / Lunch Break) ──────────────────────────────────

  String get _selectedGrade {
    final gs = _schedGsMap[_tSchedSelectedGS];
    return gs?['grade'] ?? '0';
  }

  Future<void> _loadDailyDefaults() async {
    final grade = _selectedGrade;
    try {
      final raw = await _api.getDailyDefaults(grade);
      if (mounted) setState(() {
        _dailyDefaultSlots = raw;
        _dailyDefaultsLoaded = true;
        _dailyDefaultsGrade = grade;
      });
    } catch (e) {
      debugPrint('Daily defaults load error: $e');
      if (mounted) setState(() => _dailyDefaultsLoaded = true);
    }
  }

  Future<void> _saveDailyDefaults() async {
    setState(() => _dailyDefaultsSaving = true);
    try {
      await _api.setDailyDefaults(_selectedGrade, _dailyDefaultSlots);
      if (mounted) TatvaSnackbar.show(context, 'Daily schedule saved for Grade $_selectedGrade');
    } catch (e) {
      debugPrint('Save daily defaults error: $e');
      if (mounted) TatvaSnackbar.show(context, 'Failed to save');
    }
    if (mounted) setState(() => _dailyDefaultsSaving = false);
  }

  void _showEditDailySlotSheet(int index) {
    final slot = _dailyDefaultSlots[index];
    final startCtrl = TextEditingController(text: slot['startTime'] as String? ?? '');
    final endCtrl = TextEditingController(text: slot['endTime'] as String? ?? '');
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Edit ${slot['subject']} Timing',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900)),
            const SizedBox(height: 4),
            Text('Applies to all days for Grade $_selectedGrade',
                style: const TextStyle(fontSize: 12, color: TatvaColors.neutral400)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.neutral400)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: startCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'HH:MM',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              )),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.neutral400)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: endCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'HH:MM',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              )),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final updated = Map<String, dynamic>.from(slot);
                  updated['startTime'] = startCtrl.text.trim();
                  updated['endTime'] = endCtrl.text.trim();
                  setState(() => _dailyDefaultSlots[index] = updated);
                  Navigator.pop(context);
                  _saveDailyDefaults();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TatvaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildDailyDefaultsSection() {
    final grade = _selectedGrade;
    if (!_dailyDefaultsLoaded || _dailyDefaultsGrade != grade) {
      if (_dailyDefaultsGrade != grade) _dailyDefaultsLoaded = false;
      Future.microtask(_loadDailyDefaults);
      return const SizedBox.shrink();
    }
    if (_dailyDefaultSlots.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.schedule_rounded, size: 16, color: TatvaColors.neutral400),
        const SizedBox(width: 6),
        Text('Daily Activities — Grade $grade',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
        const Spacer(),
        if (_dailyDefaultsSaving)
          const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5)),
      ]),
      const SizedBox(height: 4),
      Text('Yoga & Lunch Break times for Grade $grade students',
          style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
      const SizedBox(height: 10),
      ...List.generate(_dailyDefaultSlots.length, (i) {
        final slot = _dailyDefaultSlots[i];
        final subj = slot['subject'] as String? ?? '';
        final st = slot['startTime'] as String? ?? '';
        final et = slot['endTime'] as String? ?? '';
        final isYoga = subj == 'Yoga';
        final c = isYoga ? TatvaColors.accent : TatvaColors.success;
        final icon = isYoga ? Icons.self_improvement_rounded : Icons.restaurant_rounded;
        return GestureDetector(
          onTap: () => _showEditDailySlotSheet(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: c.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subj, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c)),
                  Text('$st – $et', style: const TextStyle(fontSize: 12, color: TatvaColors.neutral400)),
                ],
              )),
              Icon(Icons.edit_rounded, size: 16, color: c.withOpacity(0.4)),
            ]),
          ),
        );
      }),
    ]);
  }

  // ─── TIMETABLE EDITOR (existing) ──────────────────────────────────────────

  Widget _buildTimetableEditor() {
    if (!_calLoaded && !_calLoading) {
      _calWeekStart = _mondayOf(DateTime.now());
      Future.microtask(_loadCalendar);
    }
    final gsMap = _schedGsMap;

    final dayCalPeriods = _calPeriods
        .where((p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay)
        .toList();
    dayCalPeriods.sort((a, b) =>
        (a['startTime'] as String? ?? '').compareTo(b['startTime'] as String? ?? ''));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your classes',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TatvaColors.neutral400)),
      const SizedBox(height: 8),
      if (widget.classes.isEmpty)
        Text('No classes assigned',
            style: TextStyle(
fontSize: 12, color: Colors.grey.shade400))
      else
        Wrap(spacing: 6, runSpacing: 6, children: widget.classes.map((cls) {
          final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success];
          final c = colors[cls.subject.hashCode.abs() % colors.length];
          final parts = cls.name.split('—').map((s) => s.trim()).toList();
          final gradeLabel = parts.isNotEmpty ? parts[0] : cls.name;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(cls.subject,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: c)),
              const SizedBox(width: 4),
              Text(gradeLabel,
                  style: TextStyle(
                      fontSize: 10,
                      color: c.withOpacity(0.6))),
            ]),
          );
        }).toList()),
      const SizedBox(height: 16),
      Row(
        children: List.generate(5, (i) {
          final day = i + 1;
          final isActive = day == _tSchedDay;
          final dayCount = _calPeriods
              .where((p) => (p['dayOfWeek'] as num?)?.toInt() == day)
              .length;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tSchedDay = day),
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: isActive ? TatvaColors.primary : TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isActive ? TatvaColors.primary : Colors.grey.shade200)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(ScheduleModel.dayNames[day],
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : TatvaColors.neutral400)),
                  if (dayCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.2) : TatvaColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('$dayCount',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : TatvaColors.primary)),
                    ),
                ]),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Text(ScheduleModel.dayNamesFull[_tSchedDay],
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TatvaColors.neutral900)),
        const Spacer(),
        Text('${dayCalPeriods.length} period${dayCalPeriods.length == 1 ? '' : 's'}',
            style: const TextStyle(
fontSize: 12, color: TatvaColors.neutral400)),
      ]),
      const SizedBox(height: 12),
      if (_calLoading && !_calLoaded)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2)))
      else if (dayCalPeriods.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Column(children: [
              Icon(Icons.event_available_rounded, size: 32, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('No classes on ${ScheduleModel.dayNamesFull[_tSchedDay]}',
                  style: TextStyle(
fontSize: 13, color: Colors.grey.shade400)),
              const SizedBox(height: 4),
              Text('Tap + to add a class',
                  style: TextStyle(
fontSize: 11, color: Colors.grey.shade300)),
            ]),
          ),
        )
      else
        ...dayCalPeriods.map((p) {
          final subj = p['subject'] as String? ?? '';
          final grade = p['grade'] as String? ?? '';
          final section = p['section'] as String? ?? '';
          final st = p['startTime'] as String? ?? '';
          final et = p['endTime'] as String? ?? '';
          final classId = p['classId'] as String? ?? '';
          final teacherName = p['teacherName'] as String? ?? '';
          final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success];
          final c = colors[subj.hashCode.abs() % colors.length];

          final edWs = _mondayOf(_calWeekStart);
          final edDayDate = edWs.add(Duration(days: _tSchedDay - 1));
          final edDateStr = _dateStr(edDayDate);
          final edCancelled = _calCancellations.any((cn) =>
              cn['grade'] == grade &&
              cn['section'] == section &&
              cn['date'] == edDateStr &&
              cn['startTime'] == st);

          final gsKey = gsMap.keys.cast<String?>().firstWhere((k) {
            final m = gsMap[k];
            return m != null && m['grade'] == grade && m['section'] == section;
          }, orElse: () => null);

          return GestureDetector(
            onTap: gsKey != null ? () {
              _tSchedSelectedGS = gsKey;
              _tSchedLoaded = false;
              Future.microtask(() async {
                await _loadTeacherSchedule();
                if (!mounted) return;
                final daySchedule = _tSchedData
                    .where((s) => s.dayOfWeek == _tSchedDay)
                    .toList();
                final periods = daySchedule.isNotEmpty
                    ? daySchedule.first.periods
                    : <PeriodSlot>[];
                final idx = periods.indexWhere(
                    (ps) => ps.startTime == st && ps.classId == classId);
                if (idx >= 0) {
                  _editPeriodSlot(periods[idx], idx, _tSchedDay,
                      gsKey, gsMap, periods);
                }
              });
            } : null,
            child: Opacity(
              opacity: edCancelled ? 0.5 : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: edCancelled ? Colors.grey.shade50 : TatvaColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: edCancelled ? Colors.grey.shade200 : c.withOpacity(0.15))),
                child: Row(children: [
                  Container(
                    width: 4, height: 42,
                    decoration: BoxDecoration(
                        color: edCancelled ? Colors.grey.shade300 : c,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$st - $et',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TatvaColors.neutral400,
                                decoration: edCancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                      ]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(subj,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: edCancelled ? Colors.grey : c,
                                      decoration: edCancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                            ),
                            if (edCancelled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: TatvaColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text('Cancelled',
                                    style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.error)),
                              ),
                            ],
                          ]),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: c.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('$grade-$section',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: c.withOpacity(0.7))),
                            ),
                            if (teacherName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(teacherName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: TatvaColors.neutral400)),
                              ),
                            ],
                          ]),
                        ]),
                  ),
                  Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade300),
                ]),
              ),
            ),
          );
        }),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => _showAddPeriodSheet(gsMap),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: TatvaColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TatvaColors.primary.withOpacity(0.15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, color: TatvaColors.primary, size: 18),
            const SizedBox(width: 6),
            Text('Add Period',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TatvaColors.primary)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
      _buildDailyDefaultsSection(),
      const SizedBox(height: 24),
    ]);
  }

  void _showAddPeriodSheet(Map<String, Map<String, String>> gsMap) {
    String selectedClassId = '';
    String selectedSubject = '';
    String selectedTeacher = '';
    String selectedGSKey = gsMap.keys.isNotEmpty ? gsMap.keys.first : '';
    final startCtrl = TextEditingController(
        text: _defaultStartTime(_calPeriods.where(
            (p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay).length));
    final endCtrl = TextEditingController(
        text: _defaultEndTime(_calPeriods.where(
            (p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay).length));

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                    width: 36, height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Period — ${ScheduleModel.dayNamesFull[_tSchedDay]}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                const SizedBox(height: 4),
                const Text('Select a class and time for this period',
                    style: TextStyle(
fontSize: 12, color: TatvaColors.neutral400)),
                const SizedBox(height: 20),
                const Text('Select Class',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 8),
                ...widget.classes.map((cls) {
                  final isSelected = cls.id == selectedClassId;
                  final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success];
                  final c = colors[cls.subject.hashCode.abs() % colors.length];
                  final parts = cls.name.split('—').map((s) => s.trim()).toList();
                  final gradeLabel = parts.isNotEmpty ? parts[0] : cls.name;
                  final clsGSKey = gsMap.keys.cast<String?>().firstWhere((k) {
                    final m = gsMap[k];
                    if (m == null) return false;
                    return cls.name.contains(m['grade']!) &&
                        cls.name.toLowerCase().contains('section ${m['section']!.toLowerCase()}');
                  }, orElse: () => null);
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      selectedClassId = cls.id;
                      selectedSubject = cls.subject;
                      selectedTeacher = cls.teacherName;
                      if (clsGSKey != null) selectedGSKey = clsGSKey;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSelected ? c.withOpacity(0.08) : TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? c : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: isSelected ? c : Colors.grey.shade300,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.subject,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? c : TatvaColors.neutral900)),
                              Text('$gradeLabel  ·  ${cls.teacherName}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? c.withOpacity(0.6) : TatvaColors.neutral400)),
                            ])),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: c, size: 18),
                      ]),
                    ),
                  );
                }),
                if (gsMap.length > 1 && selectedClassId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('For Grade',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral400)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButton<String>(
                      value: gsMap.containsKey(selectedGSKey) ? selectedGSKey : gsMap.keys.first,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                      items: gsMap.keys
                          .map((gs) => DropdownMenuItem(
                              value: gs,
                              child: Text(gs,
                                  style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => selectedGSKey = v);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Time',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(
                    controller: startCtrl,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _scheduleFieldDecor('Start', '08:00'),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to',
                        style: TextStyle(
fontSize: 13, color: TatvaColors.neutral400)),
                  ),
                  Expanded(child: TextField(
                    controller: endCtrl,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _scheduleFieldDecor('End', '08:45'),
                  )),
                ]),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: selectedClassId.isEmpty ? null : () async {
                    final gs = gsMap[selectedGSKey];
                    if (gs == null) return;
                    try {
                      final raw = await _api.getSchedule(gs['grade']!, gs['section']!);
                      final schedules = raw.map((m) => ScheduleModel.fromJson(m)).toList();
                      final daySchedule = schedules
                          .where((s) => s.dayOfWeek == _tSchedDay)
                          .toList();
                      final existingPeriods = daySchedule.isNotEmpty
                          ? daySchedule.first.periods
                          : <PeriodSlot>[];
                      final newSlot = PeriodSlot(
                        period: existingPeriods.length + 1,
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        classId: selectedClassId,
                        subject: selectedSubject,
                        teacherName: selectedTeacher,
                      );
                      final updated = [...existingPeriods, newSlot];
                      await _api.upsertSchedule(
                        grade: gs['grade']!,
                        section: gs['section']!,
                        dayOfWeek: _tSchedDay,
                        periods: updated.map((p) => p.toJson()).toList(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _calLoaded = false;
                      _loadCalendar();
                      TatvaSnackbar.show(context, 'Period added!');
                    } catch (e) {
                      debugPrint('Add period error: $e');
                      TatvaSnackbar.show(context, 'Failed to add period');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        color: selectedClassId.isEmpty
                            ? Colors.grey.shade300
                            : TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selectedClassId.isEmpty ? [] : [
                          BoxShadow(
                              color: TatvaColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Center(
                        child: Text('Add Period',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                ),
              ],
            )),
          ),
        );
      }),
    );
  }

  void _showAddEventSheet(DateTime weekStart) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String startTime = '09:00';
    String endTime = '10:00';
    String eventType = 'event';
    bool cancels = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28))),
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
                  const SizedBox(height: 16),
                  const Text('Add Special Event',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900)),
                  const SizedBox(height: 16),
                  const Text('Type',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral400)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _eventTypeChip('event', 'Special Event', Icons.event_outlined,
                        TatvaColors.accent, eventType, (v) => setModal(() => eventType = v)),
                    _eventTypeChip('ptm', 'PTM', Icons.people_outline,
                        TatvaColors.purple, eventType, (v) => setModal(() => eventType = v)),
                    _eventTypeChip('override', 'Override', Icons.swap_horiz_rounded,
                        TatvaColors.info, eventType, (v) => setModal(() => eventType = v)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _hwFieldDecor('Event title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _hwFieldDecor('Description (optional)'),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx2, child) => Theme(
                          data: Theme.of(ctx2).copyWith(
                              colorScheme:
                                  ColorScheme.light(primary: TatvaColors.accent)),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModal(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: TatvaColors.neutral400),
                        const SizedBox(width: 8),
                        Text(_dateStr(selectedDate),
                            style: const TextStyle(
                                fontSize: 14,
                                color: TatvaColors.neutral900)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: int.tryParse(startTime.split(':')[0]) ?? 9,
                                minute: int.tryParse(startTime.split(':')[1]) ?? 0),
                          );
                          if (t != null) {
                            setModal(() => startTime =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade200)),
                          child: Row(children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: TatvaColors.neutral400),
                            const SizedBox(width: 6),
                            Text(startTime,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: TatvaColors.neutral900)),
                          ]),
                        ),
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('—',
                            style: TextStyle(color: TatvaColors.neutral400))),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: int.tryParse(endTime.split(':')[0]) ?? 10,
                                minute: int.tryParse(endTime.split(':')[1]) ?? 0),
                          );
                          if (t != null) {
                            setModal(() => endTime =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade200)),
                          child: Row(children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: TatvaColors.neutral400),
                            const SizedBox(width: 6),
                            Text(endTime,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: TatvaColors.neutral900)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => setModal(() => cancels = !cancels),
                    child: Row(children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: cancels
                                ? TatvaColors.error
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: cancels
                                    ? TatvaColors.error
                                    : Colors.grey.shade300)),
                        child: cancels
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text(
                              'Cancels regular classes for the day',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: TatvaColors.neutral900))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      await _api.createScheduleEvent(
                        title: title,
                        date: _dateStr(selectedDate),
                        description: descCtrl.text.trim(),
                        startTime: startTime,
                        endTime: endTime,
                        type: eventType,
                        cancelsRegularSchedule: cancels,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _calLoaded = false;
                      _loadCalendar();
                      widget.onRefresh?.call();
                      TatvaSnackbar.show(context, 'Event added!');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: TatvaColors.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: TatvaColors.accent.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: const Center(
                          child: Text('Add Event',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventTypeChip(String type, String label, IconData icon, Color c,
      String current, ValueChanged<String> onTap) {
    final active = type == current;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: active ? c.withOpacity(0.12) : TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? c : Colors.grey.shade200, width: active ? 1.5 : 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? c : TatvaColors.neutral400),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? c : TatvaColors.neutral400)),
        ]),
      ),
    );
  }

  void _editPeriodSlot(
      PeriodSlot slot, int index, int dayOfWeek, String selectedGS,
      Map<String, Map<String, String>> gsMap, List<PeriodSlot> allPeriods) {
    final startCtrl = TextEditingController(text: slot.startTime);
    final endCtrl = TextEditingController(text: slot.endTime);
    String selectedClassId = slot.classId;
    String selectedSubject = slot.subject;
    String selectedTeacher = slot.teacherName;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final gs = gsMap[selectedGS];
        final gradeLabel = gs != null ? 'Grade ${gs['grade']}-${gs['section']}' : selectedGS;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                    width: 36, height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Edit Period — $gradeLabel',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                const SizedBox(height: 4),
                Text('${ScheduleModel.dayNamesFull[dayOfWeek]}, ${slot.startTime} – ${slot.endTime}',
                    style: const TextStyle(
fontSize: 12, color: TatvaColors.neutral400)),
                const SizedBox(height: 20),
                const Text('Class',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 8),
                ...widget.classes.map((cls) {
                  final isSelected = cls.id == selectedClassId;
                  final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success];
                  final c = colors[cls.subject.hashCode.abs() % colors.length];
                  final parts = cls.name.split('—').map((s) => s.trim()).toList();
                  final clsGrade = parts.isNotEmpty ? parts[0] : cls.name;
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      selectedClassId = cls.id;
                      selectedSubject = cls.subject;
                      selectedTeacher = cls.teacherName;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSelected ? c.withOpacity(0.08) : TatvaColors.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? c : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: isSelected ? c : Colors.grey.shade300,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.subject,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? c : TatvaColors.neutral900)),
                              Text('$clsGrade  ·  ${cls.teacherName}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? c.withOpacity(0.6) : TatvaColors.neutral400)),
                            ])),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: c, size: 18),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text('Time',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(
                    controller: startCtrl,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _scheduleFieldDecor('Start', '08:00'),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to',
                        style: TextStyle(
fontSize: 13, color: TatvaColors.neutral400)),
                  ),
                  Expanded(child: TextField(
                    controller: endCtrl,
                    style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _scheduleFieldDecor('End', '08:45'),
                  )),
                ]),
                const SizedBox(height: 16),
                Builder(builder: (_) {
                  final gsData = gsMap[selectedGS];
                  final pGrade = gsData?['grade'] ?? '';
                  final pSection = gsData?['section'] ?? '';
                  final ws = _mondayOf(_calWeekStart);
                  final dayDate = ws.add(Duration(days: dayOfWeek - 1));
                  final dayName = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dayDate.weekday];
                  final dateStr = _dateStr(dayDate);
                  final alreadyCancelled = _calCancellations.any((cn) =>
                      cn['grade'] == pGrade &&
                      cn['section'] == pSection &&
                      cn['date'] == dateStr &&
                      cn['startTime'] == slot.startTime);
                  if (alreadyCancelled) {
                    final cId = _calCancellations.firstWhere((cn) =>
                        cn['grade'] == pGrade &&
                        cn['section'] == pSection &&
                        cn['date'] == dateStr &&
                        cn['startTime'] == slot.startTime)['id'] as String? ?? '';
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        if (cId.isEmpty) return;
                        try {
                          await _api.undoCancelPeriod(cId);
                          _calLoaded = false;
                          _loadCalendar();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: TatvaColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TatvaColors.success.withOpacity(0.25))),
                        child: Center(
                            child: Text('Restore — Cancelled for $dayName, ${_monthName(dayDate.month)} ${dayDate.day}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: TatvaColors.success))),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await _api.cancelPeriod(
                          grade: pGrade,
                          section: pSection,
                          date: dateStr,
                          startTime: slot.startTime,
                          classId: slot.classId,
                        );
                        _calLoaded = false;
                        _loadCalendar();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: TatvaColors.error.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TatvaColors.error.withOpacity(0.2))),
                      child: Center(
                          child: Text('Cancel for $dayName, ${_monthName(dayDate.month)} ${dayDate.day}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.error))),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<PeriodSlot>.from(allPeriods);
                        if (index < updated.length) updated.removeAt(index);
                        for (var i = 0; i < updated.length; i++) {
                          updated[i] = PeriodSlot(
                            period: i + 1,
                            startTime: updated[i].startTime,
                            endTime: updated[i].endTime,
                            classId: updated[i].classId,
                            subject: updated[i].subject,
                            teacherName: updated[i].teacherName,
                          );
                        }
                        Navigator.pop(context);
                        _saveScheduleDay(
                            gsMap[selectedGS]!, dayOfWeek, updated);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            color: TatvaColors.error.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: TatvaColors.error.withOpacity(0.2))),
                        child: Center(
                            child: Text('Remove',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.error))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<PeriodSlot>.from(allPeriods);
                        final newSlot = PeriodSlot(
                          period: slot.period,
                          startTime: startCtrl.text.trim(),
                          endTime: endCtrl.text.trim(),
                          classId: selectedClassId,
                          subject: selectedSubject,
                          teacherName: selectedTeacher,
                        );
                        if (index < updated.length) {
                          updated[index] = newSlot;
                        } else {
                          updated.add(newSlot);
                        }
                        Navigator.pop(context);
                        _saveScheduleDay(
                            gsMap[selectedGS]!, dayOfWeek, updated);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            color: TatvaColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: TatvaColors.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ]),
                        child: const Center(
                            child: Text('Save',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                      ),
                    ),
                  ),
                ]),
              ],
            )),
          ),
        );
      }),
    );
  }

  InputDecoration _scheduleFieldDecor(String label, String hint) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
fontSize: 12, color: TatvaColors.neutral400),
        hintText: hint,
        hintStyle: TextStyle(
fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
      );

  void _saveScheduleDay(
      Map<String, String> gs, int dayOfWeek, List<PeriodSlot> periods) async {
    try {
      await _api.upsertSchedule(
        grade: gs['grade']!,
        section: gs['section']!,
        dayOfWeek: dayOfWeek,
        periods: periods.map((p) => p.toJson()).toList(),
      );
      _calLoaded = false;
      _loadCalendar();
      TatvaSnackbar.show(context, 'Schedule saved');
    } catch (e) {
      debugPrint('Save schedule error: $e');
      TatvaSnackbar.show(context, 'Failed to save schedule');
    }
  }

  String _defaultStartTime(int index) {
    final hour = 8 + (index * 50) ~/ 60;
    final minute = (index * 50) % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _defaultEndTime(int index) {
    final startMinutes = 8 * 60 + index * 50;
    final endMinutes = startMinutes + 45;
    final hour = endMinutes ~/ 60;
    final minute = endMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  int _toMin(String t) {
    final p = t.split(':');
    return (int.tryParse(p[0]) ?? 8) * 60 +
        (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  List<Widget> _buildDayStackItems({
    required List<Map<String, dynamic>> dayPeriods,
    required bool dayCancelled,
    required DateTime dateOfDay,
    required double hourHeight,
    required int startHour,
  }) {
    if (dayCancelled) {
      final timedEvts = _calEvents
          .where((ev) =>
              ev['date'] == _dateStr(dateOfDay) &&
              (ev['startTime'] as String? ?? '').isNotEmpty)
          .toList();
      return [
        Positioned.fill(
          child: Container(
            decoration:
                BoxDecoration(color: TatvaColors.error.withOpacity(0.03)),
            child: Center(
                child: Text('Cancelled',
                    style: TextStyle(
                        fontSize: 10,
                        color: TatvaColors.error.withOpacity(0.3)))),
          ),
        ),
        ..._positionItems(
            timedEvts
                .map((ev) => _DayItem.event(
                    ev,
                    _toMin(ev['startTime'] as String),
                    _toMin(ev['endTime'] as String? ?? '10:00')))
                .toList(),
            dateOfDay,
            hourHeight,
            startHour),
      ];
    }

    final items = <_DayItem>[];
    for (final p in dayPeriods) {
      items.add(_DayItem.period(
          p,
          _toMin(p['startTime'] as String? ?? '08:00'),
          _toMin(p['endTime'] as String? ?? '08:45')));
    }
    for (final ev in _calEvents) {
      if (ev['date'] != _dateStr(dateOfDay)) continue;
      final st = ev['startTime'] as String? ?? '';
      if (st.isEmpty) continue;
      items.add(_DayItem.event(
          ev, _toMin(st), _toMin(ev['endTime'] as String? ?? '10:00')));
    }
    return _positionItems(items, dateOfDay, hourHeight, startHour);
  }

  List<Widget> _positionItems(List<_DayItem> items, DateTime dateOfDay,
      double hourHeight, int startHour) {
    if (items.isEmpty) return [];
    final n = items.length;
    final starts = items.map((i) => i.startMin).toList();
    final ends = items.map((i) => i.endMin).toList();

    final cols = List.filled(n, 0);
    final colEnds = <int>[];
    final order = List.generate(n, (i) => i)
      ..sort((a, b) => starts[a].compareTo(starts[b]));
    for (final i in order) {
      int c = -1;
      for (int j = 0; j < colEnds.length; j++) {
        if (colEnds[j] <= starts[i]) {
          c = j;
          break;
        }
      }
      if (c == -1) {
        c = colEnds.length;
        colEnds.add(0);
      }
      cols[i] = c;
      colEnds[c] = ends[i];
    }
    final totalCols = List.filled(n, 1);
    for (int i = 0; i < n; i++) {
      int mx = cols[i];
      for (int j = 0; j < n; j++) {
        if (i != j &&
            starts[i] < ends[j] &&
            starts[j] < ends[i] &&
            cols[j] > mx) mx = cols[j];
      }
      totalCols[i] = mx + 1;
    }

    return List.generate(n, (i) {
      final item = items[i];
      final top = (item.startMin - startHour * 60) * hourHeight / 60;
      final height =
          ((item.endMin - item.startMin) * hourHeight / 60).clamp(20.0, double.infinity);
      final col = cols[i];
      final total = totalCols[i];

      Widget content;
      String tipMsg;

      if (item.isPeriod) {
        final p = item.data;
        final subj = p['subject'] as String? ?? '';
        final grade = p['grade'] as String? ?? '';
        final section = p['section'] as String? ?? '';
        final st = p['startTime'] as String? ?? '';
        final et = p['endTime'] as String? ?? '';
        final teacher = p['teacherName'] as String? ?? '';

        const palette = [
          TatvaColors.primary, TatvaColors.info, TatvaColors.accent,
          TatvaColors.purple, TatvaColors.success
        ];
        final c = palette[subj.hashCode.abs() % palette.length];
        final ds = _dateStr(dateOfDay);
        final isCancelled = _calCancellations.any((cn) =>
            cn['grade'] == grade &&
            cn['section'] == section &&
            cn['date'] == ds &&
            cn['startTime'] == st);
        final cancelId = isCancelled
            ? (_calCancellations.firstWhere((cn) =>
                    cn['grade'] == grade &&
                    cn['section'] == section &&
                    cn['date'] == ds &&
                    cn['startTime'] == st)['id']
                as String? ??
                '')
            : '';
        final gsKey = _schedGsMap.keys.cast<String?>().firstWhere((k) {
          final m = _schedGsMap[k];
          return m != null && m['grade'] == grade && m['section'] == section;
        }, orElse: () => null);

        tipMsg =
            '$subj\n$st – $et\n$grade-$section${teacher.isNotEmpty ? '\n$teacher' : ''}${isCancelled ? '\n(Cancelled)' : ''}';

        content = GestureDetector(
          onTap: () {
            if (isCancelled) {
              _showUndoCancelSheet(cancelId, subj, grade, section, ds);
            } else {
              _showPeriodCancelSheet(p, dateOfDay, gsKey);
            }
          },
          child: Opacity(
            opacity: isCancelled ? 0.45 : 1.0,
            child: Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: isCancelled
                      ? Colors.grey.shade200
                      : c.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: isCancelled
                          ? Colors.grey.shade300
                          : c.withOpacity(0.3))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isCancelled ? '$subj ✕' : subj,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isCancelled ? Colors.grey : c,
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : TextDecoration.none)),
                    if (height > 28)
                      Text(
                          isCancelled ? 'Cancelled' : '$grade-$section',
                          style: TextStyle(
                              fontSize: 8,
                              color: isCancelled
                                  ? TatvaColors.error.withOpacity(0.7)
                                  : c.withOpacity(0.7))),
                  ]),
            ),
          ),
        );
      } else {
        final ev = item.data;
        final title = ev['title'] as String? ?? '';
        final st = ev['startTime'] as String? ?? '';
        final et = ev['endTime'] as String? ?? '';
        final evType = ev['type'] as String? ?? 'event';
        final desc = ev['description'] as String? ?? '';

        tipMsg =
            '$title\n$st – $et${evType != 'event' ? '\n${evType[0].toUpperCase()}${evType.substring(1)}' : ''}${desc.isNotEmpty ? '\n$desc' : ''}';

        content = Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: TatvaColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: TatvaColors.accent.withOpacity(0.4), width: 1.5)),
          child: Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.accent)),
        );
      }

      return Positioned(
        top: top.clamp(0, double.infinity),
        left: 0,
        right: 0,
        height: height,
        child: Row(children: [
          if (col > 0) Spacer(flex: col),
          Expanded(
            child: Tooltip(
              message: tipMsg,
              preferBelow: false,
              verticalOffset: 12,
              decoration: BoxDecoration(
                color: TatvaColors.neutral900.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                  fontSize: 11, color: Colors.white, height: 1.4),
              child: content,
            ),
          ),
          if (col + 1 < total) Spacer(flex: total - col - 1),
        ]),
      );
    });
  }

  InputDecoration _hwFieldDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: TatvaColors.accent.withOpacity(0.5), width: 1.5)),
      );

  // ─── Holidays Manager ─────────────────────────────────────────────

  int get _schoolYear {
    final now = DateTime.now();
    return now.month >= 8 ? now.year + 1 : now.year;
  }

  Future<void> _loadHolidays() async {
    if (_holidaysLoading) return;
    setState(() => _holidaysLoading = true);
    try {
      final raw = await _api.getHolidays(_schoolYear);
      _holidays = raw.map((m) => Holiday.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Holidays load error: $e');
      _holidays = [];
    }
    if (mounted) setState(() { _holidaysLoading = false; _holidaysLoaded = true; });
  }

  Future<void> _loadSchoolDates() async {
    try {
      final data = await _api.getSchoolYearDates(_schoolYear);
      if (mounted) setState(() {
        _firstDay = data['firstDay'] as String? ?? '';
        _lastDay = data['lastDay'] as String? ?? '';
        _schoolDatesLoaded = true;
      });
    } catch (e) {
      debugPrint('School dates load error: $e');
      if (mounted) setState(() => _schoolDatesLoaded = true);
    }
  }

  Future<void> _pickSchoolDate(bool isFirst) async {
    final initial = DateTime.tryParse(isFirst ? _firstDay : _lastDay) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 1, 7),
      lastDate: DateTime(DateTime.now().year + 2, 8),
    );
    if (picked == null) return;
    final dateStr = _dateStr(picked);
    setState(() {
      if (isFirst) _firstDay = dateStr; else _lastDay = dateStr;
    });
    try {
      await _api.setSchoolYearDates(year: _schoolYear, firstDay: _firstDay, lastDay: _lastDay);
    } catch (e) {
      debugPrint('Save school dates error: $e');
    }
  }

  Widget _buildHolidaysManager() {
    if (!_holidaysLoaded && !_holidaysLoading) {
      Future.microtask(_loadHolidays);
    }
    if (!_schoolDatesLoaded) {
      Future.microtask(_loadSchoolDates);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('School Year ${_schoolYear - 1}–$_schoolYear',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
        ),
        _addHolidayButton(),
      ]),
      const SizedBox(height: 16),
      _schoolDatesRow(),
      const SizedBox(height: 16),
      if (_holidaysLoading && !_holidaysLoaded)
        const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
      else if (_holidays.isEmpty)
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.beach_access_outlined, color: TatvaColors.neutral400, size: 48),
              const SizedBox(height: 12),
              const Text('No holidays defined yet', style: TextStyle(fontSize: 15, color: TatvaColors.neutral400)),
              const SizedBox(height: 4),
              const Text('Tap + to add holidays for this school year',
                  style: TextStyle(fontSize: 12, color: TatvaColors.neutral400)),
            ]),
          ),
        )
      else
        ..._holidays.asMap().entries.map((entry) {
          final i = entry.key;
          final h = entry.value;
          return FadeSlideIn(
            delayMs: i * 40,
            child: _holidayCard(h),
          );
        }),
      const SizedBox(height: 24),
    ]);
  }

  Widget _schoolDatesRow() {
    String fmtDisplay(String dateStr) {
      final d = DateTime.tryParse(dateStr);
      if (d == null) return 'Not set';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TatvaColors.primary.withOpacity(0.2))),
      child: Row(children: [
        Expanded(child: _schoolDateTile('First Day of School', _firstDay, fmtDisplay(_firstDay), () => _pickSchoolDate(true))),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(child: _schoolDateTile('Last Day of School', _lastDay, fmtDisplay(_lastDay), () => _pickSchoolDate(false))),
      ]),
    );
  }

  Widget _schoolDateTile(String label, String value, String display, VoidCallback onTap) {
    final isSet = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: TatvaColors.neutral400)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.calendar_today_outlined, size: 13,
                color: isSet ? TatvaColors.primary : TatvaColors.neutral400),
            const SizedBox(width: 6),
            Text(display, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isSet ? TatvaColors.neutral900 : TatvaColors.neutral400)),
          ]),
        ]),
      ),
    );
  }

  Widget _addHolidayButton() {
    return GestureDetector(
      onTap: () => _showHolidayForm(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: TatvaColors.primary, borderRadius: BorderRadius.circular(10)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text('Add Holiday', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
      ),
    );
  }

  Widget _holidayCard(Holiday h) {
    final c = h.typeColor;
    final startParsed = DateTime.tryParse(h.startDate);
    final endParsed = DateTime.tryParse(h.endDate);
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    String dateLabel = '';
    if (startParsed != null) {
      dateLabel = '${months[startParsed.month - 1]} ${startParsed.day}';
      if (endParsed != null && h.isMultiDay) {
        dateLabel += ' – ${months[endParsed.month - 1]} ${endParsed.day}';
        dateLabel += '  (${h.durationDays} days)';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: c.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.18))),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(h.typeIcon, size: 20, color: c),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
            const SizedBox(height: 2),
            Text(dateLabel, style: const TextStyle(fontSize: 12, color: TatvaColors.neutral400)),
            if (h.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(h.description, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(h.typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 18, color: TatvaColors.neutral400),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (v) {
            if (v == 'edit') _showHolidayForm(existing: h);
            if (v == 'delete') _confirmDeleteHoliday(h);
          },
        ),
      ]),
    );
  }

  void _confirmDeleteHoliday(Holiday h) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Delete "${h.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.deleteHoliday(h.id);
                _holidaysLoaded = false;
                _calLoaded = false;
                _loadHolidays();
                _loadCalendar();
                widget.onRefresh?.call();
                if (mounted) TatvaSnackbar.success(context, 'Holiday deleted');
              } catch (e) {
                if (mounted) TatvaSnackbar.error(context, 'Failed to delete');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showHolidayForm({Holiday? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String selectedType = existing?.type ?? 'custom';
    DateTime startDate = DateTime.tryParse(existing?.startDate ?? '') ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(existing?.endDate ?? '') ?? DateTime.now();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        String fmtDate(DateTime d) =>
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        String fmtDisplay(DateTime d) {
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return '${months[d.month - 1]} ${d.day}, ${d.year}';
        }

        Future<void> pickDate(bool isStart) async {
          final picked = await showDatePicker(
            context: ctx,
            initialDate: isStart ? startDate : endDate,
            firstDate: DateTime(DateTime.now().year - 1),
            lastDate: DateTime(DateTime.now().year + 2),
          );
          if (picked != null) {
            setSheet(() {
              if (isStart) {
                startDate = picked;
                if (endDate.isBefore(startDate)) endDate = startDate;
              } else {
                endDate = picked;
              }
            });
          }
        }

        Future<void> save() async {
          final name = nameCtrl.text.trim();
          if (name.isEmpty) return;
          setSheet(() => saving = true);
          try {
            final desc = descCtrl.text.trim();
            if (existing != null) {
              await _api.updateHoliday(existing.id,
                  name: name, startDate: fmtDate(startDate), endDate: fmtDate(endDate),
                  type: selectedType, description: desc);
            } else {
              await _api.createHoliday(
                  name: name, startDate: fmtDate(startDate), endDate: fmtDate(endDate),
                  type: selectedType, description: desc);
              for (var d = startDate; !d.isAfter(endDate); d = d.add(const Duration(days: 1))) {
                await _api.createScheduleEvent(
                  title: name, date: fmtDate(d), type: 'holiday',
                  description: desc, cancelsRegularSchedule: true,
                );
              }
            }
            if (ctx.mounted) Navigator.pop(ctx);
            _holidaysLoaded = false;
            _calLoaded = false;
            _loadHolidays();
            _loadCalendar();
            widget.onRefresh?.call();
            if (mounted) TatvaSnackbar.success(context, existing != null ? 'Holiday updated' : 'Holiday added');
          } catch (e) {
            setSheet(() => saving = false);
            if (mounted) TatvaSnackbar.error(context, 'Failed to save');
          }
        }

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(existing != null ? 'Edit Holiday' : 'Add Holiday',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TatvaColors.neutral900)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: _hwFieldDecor('Holiday name'),
                style: const TextStyle(fontSize: 14, color: TatvaColors.neutral900),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              const Text('Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: Holiday.typeKeys.map((t) {
                final active = selectedType == t;
                final c = Holiday.typeColors[t]!;
                return GestureDetector(
                  onTap: () => setSheet(() => selectedType = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: active ? c.withOpacity(0.15) : TatvaColors.bgLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? c : Colors.grey.shade200)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Holiday.typeIcons[t], size: 14, color: active ? c : TatvaColors.neutral400),
                      const SizedBox(width: 6),
                      Text(Holiday.typeLabels[t]!, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: active ? c : TatvaColors.neutral400)),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Start Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgLight, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: TatvaColors.neutral400),
                        const SizedBox(width: 8),
                        Text(fmtDisplay(startDate), style: const TextStyle(fontSize: 13, color: TatvaColors.neutral900)),
                      ]),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('End Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgLight, borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: TatvaColors.neutral400),
                        const SizedBox(width: 8),
                        Text(fmtDisplay(endDate), style: const TextStyle(fontSize: 13, color: TatvaColors.neutral900)),
                      ]),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: _hwFieldDecor('Description (optional)'),
                style: const TextStyle(fontSize: 14, color: TatvaColors.neutral900),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: TatvaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(existing != null ? 'Update Holiday' : 'Add Holiday',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ])),
          ),
        );
      }),
    );
  }
}
