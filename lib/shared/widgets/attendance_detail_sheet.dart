import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../shared/theme/colors.dart';

class AttendanceDetailSheet {
  static void show(
    BuildContext context, {
    required List<AttendanceRecord> records,
    required String studentName,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AttendanceDetailView(
        records: records,
        studentName: studentName,
      ),
    );
  }
}

class _AttendanceDetailView extends StatefulWidget {
  final List<AttendanceRecord> records;
  final String studentName;

  const _AttendanceDetailView({
    required this.records,
    required this.studentName,
  });

  @override
  State<_AttendanceDetailView> createState() => _AttendanceDetailViewState();
}

class _AttendanceDetailViewState extends State<_AttendanceDetailView> {
  static const primary = TatvaColors.primary;
  static const success = TatvaColors.success;
  static const danger = TatvaColors.error;
  static const accent = TatvaColors.accent;
  static const info = TatvaColors.info;
  static const textDark = TatvaColors.neutral900;
  static const textLight = TatvaColors.neutral400;
  static const textMid = TatvaColors.neutral600;
  static const bgCard = TatvaColors.bgCard;
  static const bg = TatvaColors.bgLight;

  int _viewMode = 0; // 0=Month, 1=Week, 2=Custom
  late DateTime _selectedMonth;
  late DateTime _selectedWeekStart;
  DateTimeRange? _customRange;

  late Map<String, AttendanceRecord> _byDate;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedWeekStart = _mondayOf(DateTime.now());
    _byDate = {};
    for (final r in widget.records) {
      _byDate[r.date] = r;
    }
  }

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  List<AttendanceRecord> get _filteredRecords {
    switch (_viewMode) {
      case 0: // Month
        final start =
            '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-01';
        final lastDay =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
        final end =
            '${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
        return widget.records
            .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
            .toList();
      case 1: // Week
        final start = _dateStr(_selectedWeekStart);
        final end = _dateStr(_selectedWeekStart.add(const Duration(days: 6)));
        return widget.records
            .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
            .toList();
      case 2: // Custom
        if (_customRange == null) return widget.records;
        final start = _dateStr(_customRange!.start);
        final end = _dateStr(_customRange!.end);
        return widget.records
            .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
            .toList();
      default:
        return widget.records;
    }
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ({int present, int absent, int tardy, int total}) _stats(List<AttendanceRecord> recs) {
    int p = 0, a = 0, t = 0;
    for (final r in recs) {
      switch (r.status) {
        case AttendanceStatus.present:
          p++;
        case AttendanceStatus.absent:
          a++;
        case AttendanceStatus.tardy:
          t++;
      }
    }
    return (present: p, absent: a, tardy: t, total: p + a + t);
  }

  static const _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _monthsShort = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRecords;
    final stats = _stats(filtered);
    final allStats = _stats(widget.records);
    final rate = stats.total > 0 ? (stats.present / stats.total * 100) : 0.0;

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Attendance',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          Text(widget.studentName,
              style: const TextStyle(
fontSize: 13, color: textLight)),
          const SizedBox(height: 16),

          // Attendance rate ring
          _buildAttendanceRing(rate, stats),
          const SizedBox(height: 16),

          // View mode tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                _modeTab('Month', 0),
                _modeTab('Week', 1),
                _modeTab('Custom', 2),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Navigation
          _buildNavigation(),
          const SizedBox(height: 12),

          // Calendar or list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                if (_viewMode == 0) _buildMonthCalendar(),
                if (_viewMode == 1) _buildWeekView(filtered),
                if (_viewMode == 2) _buildCustomView(filtered),
                const SizedBox(height: 16),
                _buildStatsSummary(stats),
                const SizedBox(height: 12),
                _buildStreakInfo(),
                const SizedBox(height: 12),
                _buildAllTimeBar(allStats),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeTab(String label, int mode) {
    final isActive = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: isActive ? bgCard : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              boxShadow: isActive
                  ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)]
                  : null),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? primary : textLight))),
        ),
      ),
    );
  }

  Widget _buildAttendanceRing(double rate, dynamic stats) {
    final rateColor = rate >= 90
        ? success
        : rate >= 75
            ? accent
            : danger;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation(rateColor),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: rateColor)),
              const Text('rate',
                  style: TextStyle(
                      fontSize: 10,
                      color: textLight)),
            ]),
          ]),
        ),
        const SizedBox(width: 24),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ringLegend(success, 'Present', stats.present),
          const SizedBox(height: 6),
          _ringLegend(danger, 'Absent', stats.absent),
          const SizedBox(height: 6),
          _ringLegend(accent, 'Tardy', stats.tardy),
        ]),
      ],
    );
  }

  Widget _ringLegend(Color color, String label, int count) {
    return Row(children: [
      Container(
        width: 10,
        height: 10,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
      ),
      const SizedBox(width: 6),
      Text('$count $label',
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textDark)),
    ]);
  }

  Widget _buildNavigation() {
    String label;
    VoidCallback onPrev, onNext;

    switch (_viewMode) {
      case 0:
        label = '${_months[_selectedMonth.month]} ${_selectedMonth.year}';
        onPrev = () => setState(() => _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1));
        onNext = () => setState(() => _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month + 1));
      case 1:
        final end = _selectedWeekStart.add(const Duration(days: 6));
        label =
            '${_monthsShort[_selectedWeekStart.month]} ${_selectedWeekStart.day} - ${_monthsShort[end.month]} ${end.day}';
        onPrev = () => setState(() => _selectedWeekStart =
            _selectedWeekStart.subtract(const Duration(days: 7)));
        onNext = () => setState(() => _selectedWeekStart =
            _selectedWeekStart.add(const Duration(days: 7)));
      default:
        if (_customRange != null) {
          label =
              '${_monthsShort[_customRange!.start.month]} ${_customRange!.start.day} - ${_monthsShort[_customRange!.end.month]} ${_customRange!.end.day}';
        } else {
          label = 'Select date range';
        }
        onPrev = () {};
        onNext = () {};
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        if (_viewMode != 2)
          GestureDetector(
            onTap: onPrev,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: const Icon(Icons.chevron_left, color: textLight, size: 20),
            ),
          ),
        Expanded(
          child: GestureDetector(
            onTap: _viewMode == 2 ? _pickDateRange : null,
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _viewMode == 2 ? primary : textDark))),
          ),
        ),
        if (_viewMode != 2)
          GestureDetector(
            onTap: onNext,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child:
                  const Icon(Icons.chevron_right, color: textLight, size: 20),
            ),
          ),
        if (_viewMode == 2)
          GestureDetector(
            onTap: _pickDateRange,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.date_range, color: primary, size: 20),
            ),
          ),
      ]),
    );
  }

  void _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _customRange = picked);
    }
  }

  // Month calendar heatmap
  Widget _buildMonthCalendar() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday; // 1=Mon

    final cells = <Widget>[];

    // Day-of-week headers
    for (final l in _dayLabels) {
      cells.add(Center(
          child: Text(l,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: textLight))));
    }

    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final record = _byDate[dateStr];
      final isToday = DateTime.now().year == year &&
          DateTime.now().month == month &&
          DateTime.now().day == day;
      final isFuture = DateTime(year, month, day).isAfter(DateTime.now());
      final isWeekend = DateTime(year, month, day).weekday > 5;

      Color cellColor;
      Color textColor;
      if (isFuture || isWeekend) {
        cellColor = Colors.grey.shade50;
        textColor = Colors.grey.shade300;
      } else if (record != null) {
        switch (record.status) {
          case AttendanceStatus.present:
            cellColor = success.withOpacity(0.15);
            textColor = success;
          case AttendanceStatus.absent:
            cellColor = danger.withOpacity(0.15);
            textColor = danger;
          case AttendanceStatus.tardy:
            cellColor = accent.withOpacity(0.15);
            textColor = accent;
        }
      } else {
        cellColor = Colors.grey.shade50;
        textColor = Colors.grey.shade400;
      }

      cells.add(Container(
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: primary, width: 2)
              : null,
        ),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$day',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                    color: textColor)),
            if (record != null && !isFuture)
              Text(
                  record.status == AttendanceStatus.present
                      ? 'P'
                      : record.status == AttendanceStatus.absent
                          ? 'A'
                          : 'T',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: textColor)),
          ]),
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16)),
      child: GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        children: cells,
      ),
    );
  }

  // Week detail view
  Widget _buildWeekView(List<AttendanceRecord> records) {
    records.sort((a, b) => a.date.compareTo(b.date));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: List.generate(7, (i) {
        final date = _selectedWeekStart.add(Duration(days: i));
        final dateStr = _dateStr(date);
        final record = _byDate[dateStr];
        final isToday = _dateStr(DateTime.now()) == dateStr;
        final isFuture = date.isAfter(DateTime.now());
        final isWeekend = date.weekday > 5;

        Color statusColor;
        String statusText;
        IconData statusIcon;
        if (isFuture) {
          statusColor = Colors.grey.shade300;
          statusText = 'Upcoming';
          statusIcon = Icons.schedule;
        } else if (isWeekend && record == null) {
          statusColor = Colors.grey.shade300;
          statusText = 'Weekend';
          statusIcon = Icons.weekend_outlined;
        } else if (record != null) {
          switch (record.status) {
            case AttendanceStatus.present:
              statusColor = success;
              statusText = 'Present';
              statusIcon = Icons.check_circle_rounded;
            case AttendanceStatus.absent:
              statusColor = danger;
              statusText = 'Absent';
              statusIcon = Icons.cancel_rounded;
            case AttendanceStatus.tardy:
              statusColor = accent;
              statusText = 'Tardy';
              statusIcon = Icons.access_time_rounded;
          }
        } else {
          statusColor = Colors.grey.shade400;
          statusText = 'No record';
          statusIcon = Icons.remove_circle_outline;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: isToday ? primary.withOpacity(0.05) : bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isToday ? primary.withOpacity(0.3) : Colors.grey.shade100)),
          child: Row(children: [
            SizedBox(
              width: 36,
              child: Column(children: [
                Text(dayNames[date.weekday - 1],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isToday ? primary : textLight)),
                Text('${date.day}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday ? primary : textDark)),
              ]),
            ),
            const SizedBox(width: 14),
            Container(width: 3, height: 32, color: statusColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(statusText,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: statusColor)),
            ),
            Icon(statusIcon, color: statusColor, size: 22),
          ]),
        );
      }),
    );
  }

  // Custom date range list
  Widget _buildCustomView(List<AttendanceRecord> records) {
    if (_customRange == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.date_range, color: textLight, size: 40),
          const SizedBox(height: 12),
          const Text('Tap the date range button to select dates',
              textAlign: TextAlign.center,
              style: TextStyle(
fontSize: 14, color: textLight)),
        ]),
      );
    }

    final sorted = List<AttendanceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    if (sorted.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('No attendance records in this range',
            style: TextStyle(
fontSize: 14, color: textLight)),
      );
    }

    return Column(
      children: sorted.map((r) {
        final parts = r.date.split('-');
        final month = int.tryParse(parts[1]) ?? 1;
        final day = int.tryParse(parts[2]) ?? 1;
        Color c;
        IconData icon;
        switch (r.status) {
          case AttendanceStatus.present:
            c = success;
            icon = Icons.check_circle_rounded;
          case AttendanceStatus.absent:
            c = danger;
            icon = Icons.cancel_rounded;
          case AttendanceStatus.tardy:
            c = accent;
            icon = Icons.access_time_rounded;
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade100)),
          child: Row(children: [
            Text('${_monthsShort[month]} $day',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textDark)),
            const Spacer(),
            Icon(icon, color: c, size: 18),
            const SizedBox(width: 6),
            Text(r.status.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: c)),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildStatsSummary(dynamic stats) {
    final total = stats.total as int;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Row(children: [
          const Icon(Icons.insights_rounded, color: info, size: 16),
          const SizedBox(width: 6),
          const Text('Period Summary',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
        ]),
        const SizedBox(height: 10),
        _barRow('Present', stats.present, total, success),
        const SizedBox(height: 6),
        _barRow('Absent', stats.absent, total, danger),
        const SizedBox(height: 6),
        _barRow('Tardy', stats.tardy, total, accent),
      ]),
    );
  }

  Widget _barRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(children: [
      SizedBox(
        width: 55,
        child: Text(label,
            style: const TextStyle(
fontSize: 11, color: textLight)),
      ),
      Expanded(
        child: Container(
          height: 8,
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: pct,
            child: Container(
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 30,
        child: Text('$count',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color)),
      ),
    ]);
  }

  Widget _buildStreakInfo() {
    final sorted = List<AttendanceRecord>.from(widget.records)
      ..sort((a, b) => b.date.compareTo(a.date));
    int currentStreak = 0;
    int longestStreak = 0;
    int streak = 0;
    for (final r in sorted) {
      if (r.status == AttendanceStatus.present) {
        streak++;
        if (streak > longestStreak) longestStreak = streak;
      } else {
        if (currentStreak == 0) currentStreak = streak;
        streak = 0;
      }
    }
    if (currentStreak == 0) currentStreak = streak;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Expanded(
          child: Column(children: [
            Icon(Icons.local_fire_department_rounded,
                color: accent, size: 22),
            const SizedBox(height: 4),
            Text('$currentStreak',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const Text('Current Streak',
                style: TextStyle(
fontSize: 10, color: textLight)),
          ]),
        ),
        Container(width: 1, height: 40, color: Colors.grey.shade200),
        Expanded(
          child: Column(children: [
            Icon(Icons.emoji_events_rounded, color: success, size: 22),
            const SizedBox(height: 4),
            Text('$longestStreak',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const Text('Best Streak',
                style: TextStyle(
fontSize: 10, color: textLight)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAllTimeBar(dynamic allStats) {
    final total = allStats.total as int;
    if (total == 0) return const SizedBox.shrink();
    final presentPct = allStats.present / total;
    final absentPct = allStats.absent / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.calendar_month_rounded, color: primary, size: 16),
          const SizedBox(width: 6),
          const Text('All-Time Record',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const Spacer(),
          Text('$total school days',
              style: const TextStyle(
fontSize: 11, color: textLight)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(children: [
              Flexible(
                flex: allStats.present,
                child: Container(color: success),
              ),
              if (allStats.tardy > 0)
                Flexible(
                  flex: allStats.tardy,
                  child: Container(color: accent),
                ),
              if (allStats.absent > 0)
                Flexible(
                  flex: allStats.absent,
                  child: Container(color: danger),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${(presentPct * 100).toStringAsFixed(1)}% present',
              style: const TextStyle(
                  fontSize: 11,
                  color: success,
                  fontWeight: FontWeight.w600)),
          Text('${(absentPct * 100).toStringAsFixed(1)}% absent',
              style: const TextStyle(
                  fontSize: 11,
                  color: danger,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
