import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/announcement_model.dart';
import '../../models/audience.dart';
import '../../models/attachment.dart';
import '../../features/parent/parent_helpers.dart';
import '../../services/api_service.dart';
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
          if (a.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _AttachmentPreviewGrid(attachments: a.attachments),
          ],
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
          if (value == 'delete') _confirmDelete(context);
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

class _AttachmentPreviewGrid extends StatelessWidget {
  final List<Attachment> attachments;
  const _AttachmentPreviewGrid({required this.attachments});

  @override
  Widget build(BuildContext context) {
    if (attachments.length == 1) {
      return _buildSingle(context, attachments.first);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((a) => _buildThumbnail(context, a)).toList(),
    );
  }

  Widget _buildSingle(BuildContext context, Attachment att) {
    return switch (att.type) {
      AttachmentType.image => _ImagePreview(att: att, height: 180),
      AttachmentType.youtube => _YouTubePreview(att: att, height: 180),
      AttachmentType.video => _VideoPreview(att: att),
      AttachmentType.audio => _AudioPreview(att: att),
      AttachmentType.pdf => _PdfPreview(att: att),
      _ => _LinkPreview(att: att),
    };
  }

  Widget _buildThumbnail(BuildContext context, Attachment att) {
    return SizedBox(
      width: 100,
      height: 100,
      child: switch (att.type) {
        AttachmentType.image => _ImagePreview(att: att, height: 100),
        AttachmentType.youtube => _YouTubePreview(att: att, height: 100),
        AttachmentType.video => _VideoPreview(att: att, compact: true),
        AttachmentType.audio => _AudioPreview(att: att, compact: true),
        AttachmentType.pdf => _PdfPreview(att: att, compact: true),
        _ => _LinkPreview(att: att, compact: true),
      },
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Attachment att;
  final double height;
  const _ImagePreview({required this.att, required this.height});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          att.url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: height,
              color: TatvaColors.bgLight,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: height,
            decoration: BoxDecoration(
              color: TatvaColors.bgLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(Icons.broken_image, color: TatvaColors.neutral400)),
          ),
        ),
      ),
    );
  }
}

class _YouTubePreview extends StatelessWidget {
  final Attachment att;
  final double height;
  const _YouTubePreview({required this.att, required this.height});

  @override
  Widget build(BuildContext context) {
    final videoId = Attachment.extractYouTubeId(att.url);
    final thumb = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
        : att.thumbnailUrl;

    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(children: [
          if (thumb != null)
            Image.network(thumb,
                height: height,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(height))
          else
            _placeholder(height),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder(double h) => Container(
        height: h,
        color: Colors.grey.shade800,
        child: Center(child: Icon(Icons.smart_display, color: Colors.white54, size: 40)),
      );
}

class _VideoPreview extends StatelessWidget {
  final Attachment att;
  final bool compact;
  const _VideoPreview({required this.att, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: Container(
        height: compact ? null : 60,
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: TatvaColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: compact
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam_outlined, color: TatvaColors.info, size: 28),
                const SizedBox(height: 4),
                Text(att.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: TatvaColors.neutral600)),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TatvaColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.videocam_outlined, color: TatvaColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(att.name.isNotEmpty ? att.name : 'Video',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                    Text('Tap to play', style: TextStyle(fontSize: 10, color: TatvaColors.neutral400)),
                  ]),
                ),
                Icon(Icons.play_circle_outline, color: TatvaColors.info),
              ]),
      ),
    );
  }
}

class _AudioPreview extends StatelessWidget {
  final Attachment att;
  final bool compact;
  const _AudioPreview({required this.att, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: Container(
        height: compact ? null : 60,
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: TatvaColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: compact
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.headphones_outlined, color: TatvaColors.purple, size: 28),
                const SizedBox(height: 4),
                Text(att.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: TatvaColors.neutral600)),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TatvaColors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.headphones_outlined, color: TatvaColors.purple, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(att.name.isNotEmpty ? att.name : 'Audio',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                    Text('Tap to play', style: TextStyle(fontSize: 10, color: TatvaColors.neutral400)),
                  ]),
                ),
                Icon(Icons.play_circle_outline, color: TatvaColors.purple),
              ]),
      ),
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final Attachment att;
  final bool compact;
  const _PdfPreview({required this.att, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: Container(
        height: compact ? null : 60,
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: TatvaColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: compact
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.picture_as_pdf, color: TatvaColors.error, size: 28),
                const SizedBox(height: 4),
                Text(att.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: TatvaColors.neutral600)),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TatvaColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: TatvaColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(att.name.isNotEmpty ? att.name : 'PDF Document',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
                    Text('Tap to open', style: TextStyle(fontSize: 10, color: TatvaColors.neutral400)),
                  ]),
                ),
                Icon(Icons.open_in_new, size: 18, color: TatvaColors.neutral400),
              ]),
      ),
    );
  }
}

class _LinkPreview extends StatelessWidget {
  final Attachment att;
  final bool compact;
  const _LinkPreview({required this.att, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openUrl(att.url),
      child: Container(
        height: compact ? null : 60,
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: TatvaColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: compact
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.link, color: TatvaColors.info, size: 28),
                const SizedBox(height: 4),
                Text(att.name.isNotEmpty ? att.name : att.url,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: TatvaColors.neutral600)),
              ])
            : Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: TatvaColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.link, color: TatvaColors.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(att.name.isNotEmpty ? att.name : att.url,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                ),
                Icon(Icons.open_in_new, size: 18, color: TatvaColors.neutral400),
              ]),
      ),
    );
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri != null && await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class EditAnnouncementSheet {
  static void show(
    BuildContext context, {
    required AnnouncementModel announcement,
    required List<String> availableGrades,
    required ApiService api,
    required Future<void> Function(String title, String body, List<String> grades, List<Map<String, dynamic>> attachments) onSave,
  }) {
    final titleCtl = TextEditingController(text: announcement.title);
    final bodyCtl = TextEditingController(text: announcement.body);
    bool isEveryone = announcement.audience == Audience.everyone;
    Set<String> selectedGrades = Set.from(announcement.grades);
    List<Attachment> existingAttachments = List.of(announcement.attachments);
    List<_PendingFile> newFiles = [];
    List<Attachment> newUrlAttachments = [];
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  const SizedBox(height: 16),
                  _buildAttachmentSection(
                    ctx,
                    existingAttachments: existingAttachments,
                    newFiles: newFiles,
                    newUrlAttachments: newUrlAttachments,
                    setModalState: setModalState,
                  ),
                  const SizedBox(height: 20),
                  BouncyTap(
                    onTap: isSaving ? null : () async {
                      if (titleCtl.text.trim().isEmpty) return;
                      if (!isEveryone && selectedGrades.isEmpty) return;
                      setModalState(() => isSaving = true);
                      try {
                        final grades = isEveryone ? <String>[] : selectedGrades.toList()..sort();

                        List<Map<String, dynamic>> allAttachments = [
                          ...existingAttachments.map((a) => a.toJson()),
                          ...newUrlAttachments.map((a) => a.toJson()),
                        ];

                        if (newFiles.isNotEmpty) {
                          final uploaded = await api.uploadAnnouncementFiles(
                            newFiles.map((f) => f.bytes).toList(),
                            newFiles.map((f) => f.name).toList(),
                          );
                          allAttachments.addAll(uploaded);
                        }

                        await onSave(titleCtl.text.trim(), bodyCtl.text.trim(), grades, allAttachments);
                        if (context.mounted) Navigator.pop(context);
                      } finally {
                        if (ctx.mounted) setModalState(() => isSaving = false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSaving ? TatvaColors.neutral400 : TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isSaving ? [] : [BoxShadow(color: TatvaColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: isSaving
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Save Changes',
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

  static Widget _buildAttachmentSection(
    BuildContext context, {
    required List<Attachment> existingAttachments,
    required List<_PendingFile> newFiles,
    required List<Attachment> newUrlAttachments,
    required StateSetter setModalState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Attachments',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
          const Spacer(),
          _attachBtn(Icons.attach_file, 'File', () async {
            final result = await FilePicker.platform.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'mp4', 'mov', 'mp3', 'wav', 'aac'],
            );
            if (result != null) {
              setModalState(() {
                for (final f in result.files) {
                  if (f.bytes != null) {
                    newFiles.add(_PendingFile(f.name, f.bytes!));
                  }
                }
              });
            }
          }),
          const SizedBox(width: 8),
          _attachBtn(Icons.link, 'URL', () {
            _showAddUrlDialog(context, (att) {
              setModalState(() => newUrlAttachments.add(att));
            });
          }),
        ]),
        if (existingAttachments.isNotEmpty || newFiles.isNotEmpty || newUrlAttachments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...existingAttachments.asMap().entries.map((e) => _fileChip(
                  e.value.name.isNotEmpty ? e.value.name : _typeLabel(e.value.type),
                  icon: _typeIcon(e.value.type),
                  onRemove: () => setModalState(() => existingAttachments.removeAt(e.key)),
                )),
            ...newFiles.asMap().entries.map((e) => _fileChip(
                  e.value.name,
                  onRemove: () => setModalState(() => newFiles.removeAt(e.key)),
                )),
            ...newUrlAttachments.asMap().entries.map((e) => _fileChip(
                  e.value.isYouTube ? 'YouTube: ${e.value.name}' : e.value.name.isEmpty ? e.value.url : e.value.name,
                  icon: e.value.isYouTube ? Icons.play_circle_outline : Icons.link,
                  onRemove: () => setModalState(() => newUrlAttachments.removeAt(e.key)),
                )),
          ]),
        ],
      ],
    );
  }

  static Widget _attachBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TatvaColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TatvaColors.primary.withOpacity(0.15)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: TatvaColors.primary),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TatvaColors.primary)),
        ]),
      ),
    );
  }

  static Widget _fileChip(String label, {IconData icon = Icons.insert_drive_file, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: TatvaColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: TatvaColors.neutral600),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: TatvaColors.neutral600)),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: onRemove,
          child: Icon(Icons.close, size: 14, color: TatvaColors.neutral400),
        ),
      ]),
    );
  }

  static void _showAddUrlDialog(BuildContext context, void Function(Attachment) onAdd) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://youtube.com/watch?v=...',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              final type = Attachment.inferType(url);
              final name = type == AttachmentType.youtube
                  ? (Attachment.extractYouTubeId(url) ?? 'video')
                  : url.split('/').last;
              onAdd(Attachment(
                url: url,
                type: type,
                name: name,
                thumbnailUrl: type == AttachmentType.youtube
                    ? 'https://img.youtube.com/vi/${Attachment.extractYouTubeId(url)}/hqdefault.jpg'
                    : null,
              ));
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  static IconData _typeIcon(AttachmentType type) => switch (type) {
        AttachmentType.image => Icons.image,
        AttachmentType.video => Icons.videocam_outlined,
        AttachmentType.audio => Icons.headphones_outlined,
        AttachmentType.pdf => Icons.picture_as_pdf,
        AttachmentType.youtube => Icons.play_circle_outline,
        _ => Icons.link,
      };

  static String _typeLabel(AttachmentType type) => switch (type) {
        AttachmentType.image => 'Image',
        AttachmentType.video => 'Video',
        AttachmentType.audio => 'Audio',
        AttachmentType.pdf => 'PDF',
        AttachmentType.youtube => 'YouTube',
        _ => 'Link',
      };

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

class _PendingFile {
  final String name;
  final Uint8List bytes;
  const _PendingFile(this.name, this.bytes);
}
