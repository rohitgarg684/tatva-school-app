import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../models/audience.dart';
import '../../features/parent/parent_helpers.dart';
import '../theme/colors.dart';
import '../animations/animations.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final String currentUid;
  final String currentRole;
  final bool isFirst;
  final VoidCallback? onLike;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    required this.currentUid,
    this.currentRole = '',
    this.isFirst = false,
    this.onLike,
    this.onEdit,
    this.onDelete,
  });

  bool get _canManage =>
      announcement.createdBy == currentUid ||
      currentRole.toLowerCase() == 'principal';

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final liked = a.isLikedBy(currentUid);
    final likeCount = a.likedBy.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFirst
              ? TatvaColors.info.withOpacity(0.2)
              : Colors.grey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: TatvaColors.info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.campaign_outlined,
                  color: TatvaColors.info, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(a.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                    ),
                    if (isFirst)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: TatvaColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('New',
                            style: TextStyle(
                                fontSize: 10,
                                color: TatvaColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    if (_canManage) _buildMenu(context),
                  ]),
                  const SizedBox(height: 5),
                  Text(a.body,
                      style: const TextStyle(
                          fontSize: 12,
                          color: TatvaColors.neutral600,
                          height: 1.55)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _roleBadge(a.createdByRole),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                a.createdByName,
                style: const TextStyle(
                    fontSize: 10, color: TatvaColors.neutral400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (a.audience == Audience.grades && a.grades.isNotEmpty) ...[
              const SizedBox(width: 8),
              _gradeBadge(a.grades),
            ],
            const Spacer(),
            if (a.createdAt != null)
              Text(
                formatTimeAgo(a.createdAt!),
                style: const TextStyle(
                    fontSize: 10, color: TatvaColors.neutral400),
              ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            GestureDetector(
              onTap: onLike,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: liked ? TatvaColors.error : TatvaColors.neutral400,
                ),
                if (likeCount > 0) ...[
                  const SizedBox(width: 4),
                  Text('$likeCount',
                      style: TextStyle(
                          fontSize: 11,
                          color: liked
                              ? TatvaColors.error
                              : TatvaColors.neutral400,
                          fontWeight: FontWeight.w600)),
                ],
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(Icons.more_vert, size: 18, color: TatvaColors.neutral400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          if (value == 'edit') onEdit?.call();
          if (value == 'delete') {
            _confirmDelete(context);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            height: 36,
            child: Row(children: [
              Icon(Icons.edit_outlined, size: 16, color: TatvaColors.neutral600),
              const SizedBox(width: 8),
              Text('Edit', style: TextStyle(fontSize: 13, color: TatvaColors.neutral900)),
            ]),
          ),
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: Row(children: [
              Icon(Icons.delete_outline, size: 16, color: TatvaColors.error),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(fontSize: 13, color: TatvaColors.error)),
            ]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.warning_amber_rounded, color: TatvaColors.error, size: 40),
          const SizedBox(height: 12),
          Text('Delete Announcement?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TatvaColors.neutral900)),
          const SizedBox(height: 8),
          Text('This cannot be undone.',
              style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: BouncyTap(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: TatvaColors.bgLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text('Cancel',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TatvaColors.neutral600)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BouncyTap(
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: TatvaColors.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('Delete',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  static Widget _roleBadge(String role) {
    final color = switch (role.toLowerCase()) {
      'principal' => TatvaColors.purple,
      'teacher' => TatvaColors.info,
      _ => TatvaColors.neutral400,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }

  static Widget _gradeBadge(List<String> grades) {
    final label = grades.length <= 2
        ? grades.map((g) => 'Gr $g').join(', ')
        : '${grades.length} Grades';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TatvaColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: TatvaColors.warning)),
    );
  }
}

class EditAnnouncementSheet {
  static void show(
    BuildContext context, {
    required AnnouncementModel announcement,
    required List<String> availableGrades,
    required Future<void> Function(String title, String body, List<String> grades) onSave,
  }) {
    final titleCtl = TextEditingController(text: announcement.title);
    final bodyCtl = TextEditingController(text: announcement.body);
    bool isEveryone = announcement.audience == Audience.everyone;
    Set<String> selectedGrades = Set.from(announcement.grades);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 3,
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
                        color: TatvaColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.edit_outlined, color: TatvaColors.primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('Edit Announcement',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: TatvaColors.neutral900)),
                  ]),
                  const SizedBox(height: 20),
                  Text('Send To',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _scopeChip(label: 'Everyone', selected: isEveryone, onTap: () => setModalState(() {
                      isEveryone = true;
                      selectedGrades.clear();
                    })),
                    const SizedBox(width: 8),
                    _scopeChip(label: 'Specific Grades', selected: !isEveryone, onTap: () => setModalState(() => isEveryone = false)),
                  ]),
                  if (!isEveryone) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: availableGrades.map((g) {
                        final sel = selectedGrades.contains(g);
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            sel ? selectedGrades.remove(g) : selectedGrades.add(g);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? TatvaColors.primary : TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: sel ? TatvaColors.primary : Colors.grey.shade200),
                            ),
                            child: Text('Grade $g',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: sel ? Colors.white : TatvaColors.neutral400)),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text('Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtl,
                    style: TextStyle(fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _inputDec('Title'),
                  ),
                  const SizedBox(height: 14),
                  Text('Message', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bodyCtl,
                    maxLines: 3,
                    style: TextStyle(fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _inputDec('Message'),
                  ),
                  const SizedBox(height: 20),
                  BouncyTap(
                    onTap: () async {
                      if (titleCtl.text.trim().isEmpty) return;
                      if (!isEveryone && selectedGrades.isEmpty) return;
                      final grades = isEveryone ? <String>[] : selectedGrades.toList()..sort();
                      await onSave(titleCtl.text.trim(), bodyCtl.text.trim(), grades);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: TatvaColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: Text('Save Changes',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
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

  static Widget _scopeChip({required String label, required bool selected, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? TatvaColors.primary : TatvaColors.bgLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? TatvaColors.primary : Colors.grey.shade200),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(fontSize: 12, color: selected ? Colors.white : TatvaColors.neutral400, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  static InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
      );
}
