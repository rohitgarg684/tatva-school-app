import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/tatva_snackbar.dart';
import '../../services/api_service.dart';

class HomeworkCommentsSheet extends StatefulWidget {
  final String homeworkId;
  final String studentUid;
  final String studentName;
  final VoidCallback? onCommentAdded;

  const HomeworkCommentsSheet({
    super.key,
    required this.homeworkId,
    required this.studentUid,
    required this.studentName,
    this.onCommentAdded,
  });

  static void show(
    BuildContext context, {
    required String homeworkId,
    required String studentUid,
    required String studentName,
    VoidCallback? onCommentAdded,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HomeworkCommentsSheet(
        homeworkId: homeworkId,
        studentUid: studentUid,
        studentName: studentName,
        onCommentAdded: onCommentAdded,
      ),
    );
  }

  @override
  State<HomeworkCommentsSheet> createState() => _HomeworkCommentsSheetState();
}

class _HomeworkCommentsSheetState extends State<HomeworkCommentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await ApiService()
          .getSubmissionComments(widget.homeworkId, widget.studentUid);
      if (!mounted) return;
      setState(() { _comments = comments; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ApiService()
          .addSubmissionComment(widget.homeworkId, widget.studentUid, text);
      _ctrl.clear();
      widget.onCommentAdded?.call();
      await _load();
    } catch (_) {
      if (mounted) TatvaSnackbar.show(context, 'Failed to send');
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 14),
          Row(children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 16, color: TatvaColors.info),
            const SizedBox(width: 8),
            Expanded(child: Text(
                'Comments — ${widget.studentName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: TatvaColors.neutral900))),
          ]),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Flexible(
              child: _comments.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20),
                      child: Text('No comments yet', style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _commentBubble(_comments[i]),
                    ),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 13, color: TatvaColors.neutral900),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Write a comment...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: TatvaColors.bgLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: TatvaColors.info.withOpacity(0.5), width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: TatvaColors.info,
                    borderRadius: BorderRadius.circular(12)),
                child: _sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _commentBubble(Map<String, dynamic> c) {
    final name = c['authorName'] as String? ?? '';
    final role = c['authorRole'] as String? ?? '';
    final text = c['text'] as String? ?? '';
    final at = c['createdAt'] as String?;
    final isTeacher = role == 'Teacher' || role == 'Principal';
    final accent = isTeacher ? TatvaColors.accent : TatvaColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: accent.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withOpacity(0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 11,
              backgroundColor: accent.withOpacity(0.12),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: accent))),
          const SizedBox(width: 6),
          Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
                color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(role, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: accent)),
          ),
          const Spacer(),
          if (at != null)
            Text(_timeLabel(at), style: const TextStyle(fontSize: 9, color: TatvaColors.neutral400)),
        ]),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: TatvaColors.neutral800, height: 1.4)),
      ]),
    );
  }

  String _timeLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
