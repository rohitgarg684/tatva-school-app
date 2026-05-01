import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/utils/calendar_pdf.dart';
import '../../../models/child_info.dart';
import '../../../models/schedule_model.dart';
import '../../../models/schedule_event.dart';
import '../../../models/holiday.dart';
import '../../../models/class_model.dart';
import '../../../services/api_service.dart';

class ParentScheduleTab extends StatefulWidget {
  final List<ChildDashboardData> childrenData;
  final int selectedChildIndex;
  final ApiService api;

  const ParentScheduleTab({
    super.key,
    required this.childrenData,
    required this.selectedChildIndex,
    required this.api,
  });

  @override
  State<ParentScheduleTab> createState() => _ParentScheduleTabState();
}

class _ParentScheduleTabState extends State<ParentScheduleTab> {
  List<ScheduleModel> _weekData = [];
  List<Map<String, dynamic>> _cancellations = [];
  List<ScheduleEvent> _events = [];
  bool _loading = false;
  bool _loaded = false;
  int _selectedDay = 0;
  int _viewMode = 0; // 0 = schedule, 1 = calendar
  List<Holiday> _holidays = [];
  bool _holidaysLoaded = false;
  DateTime _calMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedCalDate = '';
  String _firstDay = '';
  String _lastDay = '';
  bool _schoolDatesLoaded = false;

  @override
  void didUpdateWidget(ParentScheduleTab old) {
    super.didUpdateWidget(old);
    if (old.selectedChildIndex != widget.selectedChildIndex) {
      _loaded = false;
      _loadData();
    }
  }

  ClassModel? get _currentClass {
    if (widget.childrenData.isEmpty) return null;
    final idx = widget.selectedChildIndex.clamp(0, widget.childrenData.length - 1);
    return widget.childrenData[idx].childClass;
  }

  String _grade() {
    final cls = _currentClass;
    if (cls == null) return '8';
    final match = RegExp(r'(\d+)').firstMatch(cls.name);
    return match?.group(1) ?? '8';
  }

  String _section() {
    final cls = _currentClass;
    if (cls == null) return 'A';
    final match =
        RegExp(r'Section\s*(\w+)', caseSensitive: false).firstMatch(cls.name);
    return match?.group(1) ?? 'A';
  }

  void _loadData() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final ws = DateTime(now.year, now.month, now.day - (now.weekday - 1));
      final we = ws.add(const Duration(days: 4));
      String fmtDate(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        widget.api.getScheduleWithCancellations(_grade(), _section()),
        widget.api.getScheduleEvents(fmtDate(ws), fmtDate(we)),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final raw =
          (data['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _weekData = raw.map((m) => ScheduleModel.fromJson(m)).toList();
      _cancellations =
          (data['cancellations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final evRaw = results[1] as List<Map<String, dynamic>>;
      _events = evRaw.map((m) => ScheduleEvent.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Schedule load error: $e');
      _weekData = [];
      _cancellations = [];
      _events = [];
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loaded = true;
      });
    }
  }

  List<Holiday> get _weekHolidays {
    final now = DateTime.now();
    final ws = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final we = ws.add(const Duration(days: 4));
    final wsStr = _fmtDate(ws);
    final weStr = _fmtDate(we);
    return _holidays
        .where((h) => h.endDate.compareTo(wsStr) >= 0 && h.startDate.compareTo(weStr) <= 0)
        .toList();
  }

  String _dateStr(int dayOfWeek) {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final d = monday.add(Duration(days: dayOfWeek - 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _isPeriodCancelled(int dayOfWeek, String startTime) {
    final dateStr = _dateStr(dayOfWeek);
    return _cancellations
        .any((cn) => cn['date'] == dateStr && cn['startTime'] == startTime);
  }

  int get _schoolYear {
    final now = DateTime.now();
    return now.month >= 8 ? now.year + 1 : now.year;
  }

  void _loadHolidays() async {
    try {
      final raw = await widget.api.getHolidays(_schoolYear);
      if (mounted) setState(() {
        _holidays = raw.map((m) => Holiday.fromJson(m)).toList();
        _holidaysLoaded = true;
      });
    } catch (e) {
      debugPrint('Holidays load error: $e');
      if (mounted) setState(() => _holidaysLoaded = true);
    }
  }

  void _loadSchoolDates() async {
    try {
      final data = await widget.api.getSchoolYearDates(_schoolYear);
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

  bool _isSchoolDay(String dateStr) {
    if (_firstDay.isEmpty && _lastDay.isEmpty) return true;
    if (_firstDay.isNotEmpty && dateStr.compareTo(_firstDay) < 0) return false;
    if (_lastDay.isNotEmpty && dateStr.compareTo(_lastDay) > 0) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded && !_loading) {
      Future.microtask(_loadData);
    }
    if (!_holidaysLoaded) {
      Future.microtask(_loadHolidays);
    }
    if (!_schoolDatesLoaded) {
      Future.microtask(_loadSchoolDates);
    }
    final childName = widget.childrenData.isNotEmpty
        ? widget.childrenData[widget.selectedChildIndex].info.childName
        : '';
    final className = widget.childrenData.isNotEmpty
        ? (widget.childrenData[widget.selectedChildIndex].childClass?.name ??
            '')
        : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: Text("$childName's Schedule",
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text('$className • Schedule & Holidays',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
              color: TatvaColors.bgLight, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _modeBtn('Weekly Schedule', 0),
            _modeBtn('Holiday Calendar', 1),
          ]),
        ),
        const SizedBox(height: 16),
        if (_viewMode == 0) ...[
          Row(
            children: [
              _dayChip('All', _selectedDay == 0,
                  () => setState(() => _selectedDay = 0)),
              ...List.generate(5, (i) {
                final day = i + 1;
                return _dayChip(ScheduleModel.dayNames[day], _selectedDay == day,
                    () => setState(() => _selectedDay = day));
              }),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading && !_loaded)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator()))
          else if (_weekData.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.calendar_today_outlined,
                      color: TatvaColors.neutral400, size: 48),
                  const SizedBox(height: 12),
                  const Text('No schedule set yet',
                      style: TextStyle(
                          fontSize: 15, color: TatvaColors.neutral400)),
                ]),
              ),
            )
          else if (_selectedDay == 0)
            _weekGrid(_weekData)
          else
            _dayDetail(_weekData, _selectedDay),
          if (_visibleEvents.isNotEmpty || _weekHolidays.isNotEmpty) ...[
            const SizedBox(height: 16),
          ],
        ] else
          _buildHolidayCalendar(),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _modeBtn(String label, int mode) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
            color: _viewMode == mode ? TatvaColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10)),
        child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _viewMode == mode ? Colors.white : TatvaColors.neutral400))),
      ),
    ),
  );

  Widget _dayChip(String label, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: isActive ? TatvaColors.primary : TatvaColors.bgCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color:
                      isActive ? TatvaColors.primary : Colors.grey.shade200)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : TatvaColors.neutral400))),
        ),
      ),
    );
  }

  DateTime _weekMonday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1));
  }

  bool _isDayHoliday(int dayOfWeek) {
    final d = _weekMonday().add(Duration(days: dayOfWeek - 1));
    final ds = _fmtDate(d);
    return _weekHolidays.any((h) => h.coversDate(ds));
  }

  List<ScheduleEvent> _eventsForDay(int dayOfWeek) {
    final d = _weekMonday().add(Duration(days: dayOfWeek - 1));
    final ds = _fmtDate(d);
    return _events.where((e) => e.date == ds).toList();
  }

  Widget _weekGrid(List<ScheduleModel> schedules) {
    final allTimes = <String>{};
    for (final s in schedules) {
      for (final p in s.periods) allTimes.add(p.startTime);
    }
    for (final ev in _events) {
      if (ev.startTime.isNotEmpty) allTimes.add(ev.startTime);
    }
    final sorted = allTimes.toList()..sort();

    final colors = [
      TatvaColors.primary,
      TatvaColors.info,
      TatvaColors.accent,
      TatvaColors.purple,
      TatvaColors.success,
      TatvaColors.error
    ];
    final subjectColors = <String, Color>{};
    int ci = 0;
    for (final s in schedules) {
      for (final p in s.periods) {
        if (p.subject.isNotEmpty && !subjectColors.containsKey(p.subject)) {
          subjectColors[p.subject] = colors[ci % colors.length];
          ci++;
        }
      }
    }

    return Column(children: [
      ..._weekHolidays.map(_buildHolidayCard),
      ..._events.where((e) => e.startTime.isEmpty).map(_buildEventCard),
      if (_weekHolidays.isNotEmpty || _events.any((e) => e.startTime.isEmpty))
        const SizedBox(height: 12),
      Row(children: [
        SizedBox(
          width: 52,
          child: Text('Time',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: TatvaColors.neutral400)),
        ),
        ...List.generate(5, (i) {
          final day = i + 1;
          final isToday = DateTime.now().weekday == day;
          final isHoliday = _isDayHoliday(day);
          final headerColor = isHoliday
              ? TatvaColors.error
              : isToday
                  ? TatvaColors.primary
                  : null;
          final d = _weekMonday().add(Duration(days: i));
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                  color: isHoliday
                      ? TatvaColors.error.withOpacity(0.08)
                      : isToday
                          ? TatvaColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(6)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(ScheduleModel.dayNames[day],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: headerColor ?? TatvaColors.neutral400)),
                Text('${d.day}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: headerColor ?? TatvaColors.neutral900)),
              ]),
            ),
          );
        }),
      ]),
      const SizedBox(height: 4),
      if (sorted.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No periods defined',
              style: TextStyle(color: TatvaColors.neutral400))),
        )
      else
        ...sorted.map((time) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(time,
                        style: const TextStyle(
                            fontSize: 10, color: TatvaColors.neutral400)),
                  ),
                ),
                ...List.generate(5, (i) {
                  final day = i + 1;
                  final ds =
                      schedules.where((s) => s.dayOfWeek == day).toList();
                  PeriodSlot? slot;
                  if (ds.isNotEmpty) {
                    final m =
                        ds.first.periods.where((p) => p.startTime == time);
                    if (m.isNotEmpty) slot = m.first;
                  }
                  final dayEvents = _eventsForDay(day)
                      .where((e) => e.startTime == time)
                      .toList();

                  final isToday = DateTime.now().weekday == day;
                  final isHoliday = _isDayHoliday(day);
                  final cancelled =
                      slot != null && (_isPeriodCancelled(day, time) || isHoliday);

                  if (dayEvents.isNotEmpty && slot == null) {
                    final ev = dayEvents.first;
                    final evColor = ev.type == 'holiday'
                        ? TatvaColors.error
                        : ev.type == 'ptm'
                            ? TatvaColors.purple
                            : TatvaColors.accent;
                    return Expanded(
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: evColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: evColor.withOpacity(0.3))),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(ev.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: evColor)),
                          ],
                        ),
                      ),
                    );
                  }

                  final c = slot != null
                      ? (subjectColors[slot.subject] ?? TatvaColors.primary)
                      : Colors.grey.shade200;
                  return Expanded(
                    child: slot == null
                        ? const SizedBox(height: 52)
                        : Opacity(
                      opacity: cancelled ? 0.4 : 1.0,
                      child: Container(
                        height: 52,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: cancelled
                                ? Colors.grey.shade100
                                : c.withOpacity(isToday ? 0.18 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: cancelled
                                    ? Colors.grey.shade200
                                    : c.withOpacity(0.3))),
                        child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(cancelled ? '✕' : slot.subject,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color:
                                              cancelled ? Colors.grey : c,
                                          decoration: cancelled
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none)),
                                  if (!cancelled &&
                                      slot.teacherName.isNotEmpty)
                                    Text(
                                        slot.teacherName.split(' ').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 8,
                                            color: c.withOpacity(0.7))),
                                ],
                              ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      if (sorted.isNotEmpty) ...[
        const SizedBox(height: 12),
        ..._events.where((e) => e.startTime.isNotEmpty).where((e) {
          final d = DateTime.tryParse(e.date);
          if (d == null) return false;
          final dow = d.weekday;
          return _eventsForDay(dow).where((ev) => ev.startTime == e.startTime).isNotEmpty &&
              !sorted.contains(e.startTime);
        }).map(_buildEventCard),
      ],
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: subjectColors.entries
            .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 4),
                  Text(e.key,
                      style: const TextStyle(
                          fontSize: 11, color: TatvaColors.neutral900)),
                ]))
            .toList(),
      ),
    ]);
  }

  List<ScheduleEvent> get _visibleEvents {
    if (_selectedDay == 0) return _events;
    final ds = _dateStr(_selectedDay);
    return _events.where((e) => e.date == ds).toList();
  }

  Widget _buildEventCard(ScheduleEvent ev) {
    final c = ev.type == 'holiday'
        ? TatvaColors.error
        : ev.type == 'ptm'
            ? TatvaColors.purple
            : TatvaColors.accent;
    final icon = ev.type == 'holiday'
        ? Icons.wb_sunny_outlined
        : ev.type == 'ptm'
            ? Icons.people_outline
            : Icons.event_outlined;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, size: 18, color: c),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ev.title,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c)),
            if (ev.startTime.isNotEmpty)
              Text('${ev.date} • ${ev.startTime}${ev.endTime.isNotEmpty ? ' – ${ev.endTime}' : ''}',
                  style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400))
            else
              Text(ev.date,
                  style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
            if (ev.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(ev.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
              ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4)),
          child: Text(ev.typeLabel,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
        ),
      ]),
    );
  }

  Widget _dayDetail(List<ScheduleModel> schedules, int day) {
    final ds = schedules.where((s) => s.dayOfWeek == day).toList();
    final periods = ds.isNotEmpty ? ds.first.periods : <PeriodSlot>[];
    final colors = [
      TatvaColors.primary,
      TatvaColors.info,
      TatvaColors.accent,
      TatvaColors.purple,
      TatvaColors.success,
      TatvaColors.error
    ];

    if (periods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_busy_outlined,
                color: TatvaColors.neutral400, size: 40),
            const SizedBox(height: 10),
            Text('No classes on ${ScheduleModel.dayNamesFull[day]}',
                style: const TextStyle(
                    fontSize: 14, color: TatvaColors.neutral400)),
          ]),
        ),
      );
    }

    return Column(
      children: periods.asMap().entries.map((e) {
        final i = e.key;
        final p = e.value;
        final c = colors[i % colors.length];
        final cancelled = _isPeriodCancelled(day, p.startTime);
        return Opacity(
          opacity: cancelled ? 0.5 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: cancelled ? Colors.grey.shade50 : TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cancelled
                        ? Colors.grey.shade200
                        : c.withOpacity(0.2))),
            child: Row(children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                    color: cancelled ? Colors.grey.shade300 : c,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${p.startTime} - ${p.endTime}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cancelled ? Colors.grey : c,
                        decoration: cancelled
                            ? TextDecoration.lineThrough
                            : TextDecoration.none)),
                Text('Period ${p.period}',
                    style: const TextStyle(
                        fontSize: 10, color: TatvaColors.neutral400)),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(
                              p.subject.isNotEmpty
                                  ? p.subject
                                  : 'Free Period',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: cancelled
                                      ? Colors.grey
                                      : (p.subject.isNotEmpty
                                          ? TatvaColors.neutral900
                                          : TatvaColors.neutral400),
                                  decoration: cancelled
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none)),
                        ),
                        if (cancelled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: TatvaColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('Cancelled',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: TatvaColors.error)),
                          ),
                        ],
                      ]),
                      if (!cancelled && p.teacherName.isNotEmpty)
                        Text(p.teacherName,
                            style: const TextStyle(
                                fontSize: 12,
                                color: TatvaColors.neutral400)),
                    ]),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ─── Holiday Calendar ──────────────────────────────────────────────

  Future<void> _downloadPdf() async {
    try {
      final bytes = await generateSchoolYearPdf(_holidays, _schoolYear, firstDay: _firstDay, lastDay: _lastDay);
      await Printing.sharePdf(bytes: bytes, filename: 'school_year_${_schoolYear - 1}_${_schoolYear}_holidays.pdf');
    } catch (e) {
      debugPrint('PDF error: $e');
    }
  }

  Widget _buildHolidayCalendar() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: _downloadPdf,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: TatvaColors.primary, borderRadius: BorderRadius.circular(10)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.picture_as_pdf_outlined, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text('Download PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 12),
      _monthCalendarWidget(),
      if (_selectedCalDate.isNotEmpty) ...[
        const SizedBox(height: 16),
        ..._holidaysForDate(_selectedCalDate).map(_buildHolidayCard),
      ],
      const SizedBox(height: 20),
      _buildUpcomingHolidays(),
    ]);
  }

  List<Holiday> _holidaysForDate(String dateStr) =>
      _holidays.where((h) => h.coversDate(dateStr)).toList();

  Widget _monthCalendarWidget() {
    final year = _calMonth.year;
    final month = _calMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    final todayStr = _fmtDate(DateTime.now());

    final holidayDates = <String>{};
    for (final h in _holidays) {
      final s = DateTime.tryParse(h.startDate);
      final e = DateTime.tryParse(h.endDate);
      if (s == null || e == null) continue;
      for (var d = s; !d.isAfter(e); d = d.add(const Duration(days: 1))) {
        if (d.month == month && d.year == year) holidayDates.add(_fmtDate(d));
      }
    }

    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: TatvaColors.neutral900),
          onPressed: () => setState(() {
            _calMonth = DateTime(year, month - 1);
            _selectedCalDate = '';
          }),
        ),
        Text('${months[month - 1]} $year',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: TatvaColors.neutral900),
          onPressed: () => setState(() {
            _calMonth = DateTime(year, month + 1);
            _selectedCalDate = '';
          }),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
          .map((d) => Expanded(
              child: Center(
                  child: Text(d,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TatvaColors.neutral400)))))
          .toList()),
      const SizedBox(height: 6),
      ...List.generate(6, (week) {
        return Row(children: List.generate(7, (col) {
          final idx = week * 7 + col - startWeekday + 1;
          if (idx < 1 || idx > daysInMonth) {
            return const Expanded(child: SizedBox(height: 42));
          }
          final dateStr = _fmtDate(DateTime(year, month, idx));
          final isHoliday = holidayDates.contains(dateStr);
          final isToday = dateStr == todayStr;
          final isSelected = dateStr == _selectedCalDate;
          final inSchool = _isSchoolDay(dateStr);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCalDate = isSelected ? '' : dateStr),
              child: Container(
                height: 42,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    color: isSelected
                        ? TatvaColors.primary.withOpacity(0.15)
                        : isHoliday
                            ? Colors.red.withOpacity(0.06)
                            : !inSchool
                                ? Colors.grey.shade100
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: TatvaColors.primary, width: 1.5) : null),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('$idx',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? TatvaColors.primary
                              : isHoliday
                                  ? Colors.red
                                  : !inSchool
                                      ? Colors.grey.shade400
                                      : TatvaColors.neutral900)),
                  if (isHoliday)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 5, height: 5,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                ]),
              ),
            ),
          );
        }));
      }),
    ]);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _buildHolidayCard(Holiday h) {
    final c = h.typeColor;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final s = DateTime.tryParse(h.startDate);
    final e = DateTime.tryParse(h.endDate);
    String dateLabel = '';
    if (s != null) {
      dateLabel = '${months[s.month - 1]} ${s.day}';
      if (e != null && h.isMultiDay) {
        dateLabel += ' – ${months[e.month - 1]} ${e.day}  (${h.durationDays} days)';
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
          color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.2))),
      child: Row(children: [
        Icon(h.typeIcon, size: 18, color: c),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(h.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)),
            Text(dateLabel, style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
            if (h.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(h.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
              ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
          child: Text(h.typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
        ),
      ]),
    );
  }

  Widget _buildUpcomingHolidays() {
    final todayStr = _fmtDate(DateTime.now());
    final upcoming = _holidays
        .where((h) => h.endDate.compareTo(todayStr) >= 0)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (upcoming.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.beach_access_outlined, color: TatvaColors.neutral400, size: 36),
            const SizedBox(height: 8),
            const Text('No upcoming holidays', style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
          ]),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Upcoming Holidays',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
      const SizedBox(height: 10),
      ...upcoming.asMap().entries.map((entry) {
        final i = entry.key;
        return FadeSlideIn(delayMs: i * 40, child: _buildHolidayCard(entry.value));
      }),
    ]);
  }
}
