import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../models/class_model.dart';
import '../../../models/schedule_model.dart';
import '../../../models/schedule_event.dart';
import '../../../models/holiday.dart';
import '../../../services/api_service.dart';

class StudentScheduleTab extends StatefulWidget {
  final ClassModel? primaryClass;
  final ApiService api;

  const StudentScheduleTab({
    super.key,
    required this.primaryClass,
    required this.api,
  });

  @override
  State<StudentScheduleTab> createState() => _StudentScheduleTabState();
}

class _StudentScheduleTabState extends State<StudentScheduleTab> {
  List<ScheduleModel> _weekData = [];
  List<Map<String, dynamic>> _cancellations = [];
  List<ScheduleEvent> _events = [];
  bool _loading = false;
  bool _loaded = false;
  DateTime? _lastLoadedWeek;
  int _selectedDay = 0;
  DateTime _weekStart = DateTime.now();
  List<Holiday> _holidays = [];
  bool _holidaysLoaded = false;

  String _parseGrade() {
    final name = widget.primaryClass?.name ?? '';
    final match = RegExp(r'(\d+)').firstMatch(name);
    return match?.group(1) ?? '8';
  }

  String _parseSection() {
    final name = widget.primaryClass?.name ?? '';
    final match = RegExp(r'Section\s*(\w+)', caseSensitive: false).firstMatch(name);
    return match?.group(1) ?? 'A';
  }

  void _loadData() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final ws = _getWeekStart(_weekStart);
      final we = ws.add(const Duration(days: 4));
      String dateStr(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final results = await Future.wait([
        widget.api.getScheduleWithCancellations(_parseGrade(), _parseSection()),
        widget.api.getScheduleEvents(dateStr(ws), dateStr(we)),
      ]);
      final data = results[0] as Map<String, dynamic>;
      final raw = (data['schedules'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      _weekData = raw.map((m) => ScheduleModel.fromJson(m)).toList();
      _cancellations = (data['cancellations'] as List?)
              ?.cast<Map<String, dynamic>>() ?? [];
      final evRaw = results[1] as List<Map<String, dynamic>>;
      _events = evRaw.map((m) => ScheduleEvent.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Schedule load error: $e');
      _weekData = [];
      _cancellations = [];
      _events = [];
    }
    if (mounted) setState(() { _loading = false; _loaded = true; _lastLoadedWeek = _weekStart; });
  }

  @override
  Widget build(BuildContext context) {
    final needsLoad = !_loaded && !_loading;
    final weekChanged = _lastLoadedWeek != null &&
        _getWeekStart(_weekStart) != _getWeekStart(_lastLoadedWeek!);
    if (needsLoad || (weekChanged && !_loading)) {
      Future.microtask(_loadData);
    }
    if (!_holidaysLoaded) {
      Future.microtask(_loadHolidays);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('My Schedule',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text(
                '${widget.primaryClass?.name ?? ''} • Weekly Timetable',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 16),
        Row(children: [
          GestureDetector(
            onTap: () => setState(() {
              _weekStart = _weekStart.subtract(const Duration(days: 7));
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: const Icon(Icons.chevron_left, color: TatvaColors.neutral400, size: 20),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                  _weekLabel(_weekStart),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: TatvaColors.neutral900)),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {
              _weekStart = _weekStart.add(const Duration(days: 7));
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: const Icon(Icons.chevron_right, color: TatvaColors.neutral400, size: 20),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            _dayChip('All', _selectedDay == 0, () => setState(() => _selectedDay = 0)),
            ...List.generate(5, (i) {
              final day = i + 1;
              return _dayChip(
                  ScheduleModel.dayNames[day],
                  _selectedDay == day,
                  () => setState(() => _selectedDay = day));
            }),
          ],
        ),
        const SizedBox(height: 16),
        if (_loading && !_loaded)
          const Center(child: Padding(
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
                        fontSize: 15,
                        color: TatvaColors.neutral400)),
              ]),
            ),
          )
        else if (_selectedDay == 0)
          _buildWeekGrid(_weekData)
        else
          _buildDayDetail(_weekData, _selectedDay),
        if (_weekEvents.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._weekEvents.map(_buildEventCard),
        ],
        if (_upcomingHolidays.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Upcoming Holidays',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
          const SizedBox(height: 10),
          ..._upcomingHolidays.asMap().entries.map((e) =>
              FadeSlideIn(delayMs: e.key * 40, child: _buildHolidayCard(e.value))),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

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
                  color: isActive ? TatvaColors.primary : Colors.grey.shade200)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : TatvaColors.neutral400))),
        ),
      ),
    );
  }

  String _schedDateStr(int dayOfWeek) {
    final ws = _getWeekStart(_weekStart);
    final d = ws.add(Duration(days: dayOfWeek - 1));
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _isPeriodCancelled(int dayOfWeek, String startTime) {
    final dateStr = _schedDateStr(dayOfWeek);
    return _cancellations.any((cn) =>
        cn['date'] == dateStr && cn['startTime'] == startTime);
  }

  Widget _buildWeekGrid(List<ScheduleModel> schedules) {
    final allPeriodTimes = <String>{};
    for (final s in schedules) {
      for (final p in s.periods) {
        allPeriodTimes.add(p.startTime);
      }
    }
    final sortedTimes = allPeriodTimes.toList()..sort();
    if (sortedTimes.isEmpty) {
      return const Center(
          child: Text('No periods defined',
              style: TextStyle(color: TatvaColors.neutral400)));
    }

    final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success, TatvaColors.error];
    final subjectColorMap = <String, Color>{};
    int colorIndex = 0;
    for (final s in schedules) {
      for (final p in s.periods) {
        if (p.subject.isNotEmpty && !subjectColorMap.containsKey(p.subject)) {
          subjectColorMap[p.subject] = colors[colorIndex % colors.length];
          colorIndex++;
        }
      }
    }

    return Column(children: [
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
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                  color: isToday ? TatvaColors.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                  child: Text(ScheduleModel.dayNames[day],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday ? TatvaColors.primary : TatvaColors.neutral900))),
            ),
          );
        }),
      ]),
      const SizedBox(height: 4),
      ...sortedTimes.map((time) {
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
                          fontSize: 10,
                          color: TatvaColors.neutral400)),
                ),
              ),
              ...List.generate(5, (i) {
                final day = i + 1;
                final daySchedule = schedules
                    .where((s) => s.dayOfWeek == day)
                    .toList();
                PeriodSlot? slot;
                if (daySchedule.isNotEmpty) {
                  final matching = daySchedule.first.periods
                      .where((p) => p.startTime == time);
                  if (matching.isNotEmpty) slot = matching.first;
                }
                final isToday = DateTime.now().weekday == day;
                final cancelled = slot != null && _isPeriodCancelled(day, time);
                final c = slot != null
                    ? (subjectColorMap[slot.subject] ?? TatvaColors.primary)
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
                                        color: cancelled ? Colors.grey : c,
                                        decoration: cancelled
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none)),
                                if (!cancelled && slot.teacherName.isNotEmpty)
                                  Text(slot.teacherName.split(' ').last,
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
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 6,
        children: subjectColorMap.entries
            .map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: e.value, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 4),
                  Text(e.key,
                      style: const TextStyle(
                          fontSize: 11,
                          color: TatvaColors.neutral900)),
                ]))
            .toList(),
      ),
    ]);
  }

  Widget _buildDayDetail(List<ScheduleModel> schedules, int day) {
    final daySchedule = schedules.where((s) => s.dayOfWeek == day).toList();
    final periods = daySchedule.isNotEmpty ? daySchedule.first.periods : <PeriodSlot>[];
    final colors = [TatvaColors.primary, TatvaColors.info, TatvaColors.accent, TatvaColors.purple, TatvaColors.success, TatvaColors.error];

    if (periods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.event_busy_outlined, color: TatvaColors.neutral400, size: 40),
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
                border: Border.all(color: cancelled ? Colors.grey.shade200 : c.withOpacity(0.2))),
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
                        decoration: cancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                Text('Period ${p.period}',
                    style: const TextStyle(
                        fontSize: 10, color: TatvaColors.neutral400)),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(
                      child: Text(p.subject.isNotEmpty ? p.subject : 'Free Period',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cancelled ? Colors.grey : (p.subject.isNotEmpty ? TatvaColors.neutral900 : TatvaColors.neutral400),
                              decoration: cancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                    ),
                    if (cancelled) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  List<ScheduleEvent> get _weekEvents {
    if (_selectedDay == 0) return _events;
    final ws = _getWeekStart(_weekStart);
    final d = ws.add(Duration(days: _selectedDay - 1));
    final ds = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c)),
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

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  String _weekLabel(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 4));
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (weekStart.month == weekEnd.month) {
      return '${months[weekStart.month]} ${weekStart.day} - ${weekEnd.day}, ${weekStart.year}';
    }
    return '${months[weekStart.month]} ${weekStart.day} - ${months[weekEnd.month]} ${weekEnd.day}';
  }

  // ─── Holidays ──────────────────────────────────────────────────────

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

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Holiday> get _upcomingHolidays {
    final todayStr = _fmtDate(DateTime.now());
    return _holidays
        .where((h) => h.endDate.compareTo(todayStr) >= 0)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

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
}
