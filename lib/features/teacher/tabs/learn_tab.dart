import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/content_item.dart';

class TeacherLearnTab extends StatelessWidget {
  final List<ContentItem> contentItems;
  final List<ClassModel> classes;
  final List<UserModel> allStudents;
  final String uid;
  final void Function(ContentItem) onContentAdded;
  final void Function(String) onContentDeleted;
  final void Function(ContentItem) onContentUpdated;

  const TeacherLearnTab({
    super.key,
    required this.contentItems,
    required this.classes,
    required this.allStudents,
    required this.uid,
    required this.onContentAdded,
    required this.onContentDeleted,
    required this.onContentUpdated,
  });

  List<String> get _availableGrades =>
      classes.map((c) => c.grade).where((g) => g.isNotEmpty).toSet().toList()
        ..sort();

  @override
  Widget build(BuildContext context) {
    final Map<String, List<ContentItem>> byCategory = {};
    for (final item in contentItems) {
      final key = '${item.category.emoji} ${item.category.label}';
      byCategory.putIfAbsent(key, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Beyond School',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text('${contentItems.length} learning items created by you',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 16),
        FadeSlideIn(
            delayMs: 80,
            child: GestureDetector(
              onTap: () => _showCreateSheet(context),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TatvaColors.primary.withOpacity(0.15))),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: TatvaColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.add_rounded,
                            color: TatvaColors.primary, size: 20)),
                    const SizedBox(width: 12),
                    const Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Create Learning Content',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.primary)),
                          SizedBox(height: 2),
                          Text(
                              'Assign to a grade or specific students',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: TatvaColors.neutral400)),
                        ])),
                    const Icon(Icons.chevron_right_rounded,
                        color: TatvaColors.primary, size: 20),
                  ])),
            )),
        const SizedBox(height: 20),
        if (contentItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 48,
                    color: TatvaColors.neutral400.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No content created yet',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.neutral400)),
                const SizedBox(height: 4),
                const Text('Tap above to create your first learning item',
                    style: TextStyle(
                        fontSize: 12, color: TatvaColors.neutral400)),
              ]),
            ),
          )
        else
          ...byCategory.entries.toList().asMap().entries.map((entry) {
            final catIdx = entry.key;
            final catLabel = entry.value.key;
            final items = entry.value.value;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIdx > 0) const SizedBox(height: 20),
                  StaggeredItem(
                    index: catIdx,
                    child: Text(catLabel,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((itemEntry) {
                    final ci = itemEntry.value;
                    return StaggeredItem(
                      index: catIdx * 10 + itemEntry.key,
                      child: _ContentCard(
                        item: ci,
                        allStudents: allStudents,
                        onTap: () => _showEditSheet(context, ci),
                        onDelete: () => _confirmDelete(context, ci),
                      ),
                    );
                  }),
                ]);
          }),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _showCreateSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentFormSheet(
        grades: _availableGrades,
        allStudents: allStudents,
        onSave: (item) async {
          try {
            final result = await ApiService().createContent(
              title: item.title,
              description: item.description,
              category: item.category.name,
              duration: item.duration,
              grade: item.grade,
              studentUids: item.studentUids,
            );
            final created = ContentItem.fromJson(
                Map<String, dynamic>.from(result));
            onContentAdded(created);
            if (context.mounted) {
              TatvaSnackbar.show(context, 'Content created');
            }
          } catch (e) {
            if (context.mounted) {
              TatvaSnackbar.show(context, 'Failed to create content');
            }
          }
        },
      ),
    );
  }

  void _showEditSheet(BuildContext context, ContentItem existing) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContentFormSheet(
        existing: existing,
        grades: _availableGrades,
        allStudents: allStudents,
        onSave: (item) async {
          try {
            await ApiService().updateContent(
              existing.id,
              title: item.title,
              description: item.description,
              category: item.category.name,
              duration: item.duration,
              grade: item.grade,
              studentUids: item.studentUids,
            );
            onContentUpdated(item.copyWith(id: existing.id));
            if (context.mounted) {
              TatvaSnackbar.show(context, 'Content updated');
            }
          } catch (e) {
            if (context.mounted) {
              TatvaSnackbar.show(context, 'Failed to update content');
            }
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ContentItem ci) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Content',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${ci.title}"? This cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: TatvaColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteContent(ci.id);
                onContentDeleted(ci.id);
                if (context.mounted) {
                  TatvaSnackbar.show(context, 'Content deleted');
                }
              } catch (e) {
                if (context.mounted) {
                  TatvaSnackbar.show(context, 'Failed to delete');
                }
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: TatvaColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Content Card ──────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final ContentItem item;
  final List<UserModel> allStudents;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ContentCard({
    required this.item,
    required this.allStudents,
    required this.onTap,
    required this.onDelete,
  });

  String get _audienceLabel {
    if (item.studentUids.isNotEmpty) {
      final count = item.studentUids.length;
      return '$count student${count == 1 ? '' : 's'}';
    }
    if (item.grade.isNotEmpty) return 'Grade ${item.grade}';
    return 'Everyone';
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = item.completedBy.length;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100)),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: TatvaColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.auto_stories_rounded,
                  color: TatvaColors.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                if (item.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            color: TatvaColors.neutral600,
                            height: 1.4)),
                  ),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: TatvaColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(_audienceLabel,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: TatvaColors.info)),
                  ),
                  if (item.duration.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule_rounded,
                        size: 11, color: TatvaColors.neutral400),
                    const SizedBox(width: 3),
                    Text(item.duration,
                        style: const TextStyle(
                            fontSize: 10, color: TatvaColors.neutral400)),
                  ],
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle_outline_rounded,
                      size: 11, color: TatvaColors.success),
                  const SizedBox(width: 3),
                  Text('$completedCount done',
                      style: const TextStyle(
                          fontSize: 10, color: TatvaColors.success)),
                ]),
              ])),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: TatvaColors.neutral400),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    );
  }
}

// ─── Create / Edit Form Sheet ──────────────────────────────────────────────

enum _TargetMode { everyone, grade, students }

class _ContentFormSheet extends StatefulWidget {
  final ContentItem? existing;
  final List<String> grades;
  final List<UserModel> allStudents;
  final Future<void> Function(ContentItem item) onSave;

  const _ContentFormSheet({
    this.existing,
    required this.grades,
    required this.allStudents,
    required this.onSave,
  });

  @override
  State<_ContentFormSheet> createState() => _ContentFormSheetState();
}

class _ContentFormSheetState extends State<_ContentFormSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  ContentCategory _category = ContentCategory.creativity;
  _TargetMode _targetMode = _TargetMode.everyone;
  String _selectedGrade = '';
  final Set<String> _selectedStudentUids = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _durationCtrl.text = e.duration;
      _category = e.category;
      if (e.studentUids.isNotEmpty) {
        _targetMode = _TargetMode.students;
        _selectedStudentUids.addAll(e.studentUids);
      } else if (e.grade.isNotEmpty) {
        _targetMode = _TargetMode.grade;
        _selectedGrade = e.grade;
      }
    }
    if (_selectedGrade.isEmpty && widget.grades.isNotEmpty) {
      _selectedGrade = widget.grades.first;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final item = ContentItem(
      title: title,
      description: _descCtrl.text.trim(),
      category: _category,
      duration: _durationCtrl.text.trim(),
      grade: _targetMode == _TargetMode.grade ? _selectedGrade : '',
      studentUids:
          _targetMode == _TargetMode.students ? _selectedStudentUids.toList() : [],
    );
    await widget.onSave(item);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 12),
        Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Expanded(
                child: Text(isEdit ? 'Edit Content' : 'New Learning Content',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900))),
            if (_saving)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildTextField(_titleCtrl, 'Title', 'e.g. Breathing Buddies'),
              const SizedBox(height: 12),
              _buildTextField(_descCtrl, 'Description',
                  'What will students learn?',
                  maxLines: 3),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _buildTextField(
                        _durationCtrl, 'Duration', 'e.g. 5 min')),
                const SizedBox(width: 12),
                Expanded(child: _buildCategoryDropdown()),
              ]),
              const SizedBox(height: 16),
              const Text('Assign to',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TatvaColors.neutral900)),
              const SizedBox(height: 8),
              _buildTargetSelector(),
              if (_targetMode == _TargetMode.grade) ...[
                const SizedBox(height: 12),
                _buildGradeSelector(),
              ],
              if (_targetMode == _TargetMode.students) ...[
                const SizedBox(height: 12),
                _buildStudentSelector(),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TatvaColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isEdit ? 'Save Changes' : 'Create',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, String hint,
      {int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TatvaColors.neutral600)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(fontSize: 13, color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: TatvaColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _buildCategoryDropdown() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Category',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TatvaColors.neutral600)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ContentCategory>(
            value: _category,
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: TatvaColors.neutral900),
            items: ContentCategory.values
                .map((c) => DropdownMenuItem(
                    value: c, child: Text('${c.emoji} ${c.label}')))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
        ),
      ),
    ]);
  }

  Widget _buildTargetSelector() {
    return Row(children: [
      _targetChip('Everyone', _TargetMode.everyone),
      const SizedBox(width: 8),
      _targetChip('Grade', _TargetMode.grade),
      const SizedBox(width: 8),
      _targetChip('Students', _TargetMode.students),
    ]);
  }

  Widget _targetChip(String label, _TargetMode mode) {
    final selected = _targetMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _targetMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? TatvaColors.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected
                  ? TatvaColors.primary.withOpacity(0.3)
                  : Colors.grey.shade200),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? TatvaColors.primary : TatvaColors.neutral600)),
      ),
    );
  }

  Widget _buildGradeSelector() {
    if (widget.grades.isEmpty) {
      return const Text('No grades available from your classes',
          style: TextStyle(fontSize: 12, color: TatvaColors.neutral400));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.grades.map((g) {
        final selected = _selectedGrade == g;
        return GestureDetector(
          onTap: () => setState(() => _selectedGrade = g),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? TatvaColors.primary.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: selected
                      ? TatvaColors.primary.withOpacity(0.3)
                      : Colors.grey.shade200),
            ),
            child: Text('Grade $g',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? TatvaColors.primary
                        : TatvaColors.neutral600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudentSelector() {
    final students = widget.allStudents;
    if (students.isEmpty) {
      return const Text('No students available',
          style: TextStyle(fontSize: 12, color: TatvaColors.neutral400));
    }
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200)),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: students.length,
        itemBuilder: (_, i) {
          final s = students[i];
          final selected = _selectedStudentUids.contains(s.uid);
          return CheckboxListTile(
            value: selected,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(s.name,
                style: const TextStyle(fontSize: 13)),
            subtitle: s.email.isNotEmpty
                ? Text(s.email,
                    style: const TextStyle(fontSize: 10, color: TatvaColors.neutral400))
                : null,
            activeColor: TatvaColors.primary,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedStudentUids.add(s.uid);
                } else {
                  _selectedStudentUids.remove(s.uid);
                }
              });
            },
          );
        },
      ),
    );
  }
}
