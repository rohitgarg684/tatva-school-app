import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../models/diary_model.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/animations/fade_slide_in.dart';
import '../../../shared/widgets/shimmer_placeholder.dart';
import 'create_diary_entry_sheet.dart';
import 'diary_entry_detail_sheet.dart';

class DiaryScreen extends StatefulWidget {
  final List<ClassModel> classes;
  final List<UserModel> students;
  final String uid;
  final String role;
  /// For parents: fixed to their child's UID
  final String? fixedStudentUid;
  final String? fixedStudentName;

  const DiaryScreen({
    super.key,
    required this.classes,
    this.students = const [],
    required this.uid,
    required this.role,
    this.fixedStudentUid,
    this.fixedStudentName,
  });

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _api = ApiService();
  String _selectedStudentUid = '';
  String _selectedStudentName = '';
  late DateTime _selectedDate;
  List<DiaryEntry> _entries = [];
  Set<String> _datesWithEntries = {};
  bool _loading = true;
  bool _monthExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    if (widget.fixedStudentUid != null) {
      _selectedStudentUid = widget.fixedStudentUid!;
      _selectedStudentName = widget.fixedStudentName ?? '';
    } else if (widget.students.isNotEmpty) {
      _selectedStudentUid = widget.students.first.uid;
      _selectedStudentName = widget.students.first.name;
    }
    if (_selectedStudentUid.isNotEmpty) {
      _loadEntries();
      _loadMonthDots();
    } else {
      _loading = false;
    }
  }

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _monthStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}';

  Future<void> _loadEntries() async {
    if (_selectedStudentUid.isEmpty) return;
    setState(() => _loading = true);
    try {
      final raw = await _api.getDiaryEntries(_selectedStudentUid, _dateStr);
      _entries = raw.map((e) => DiaryEntry.fromJson(e)).toList();
    } catch (e) {
      debugPrint('DiaryScreen._loadEntries error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMonthDots() async {
    if (_selectedStudentUid.isEmpty) return;
    try {
      final dates = await _api.getDiaryDates(_selectedStudentUid, _monthStr);
      if (mounted) setState(() => _datesWithEntries = dates.toSet());
    } catch (e) {
      debugPrint('DiaryScreen._loadMonthDots error: $e');
    }
  }

  void _onDateSelected(DateTime date) {
    final monthChanged = date.month != _selectedDate.month || date.year != _selectedDate.year;
    setState(() => _selectedDate = date);
    _loadEntries();
    if (monthChanged) _loadMonthDots();
  }

  void _onStudentSelected(UserModel student) {
    setState(() {
      _selectedStudentUid = student.uid;
      _selectedStudentName = student.name;
    });
    _loadEntries();
    _loadMonthDots();
  }

  void _showStudentPicker() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StudentPickerSheet(
        students: widget.students,
        selectedUid: _selectedStudentUid,
        onSelect: (s) {
          Navigator.pop(context);
          _onStudentSelected(s);
        },
      ),
    );
  }

  void _showCreateEntry() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateDiaryEntrySheet(
        studentUid: _selectedStudentUid,
        studentName: _selectedStudentName,
        onCreated: (entry) {
          setState(() => _entries.insert(0, entry));
          _datesWithEntries.add(_dateStr);
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
      floatingActionButton: isTeacher && _selectedStudentUid.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCreateEntry,
              backgroundColor: TatvaColors.primary,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              label: const Text('Write Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isTeacher) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book_rounded, color: TatvaColors.primary, size: 28),
          const SizedBox(width: 12),
          Text('Diary', style: TatvaText.h2.copyWith(color: TatvaColors.neutral900)),
        ]),
        const SizedBox(height: 12),
        if (isTeacher && widget.fixedStudentUid == null)
          GestureDetector(
            onTap: _showStudentPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TatvaColors.neutral200),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: TatvaColors.primaryLight.withOpacity(0.2),
                  child: Text(
                    _selectedStudentName.isNotEmpty ? _selectedStudentName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TatvaColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedStudentName.isEmpty ? 'Select a student' : _selectedStudentName,
                    style: TatvaText.body.copyWith(
                      color: _selectedStudentName.isEmpty ? TatvaColors.neutral400 : TatvaColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.unfold_more_rounded, size: 20, color: TatvaColors.neutral500),
              ]),
            ),
          )
        else if (widget.fixedStudentName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.fixedStudentName!,
              style: TatvaText.body.copyWith(color: TatvaColors.neutral600, fontWeight: FontWeight.w600),
            ),
          ),
      ]),
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
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  _formatMonthYear(_selectedDate),
                  style: TatvaText.label.copyWith(color: TatvaColors.neutral800),
                ),
                Icon(
                  _monthExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 20, color: TatvaColors.neutral500,
                ),
              ]),
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
            final dayStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
            final hasEntry = _datesWithEntries.contains(dayStr);
            return GestureDetector(
              onTap: () => _onDateSelected(day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 42,
                height: 60,
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
                    const SizedBox(height: 3),
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasEntry
                            ? (isSelected ? Colors.white : TatvaColors.accent)
                            : Colors.transparent,
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
          final dayStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          final hasEntry = _datesWithEntries.contains(dayStr);
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : TatvaColors.neutral700,
                    ),
                  ),
                  if (hasEntry)
                    Container(
                      width: 4, height: 4, margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.white : TatvaColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedStudentUid.isEmpty) {
      return _buildEmptyState('Select a student to view diary', Icons.person_search_rounded);
    }
    if (_loading) return const ShimmerPlaceholder();
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

class _StudentPickerSheet extends StatefulWidget {
  final List<UserModel> students;
  final String selectedUid;
  final ValueChanged<UserModel> onSelect;

  const _StudentPickerSheet({
    required this.students,
    required this.selectedUid,
    required this.onSelect,
  });

  @override
  State<_StudentPickerSheet> createState() => _StudentPickerSheetState();
}

class _StudentPickerSheetState extends State<_StudentPickerSheet> {
  String _search = '';

  List<UserModel> get _filtered {
    if (_search.isEmpty) return widget.students;
    final q = _search.toLowerCase();
    return widget.students.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: TatvaColors.neutral300, borderRadius: BorderRadius.circular(2)))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Select Student', style: TatvaText.h3.copyWith(color: TatvaColors.neutral900)),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: TextStyle(color: TatvaColors.neutral400),
                prefixIcon: const Icon(Icons.search_rounded, color: TatvaColors.neutral400, size: 20),
                filled: true,
                fillColor: TatvaColors.neutral50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final s = _filtered[i];
              final selected = s.uid == widget.selectedUid;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                selected: selected,
                selectedTileColor: TatvaColors.primaryLight.withOpacity(0.1),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: selected ? TatvaColors.primary : TatvaColors.neutral200,
                  child: Text(
                    s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : TatvaColors.neutral700,
                    ),
                  ),
                ),
                title: Text(s.name, style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: TatvaColors.neutral900,
                )),
                trailing: selected ? const Icon(Icons.check_circle_rounded, color: TatvaColors.primary, size: 20) : null,
                onTap: () => widget.onSelect(s),
              );
            },
          ),
        ),
      ]),
    );
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
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
