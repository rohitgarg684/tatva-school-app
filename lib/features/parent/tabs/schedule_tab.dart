import 'package:flutter/material.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/child_info.dart';
import '../../../models/schedule_model.dart';
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
  bool _loading = false;
  bool _loaded = false;
  int _selectedDay = 0;

  @override
  void didUpdateWidget(ParentScheduleTab old) {
    super.didUpdateWidget(old);
    if (old.selectedChildIndex != widget.selectedChildIndex) {
      _loaded = false;
      _loadData();
    }
  }

  String _grade() {
    if (widget.childrenData.isEmpty) return '8';
    final cls = widget.childrenData[widget.selectedChildIndex].childClass;
    if (cls == null) return '8';
    final match = RegExp(r'(\d+)').firstMatch(cls.name);
    return match?.group(1) ?? '8';
  }

  String _section() {
    if (widget.childrenData.isEmpty) return 'A';
    final cls = widget.childrenData[widget.selectedChildIndex].childClass;
    if (cls == null) return 'A';
    final match =
        RegExp(r'Section\s*(\w+)', caseSensitive: false).firstMatch(cls.name);
    return match?.group(1) ?? 'A';
  }

  void _loadData() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final data =
          await widget.api.getScheduleWithCancellations(_grade(), _section());
      final raw =
          (data['schedules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _weekData = raw.map((m) => ScheduleModel.fromJson(m)).toList();
      _cancellations =
          (data['cancellations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Schedule load error: $e');
      _weekData = [];
      _cancellations = [];
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _loaded = true;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded && !_loading) {
      Future.microtask(_loadData);
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
            child: Text('$className • Weekly Timetable',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 16),
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

  Widget _weekGrid(List<ScheduleModel> schedules) {
    final allTimes = <String>{};
    for (final s in schedules) {
      for (final p in s.periods) allTimes.add(p.startTime);
    }
    final sorted = allTimes.toList()..sort();
    if (sorted.isEmpty) {
      return const Center(
          child: Text('No periods defined',
              style: TextStyle(color: TatvaColors.neutral400)));
    }

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
                  color: isToday
                      ? TatvaColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6)),
              child: Center(
                  child: Text(ScheduleModel.dayNames[day],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? TatvaColors.primary
                              : TatvaColors.neutral900))),
            ),
          );
        }),
      ]),
      const SizedBox(height: 4),
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
                final isToday = DateTime.now().weekday == day;
                final cancelled =
                    slot != null && _isPeriodCancelled(day, time);
                final c = slot != null
                    ? (subjectColors[slot.subject] ?? TatvaColors.primary)
                    : Colors.grey.shade200;
                return Expanded(
                  child: Opacity(
                    opacity: cancelled ? 0.4 : 1.0,
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: cancelled
                              ? Colors.grey.shade100
                              : slot != null
                                  ? c.withOpacity(isToday ? 0.18 : 0.1)
                                  : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: cancelled
                                  ? Colors.grey.shade200
                                  : slot != null
                                      ? c.withOpacity(0.3)
                                      : Colors.grey.shade100)),
                      child: slot != null
                          ? Column(
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
                            )
                          : const SizedBox.shrink(),
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
}
