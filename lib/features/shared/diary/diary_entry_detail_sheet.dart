import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/diary_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/animations/fade_slide_in.dart';

class DiaryEntryDetailSheet extends StatefulWidget {
  final DiaryEntry entry;
  final String uid;
  final String role;
  final ValueChanged<String> onEntryDeleted;
  final ValueChanged<DiaryEntry> onEntryUpdated;

  const DiaryEntryDetailSheet({
    super.key,
    required this.entry,
    required this.uid,
    required this.role,
    required this.onEntryDeleted,
    required this.onEntryUpdated,
  });

  @override
  State<DiaryEntryDetailSheet> createState() => _DiaryEntryDetailSheetState();
}

class _DiaryEntryDetailSheetState extends State<DiaryEntryDetailSheet> {
  final _api = ApiService();
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late DiaryEntry _entry;
  List<DiaryComment> _comments = [];
  bool _loadingComments = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final raw = await _api.getDiaryComments(_entry.id);
      _comments = raw.map((e) => DiaryComment.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Load comments error: $e');
    }
    if (mounted) setState(() => _loadingComments = false);
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _api.createDiaryComment(_entry.id, text);
      _commentCtrl.clear();
      await _loadComments();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteComment(DiaryComment comment) async {
    final confirmed = await _showConfirmDialog('Delete this comment?');
    if (!confirmed) return;
    try {
      await _api.deleteDiaryComment(comment.id);
      setState(() => _comments.removeWhere((c) => c.id == comment.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirmed = await _showConfirmDialog('Delete this diary entry and all its comments?');
    if (!confirmed) return;
    try {
      await _api.deleteDiaryEntry(_entry.id);
      widget.onEntryDeleted(_entry.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
  }

  Future<void> _deleteAttachment(DiaryAttachment att) async {
    final confirmed = await _showConfirmDialog('Delete this file?');
    if (!confirmed) return;
    try {
      await _api.deleteDiaryAttachment(entryId: _entry.id, storagePath: att.storagePath);
      setState(() {
        _entry = _entry.copyWith(
          attachments: _entry.attachments.where((a) => a.storagePath != att.storagePath).toList(),
        );
      });
      widget.onEntryUpdated(_entry);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
  }

  Future<void> _uploadEntryFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.bytes != null)
        .map((f) => MapEntry(f.name, f.bytes!))
        .toList();

    try {
      final uploaded = await _api.uploadDiaryEntryFiles(_entry.id, files);
      final newAtts = uploaded.map((e) => DiaryAttachment.fromJson(e)).toList();
      setState(() {
        _entry = _entry.copyWith(attachments: [..._entry.attachments, ...newAtts]);
      });
      widget.onEntryUpdated(_entry);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
  }

  Future<void> _uploadCommentFiles(DiaryComment comment) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true, type: FileType.any);
    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.bytes != null)
        .map((f) => MapEntry(f.name, f.bytes!))
        .toList();

    try {
      await _api.uploadDiaryCommentFiles(comment.id, files);
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
  }

  Future<void> _openFile(DiaryAttachment att) async {
    final uri = Uri.parse(att.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: TatvaColors.error)),
          ),
        ],
      ),
    ) ?? false;
  }

  bool get _canEditEntry =>
      widget.role == 'Principal' || _entry.teacherUid == widget.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      appBar: AppBar(
        backgroundColor: TatvaColors.bgCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TatvaColors.neutral800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Diary Entry', style: TatvaText.label.copyWith(color: TatvaColors.neutral900)),
        centerTitle: true,
        actions: [
          if (_canEditEntry) ...[
            IconButton(
              icon: const Icon(Icons.attach_file_rounded, color: TatvaColors.primary),
              onPressed: _uploadEntryFiles,
              tooltip: 'Upload files',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: TatvaColors.error),
              onPressed: _deleteEntry,
              tooltip: 'Delete entry',
            ),
          ],
        ],
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildEntryContent(),
              if (_entry.attachments.isNotEmpty) _buildAttachments(),
              const SizedBox(height: 24),
              _buildCommentsSection(),
            ]),
          ),
        ),
        _buildCommentInput(),
      ]),
    );
  }

  Widget _buildEntryContent() {
    return FadeSlideIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: TatvaColors.primaryLight.withOpacity(0.2),
              child: Text(
                _initials(_entry.teacherName),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: TatvaColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_entry.teacherName, style: TatvaText.label),
                if (_entry.createdAt != null)
                  Text(_formatDateTime(_entry.createdAt!), style: TatvaText.caption.copyWith(color: TatvaColors.neutral500)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Text(_entry.title, style: TatvaText.h3),
          const SizedBox(height: 10),
          Text(_entry.body, style: TatvaText.body.copyWith(color: TatvaColors.neutral700, height: 1.6)),
        ]),
      ),
    );
  }

  Widget _buildAttachments() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: _entry.attachments.map((att) {
        return GestureDetector(
          onTap: () => _openFile(att),
          onLongPress: _canEditEntry ? () => _deleteAttachment(att) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: TatvaColors.neutral100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: TatvaColors.neutral200),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_fileIcon(att.fileType), size: 18, color: TatvaColors.primary),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(att.fileName, style: TatvaText.caption, overflow: TextOverflow.ellipsis),
              ),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildCommentsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.forum_outlined, size: 18, color: TatvaColors.neutral600),
        const SizedBox(width: 6),
        Text(
          'Discussion (${_comments.length})',
          style: TatvaText.label.copyWith(color: TatvaColors.neutral700),
        ),
      ]),
      const SizedBox(height: 12),
      if (_loadingComments)
        const Center(child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: TatvaColors.primary, strokeWidth: 2),
        ))
      else if (_comments.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No comments yet. Be the first to ask a question!',
            style: TatvaText.body.copyWith(color: TatvaColors.neutral400),
          ),
        )
      else
        ...List.generate(_comments.length, (i) {
          final c = _comments[i];
          return FadeSlideIn(
            delayMs: i * 50,
            child: _CommentBubble(
              comment: c,
              isOwn: c.authorUid == widget.uid,
              onDelete: (c.authorUid == widget.uid || widget.role == 'Principal')
                  ? () => _deleteComment(c)
                  : null,
              onUpload: (c.authorUid == widget.uid || widget.role == 'Principal')
                  ? () => _uploadCommentFiles(c)
                  : null,
              onOpenFile: _openFile,
              onDeleteAttachment: (c.authorUid == widget.uid || widget.role == 'Principal')
                  ? (att) async {
                      final confirmed = await _showConfirmDialog('Delete this file?');
                      if (!confirmed) return;
                      await _api.deleteDiaryAttachment(commentId: c.id, storagePath: att.storagePath);
                      await _loadComments();
                    }
                  : null,
            ),
          );
        }),
    ]);
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: TatvaColors.bgCard,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _commentCtrl,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              hintStyle: TextStyle(color: TatvaColors.neutral400),
              filled: true,
              fillColor: TatvaColors.neutral50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _sendComment,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: TatvaColors.primary,
              shape: BoxShape.circle,
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day}/${dt.month}/${dt.year} at $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'image': return Icons.image_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      default: return Icons.description_rounded;
    }
  }
}

class _CommentBubble extends StatelessWidget {
  final DiaryComment comment;
  final bool isOwn;
  final VoidCallback? onDelete;
  final VoidCallback? onUpload;
  final ValueChanged<DiaryAttachment> onOpenFile;
  final ValueChanged<DiaryAttachment>? onDeleteAttachment;

  const _CommentBubble({
    required this.comment,
    required this.isOwn,
    this.onDelete,
    this.onUpload,
    required this.onOpenFile,
    this.onDeleteAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = comment.authorRole == 'Teacher' || comment.authorRole == 'Principal';
    return Align(
      alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isTeacher ? TatvaColors.primary.withOpacity(0.08) : TatvaColors.neutral100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isTeacher ? 14 : 4),
            bottomRight: Radius.circular(isTeacher ? 4 : 14),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              comment.authorName,
              style: TatvaText.caption.copyWith(
                fontWeight: FontWeight.w700,
                color: isTeacher ? TatvaColors.primary : TatvaColors.neutral700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isTeacher ? TatvaColors.primaryLight.withOpacity(0.2) : TatvaColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                comment.authorRole,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                  color: isTeacher ? TatvaColors.primary : TatvaColors.accentDark),
              ),
            ),
            const Spacer(),
            if (onUpload != null)
              GestureDetector(
                onTap: onUpload,
                child: const Icon(Icons.attach_file_rounded, size: 16, color: TatvaColors.neutral500),
              ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: TatvaColors.error),
              ),
            ],
          ]),
          const SizedBox(height: 6),
          Text(comment.body, style: TatvaText.body.copyWith(height: 1.4)),
          if (comment.attachments.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: comment.attachments.map((att) {
              return GestureDetector(
                onTap: () => onOpenFile(att),
                onLongPress: onDeleteAttachment != null ? () => onDeleteAttachment!(att) : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TatvaColors.neutral200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_fileIcon(att.fileType), size: 14, color: TatvaColors.info),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(att.fileName, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ),
              );
            }).toList()),
          ],
          if (comment.createdAt != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTime(comment.createdAt!),
              style: TextStyle(fontSize: 10, color: TatvaColors.neutral400),
            ),
          ],
        ]),
      ),
    );
  }

  IconData _fileIcon(String type) {
    switch (type) {
      case 'image': return Icons.image_rounded;
      case 'pdf': return Icons.picture_as_pdf_rounded;
      default: return Icons.description_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
