import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../models/homework_model.dart';
import '../../../services/api_service.dart';
import '../widgets/submit_work_sheet.dart';
import '../../shared/homework_comments_sheet.dart';

class StudentHomeworkTab extends StatelessWidget {
  final List<HomeworkModel> homework;
  final Set<String> completedIds;
  final Map<String, Map<String, dynamic>> mySubmissions;
  final String uid;
  final ApiService api;
  final void Function(String hwId, [Map<String, dynamic>? submission]) onMarkDone;
  final void Function(String hwId) onMarkIncomplete;
  final VoidCallback? onRefresh;

  const StudentHomeworkTab({
    super.key,
    required this.homework,
    required this.completedIds,
    required this.mySubmissions,
    required this.uid,
    required this.api,
    required this.onMarkDone,
    required this.onMarkIncomplete,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final pending =
        homework.where((h) => !completedIds.contains(h.id)).toList();
    final done =
        homework.where((h) => completedIds.contains(h.id)).toList();

    pending.sort((a, b) {
      final ua = _hwUrgency(a);
      final ub = _hwUrgency(b);
      if (ua != ub) return ua.compareTo(ub);
      final da = _parseDueDate(a.dueDate) ?? DateTime(2099);
      final db = _parseDueDate(b.dueDate) ?? DateTime(2099);
      return da.compareTo(db);
    });

    final overdue = pending.where((h) => _hwUrgency(h) == 0).toList();
    final urgent = pending.where((h) => _hwUrgency(h) == 1).toList();
    final thisWeek = pending.where((h) => _hwUrgency(h) == 2).toList();
    final later = pending.where((h) => _hwUrgency(h) == 3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Action Items',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text(
                '${pending.length} pending · ${done.length} done · all subjects',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        FadeSlideIn(
          delayMs: 80,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [TatvaColors.info.withOpacity(0.12), TatvaColors.info.withOpacity(0.04)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TatvaColors.info.withOpacity(0.15))),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${done.length}/${homework.length} completed',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0,
                            end: homework.isEmpty
                                ? 0.0
                                : done.length / homework.length),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: TatvaColors.info.withOpacity(0.1),
                          valueColor:
                              AlwaysStoppedAnimation(v >= 1.0 ? TatvaColors.success : TatvaColors.info),
                        ),
                      ),
                    ),
                  ])),
              const SizedBox(width: 16),
              Text(
                  homework.isEmpty
                      ? '—'
                      : '${(done.length / homework.length * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: done.length == homework.length ? TatvaColors.success : TatvaColors.info)),
            ]),
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            delayMs: 100,
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              if (overdue.isNotEmpty)
                _urgencyChip('${overdue.length} overdue', TatvaColors.error),
              if (urgent.isNotEmpty)
                _urgencyChip('${urgent.length} due today', TatvaColors.accent),
              if (thisWeek.isNotEmpty)
                _urgencyChip('${thisWeek.length} this week', TatvaColors.info),
              if (later.isNotEmpty)
                _urgencyChip('${later.length} upcoming', TatvaColors.neutral400),
            ]),
          ),
        ],
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 24),
          _hwSectionHeader('Overdue', Icons.warning_amber_rounded, TatvaColors.error),
          const SizedBox(height: 10),
          ...overdue.asMap().entries
              .map((e) => _hwStudentCard(context, e.value, e.key, false, urgency: 0)),
        ],
        if (urgent.isNotEmpty) ...[
          const SizedBox(height: 24),
          _hwSectionHeader(
              'Due Today', Icons.schedule_rounded, TatvaColors.accent),
          const SizedBox(height: 10),
          ...urgent.asMap().entries
              .map((e) => _hwStudentCard(context, e.value, e.key, false, urgency: 1)),
        ],
        if (thisWeek.isNotEmpty) ...[
          const SizedBox(height: 24),
          _hwSectionHeader(
              'This Week', Icons.date_range_rounded, TatvaColors.info),
          const SizedBox(height: 10),
          ...thisWeek.asMap().entries
              .map((e) => _hwStudentCard(context, e.value, e.key, false, urgency: 2)),
        ],
        if (later.isNotEmpty) ...[
          const SizedBox(height: 24),
          _hwSectionHeader('Upcoming', Icons.event_outlined, TatvaColors.neutral400),
          const SizedBox(height: 10),
          ...later.asMap().entries
              .map((e) => _hwStudentCard(context, e.value, e.key, false, urgency: 3)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 24),
          _hwSectionHeader(
              'Completed (${done.length})', Icons.check_circle_rounded, TatvaColors.success),
          const SizedBox(height: 10),
          ...done.asMap().entries
              .map((e) => _hwStudentCard(context, e.value, e.key, true)),
        ],
        const SizedBox(height: 28),
      ]),
    );
  }

  DateTime? _parseDueDate(String dueDate) => DateTime.tryParse(dueDate);

  int _hwUrgency(HomeworkModel hw) {
    final due = _parseDueDate(hw.dueDate);
    if (due == null) return 3;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff < 0) return 0;
    if (diff == 0) return 1;
    if (diff <= 7) return 2;
    return 3;
  }

  String _hwDueLabel(HomeworkModel hw) {
    final due = _parseDueDate(hw.dueDate);
    if (due == null) return hw.dueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final diff = dueDay.difference(today).inDays;
    if (diff < 0) return 'Overdue by ${-diff} day${diff == -1 ? '' : 's'}';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff <= 7) return 'Due in $diff days';
    return 'Due ${hw.dueDate}';
  }

  Widget _urgencyChip(String label, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c)),
      );

  Widget _mySubmissionSection(BuildContext context, HomeworkModel hw, Map<String, dynamic> sub) {
    final files = (sub['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final note = sub['note'] as String? ?? '';
    final status = sub['status'] as String? ?? 'pending';
    final commentCount = sub['commentCount'] as int? ?? 0;
    if (files.isEmpty && note.isEmpty) return const SizedBox.shrink();

    final Color statusColor;
    final String statusLabel;
    switch (status) {
      case 'accepted':
        statusColor = TatvaColors.success;
        statusLabel = 'Accepted';
      case 'returned':
        statusColor = TatvaColors.accent;
        statusLabel = 'Returned';
      default:
        statusColor = TatvaColors.info;
        statusLabel = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.15)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.upload_file_rounded, size: 13, color: statusColor),
          const SizedBox(width: 4),
          const Text('Your Submission',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TatvaColors.neutral900)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: statusColor.withOpacity(0.25))),
            child: Text(statusLabel,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ]),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(note, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: TatvaColors.neutral600, height: 1.4)),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: files.map((f) {
            final type = f['type'] as String? ?? 'link';
            final fName = f['name'] as String? ?? 'File';
            final fUrl = f['url'] as String? ?? '';
            final isImg = type == 'image';
            final ac = isImg ? TatvaColors.info : TatvaColors.error;
            return Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () {
                  if (fUrl.isNotEmpty) launchUrl(Uri.parse(fUrl), mode: LaunchMode.externalApplication);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: ac.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ac.withOpacity(0.15))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isImg ? Icons.image_rounded : Icons.picture_as_pdf_rounded, size: 12, color: ac),
                    const SizedBox(width: 4),
                    Text(fName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ac)),
                    const SizedBox(width: 2),
                    Icon(Icons.open_in_new_rounded, size: 9, color: ac.withOpacity(0.6)),
                  ]),
                ),
              ),
              if (status != 'accepted')
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    try {
                      await api.deleteSubmissionFile(hw.id, fUrl);
                      if (context.mounted) {
                        TatvaSnackbar.show(context, 'File removed');
                        onRefresh?.call();
                      }
                    } catch (_) {
                      if (context.mounted) TatvaSnackbar.show(context, 'Failed to delete');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Icon(Icons.close_rounded, size: 14, color: TatvaColors.neutral400),
                  ),
                ),
            ]);
          }).toList()),
        ],
        const SizedBox(height: 8),
        Row(children: [
          if (status == 'returned')
            GestureDetector(
              onTap: () => SubmitWorkSheet.show(
                context,
                hw: hw,
                color: TatvaColors.accent,
                api: api,
                onSubmitted: (submission) {
                  onMarkDone(hw.id, submission);
                  onRefresh?.call();
                },
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: TatvaColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TatvaColors.accent.withOpacity(0.2))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh_rounded, size: 13, color: TatvaColors.accent),
                  const SizedBox(width: 4),
                  Text('Re-submit', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: TatvaColors.accent)),
                ]),
              ),
            ),
          if (status == 'returned') const SizedBox(width: 6),
          GestureDetector(
            onTap: () => HomeworkCommentsSheet.show(
              context,
              homeworkId: hw.id,
              studentUid: uid,
              studentName: 'My Submission',
              onCommentAdded: onRefresh,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                  color: TatvaColors.neutral400.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_bubble_outline_rounded, size: 12, color: TatvaColors.neutral600),
                const SizedBox(width: 4),
                Text(commentCount > 0 ? '$commentCount' : 'Comment',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: TatvaColors.neutral600)),
              ]),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _hwSectionHeader(String title, IconData icon, Color c) => Row(
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text(title,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c)),
        ],
      );

  Widget _hwStudentCard(BuildContext context, HomeworkModel hw, int idx, bool isDone,
      {int urgency = 3}) {
    final isUrgent = !isDone && urgency <= 1;
    final Color color;
    if (isDone) {
      color = TatvaColors.success;
    } else if (urgency == 0) {
      color = TatvaColors.error;
    } else if (urgency == 1) {
      color = TatvaColors.accent;
    } else {
      color = TatvaColors.info;
    }
    final dueLabel = _hwDueLabel(hw);

    return StaggeredItem(
      index: idx,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isUrgent
                    ? color.withOpacity(0.4)
                    : isDone
                        ? TatvaColors.success.withOpacity(0.15)
                        : Colors.grey.shade100,
                width: isUrgent ? 1.5 : 1),
            boxShadow: isUrgent
                ? [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8)]
                : null),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.10), color.withOpacity(0.02)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : isUrgent
                              ? Icons.priority_high_rounded
                              : Icons.assignment_outlined,
                      color: color,
                      size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(hw.title,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            decorationColor: TatvaColors.neutral400)),
                    Text('${hw.subject} · ${hw.className}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: TatvaColors.neutral400)),
                  ])),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(dueLabel,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (hw.description.isNotEmpty)
                Text(hw.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        color: TatvaColors.neutral600,
                        height: 1.5)),
              if (hw.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: hw.attachments.map((a) {
                      IconData aIcon;
                      Color ac;
                      switch (a.type) {
                        case 'pdf':
                          aIcon = Icons.picture_as_pdf_rounded;
                          ac = TatvaColors.error;
                        case 'image':
                          aIcon = Icons.image_rounded;
                          ac = TatvaColors.info;
                        default:
                          aIcon = Icons.link_rounded;
                          ac = TatvaColors.primary;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: ac.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ac.withOpacity(0.15))),
                        child:
                            Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(aIcon, size: 14, color: ac),
                          const SizedBox(width: 4),
                          Text(a.name.isNotEmpty ? a.name : 'Attachment',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ac)),
                        ]),
                      );
                    }).toList()),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.person_outline, size: 12, color: TatvaColors.neutral400),
                const SizedBox(width: 4),
                Expanded(child: Text(hw.teacherName,
                    style: const TextStyle(
                        fontSize: 11, color: TatvaColors.neutral400))),
                GestureDetector(
                  onTap: () => HomeworkCommentsSheet.show(
                    context,
                    homeworkId: hw.id,
                    studentUid: uid,
                    studentName: 'My Questions',
                    onCommentAdded: onRefresh,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: TatvaColors.info.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: TatvaColors.info.withOpacity(0.15))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 12, color: TatvaColors.info),
                      const SizedBox(width: 4),
                      Text('Ask / Comment',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                    ]),
                  ),
                ),
              ]),
              if (mySubmissions.containsKey(hw.id)) ...[
                const SizedBox(height: 8),
                _mySubmissionSection(context, hw, mySubmissions[hw.id]!),
              ],
              const SizedBox(height: 12),
              if (!isDone)
                Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => SubmitWorkSheet.show(
                        context,
                        hw: hw,
                        color: color,
                        api: api,
                        onSubmitted: (submission) => onMarkDone(hw.id, submission),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: color.withOpacity(0.2))),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file_rounded,
                                  size: 16, color: color),
                              const SizedBox(width: 6),
                              Text('Submit Work',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMarkDone(hw.id);
                      TatvaSnackbar.show(context, 'Marked as done! 🎉');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                          color: TatvaColors.success.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: TatvaColors.success.withOpacity(0.2))),
                      child: Icon(Icons.check_rounded,
                          size: 16, color: TatvaColors.success),
                    ),
                  ),
                ])
              else
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onMarkIncomplete(hw.id);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.undo_rounded,
                              size: 16, color: TatvaColors.neutral400),
                          const SizedBox(width: 6),
                          Text('Mark as Incomplete',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: TatvaColors.neutral400)),
                        ]),
                  ),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
