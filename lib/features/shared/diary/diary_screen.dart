import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../models/diary_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/animations/fade_slide_in.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import 'create_diary_entry_sheet.dart';
import 'diary_entry_detail_sheet.dart';

class DiaryScreen extends StatefulWidget {
  final List<ClassModel> classes;
  final String uid;
  final String role;
  final String? fixedClassId;

  const DiaryScreen({
    super.key,
    required this.classes,
    required this.uid,
    required this.role,
    this.fixedClassId,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _api = ApiService();
  late String _selectedClassId;
  late DateTime _selectedDate;
  List<DiaryEntry> _entries = [];
  bool _loading = true;
  bool _monthExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.fixedClassId ?? (widget.classes.isNotEmpty ? widget.classes.first.id : '');
    _selectedDate = DateTime.now();
    _loadEntries();
  }

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  Future<void> _loadEntries() async {
    if (_selectedClassId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final raw = await _api.getDiaryEntries(_selectedClassId, _dateStr);
      _entries = raw.map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('DiaryScreen._loadEntries error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onDateSelected(DateTime date) {
    setState(() => _selectedDate = date);
    _loadEntries();
  }

  void _showCreateEntry() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateDiaryEntrySheet(
        classId: _selectedClassId,
        onCreated: (entry) {
          setState(() => _entries.insert(0, entry));
        },
      ),
    );
  }

  void _openEntry(DiaryEntry entry) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DiaryEntryDetailSheet(
        entry: entry,
        uid: widget.uid,
        role: widget.role,
        onEntryDeleted: (id) {
          setState(() => _entries.removeWhere((e) => e.id == id));
        },
        onEntryUpdated: (updated) {
          setState(() {
            final idx = _entries.indexWhere((e) => e.id == updated.id);
            if (idx >= 0) _entries[idx] = updated;
          });
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.role == 'Teacher' || widget.role == 'Principal';
    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(isTeacher),
          _buildCalendarStrip(),
          if (_monthExpanded) _buildMonthGrid(),
          Expanded(child: _buildBody()),
        ]),
      ),
      floatingActionButton: isTeacher && _selectedClassId.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCreateEntry,
              backgroundColor: TatvaColors.primary,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text('Write', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isTeacher) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        const Icon(Icons.menu_book_rounded, color: TatvaColors.primary, size: 28),
        const SizedBox(width: 12),
        Text('Diary', style: TatvaText.h2.copyWith(color: TatvaColors.neutral900)),
        const Spacer(),
        if (widget.fixedClassId == null && widget.classes.length > 1)
          _buildClassDropdown(),
      ]),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: TatvaColors.neutral100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isDense: true,
          style: TatvaText.body.copyWith(color: TatvaColors.neutral800, fontSize: 13),
          icon: const Icon(Icons.arrow_drop_down_rounded, size: 20, color: TatvaColors.neutral600),
          items: widget.classes.map((c) => DropdownMenuItem(
            value: c.id,
            child: Text(c.name, overflow: TextOverflow.ellipsis),
          )).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _selectedClassId = val);
            _loadEntries();
          },
        ),
      ),
    );
  }

  Widget _buildCalendarStrip() {
    final now = DateTime.now();
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            onPressed: () => _onDateSelected(_selectedDate.subtract(const Duration(days: 7))),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _monthExpanded = !_monthExpanded),
              child: Text(
                _formatMonthYear(_selectedDate),
                textAlign: TextAlign.center,
                style: TatvaText.label.copyWith(color: TatvaColors.neutral800),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            onPressed: () => _onDateSelected(_selectedDate.add(const Duration(days: 7))),
          ),
        ]),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final day = weekStart.add(Duration(days: i));
            final isSelected = day.day == _selectedDate.day &&
                day.month == _selectedDate.month &&
                day.year == _selectedDate.year;
            final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
            return GestureDetector(
              onTap: () => _onDateSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected ? TatvaColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isToday && !isSelected
                      ? Border.all(color: TatvaColors.primaryLight, width: 1.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayLabel(day.weekday),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white70 : TatvaColors.neutral500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : TatvaColors.neutral800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildMonthGrid() {
    final firstOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final startWeekday = firstOfMonth.weekday;
    final now = DateTime.now();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4,
        ),
        itemCount: daysInMonth + startWeekday - 1,
        itemBuilder: (_, index) {
          if (index < startWeekday - 1) return const SizedBox();
          final day = index - startWeekday + 2;
          final date = DateTime(_selectedDate.year, _selectedDate.month, day);
          final isSelected = date.day == _selectedDate.day;
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
          return GestureDetector(
            onTap: () {
              _onDateSelected(date);
              setState(() => _monthExpanded = false);
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? TatvaColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isSelected ? Border.all(color: TatvaColors.primaryLight) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : TatvaColors.neutral700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ShimmerPlaceholder();
    if (_selectedClassId.isEmpty) {
      return _buildEmptyState('No class selected', Icons.class_outlined);
    }
    if (_entries.isEmpty) {
      return _buildEmptyState('No diary entries for this day', Icons.menu_book_outlined);
    }
    return RefreshIndicator(
      onRefresh: _loadEntries,
      color: TatvaColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _entries.length,
        itemBuilder: (_, i) => FadeSlideIn(
          delayMs: i * 80,
          child: _DiaryEntryCard(
            entry: _entries[i],
            onTap: () => _openEntry(_entries[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: FadeSlideIn(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: TatvaColors.neutral300),
          const SizedBox(height: 16),
          Text(message, style: TatvaText.body.copyWith(color: TatvaColors.neutral500)),
        ]),
      ),
    );
  }

  String _formatMonthYear(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return labels[weekday - 1];
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;

  const _DiaryEntryCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TatvaColors.neutral900.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: TatvaColors.primaryLight.withOpacity(0.2),
              child: Text(
                _initials(entry.teacherName),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TatvaColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(entry.title, style: TatvaText.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  entry.teacherName,
                  style: TatvaText.caption.copyWith(color: TatvaColors.neutral500),
                ),
              ]),
            ),
            if (entry.attachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TatvaColors.infoLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.attach_file_rounded, size: 14, color: TatvaColors.info),
                  const SizedBox(width: 2),
                  Text('${entry.attachments.length}', style: const TextStyle(fontSize: 11, color: TatvaColors.info, fontWeight: FontWeight.w600)),
                ]),
              ),
          ]),
          const SizedBox(height: 10),
          Text(
            entry.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TatvaText.body.copyWith(color: TatvaColors.neutral600, height: 1.4),
          ),
          if (entry.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _formatTime(entry.createdAt!),
              style: TatvaText.caption.copyWith(color: TatvaColors.neutral400, fontSize: 11),
            ),
          ],
        ]),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
