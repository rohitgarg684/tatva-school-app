import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../models/announcement_model.dart';
import '../../../models/audience.dart';
import '../../../models/attachment.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class NewAnnouncementSheet {
  static void show(
    BuildContext context, {
    required ApiService api,
    required String uid,
    required String userName,
    required String userRole,
    required List<String> availableGrades,
    required void Function(AnnouncementModel ann) onAnnouncementCreated,
  }) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isEveryone = true;
    Set<String> selectedGrades = {};
    List<_PendingAttachment> pendingFiles = [];
    List<Attachment> urlAttachments = [];
    bool isSending = false;
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2)))),
                  SizedBox(height: 20),
                  Row(children: [
                    Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: TatvaColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.campaign_outlined,
                            color: TatvaColors.primary, size: 18)),
                    SizedBox(width: 10),
                    Text('New Announcement',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                  ]),
                  SizedBox(height: 20),
                  Text('Send To',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  SizedBox(height: 8),
                  Row(children: [
                    _scopeChip(
                      label: 'Everyone',
                      selected: isEveryone,
                      onTap: () => setModalState(() {
                        isEveryone = true;
                        selectedGrades.clear();
                      }),
                    ),
                    SizedBox(width: 8),
                    _scopeChip(
                      label: 'Specific Grades',
                      selected: !isEveryone,
                      onTap: () => setModalState(() => isEveryone = false),
                    ),
                  ]),
                  if (!isEveryone) ...[
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableGrades.map((g) {
                        final sel = selectedGrades.contains(g);
                        return GestureDetector(
                          onTap: () => setModalState(() {
                            sel ? selectedGrades.remove(g) : selectedGrades.add(g);
                          }),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? TatvaColors.primary : TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sel ? TatvaColors.primary : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              'Grade $g',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : TatvaColors.neutral400,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 16),
                  Text('Title',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _inputDecoration('e.g. School Closure Notice'),
                  ),
                  SizedBox(height: 14),
                  Text('Message',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  SizedBox(height: 8),
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _inputDecoration('Write your announcement here...'),
                  ),
                  SizedBox(height: 16),
                  _buildAttachmentSection(
                    ctx,
                    pendingFiles: pendingFiles,
                    urlAttachments: urlAttachments,
                    setModalState: setModalState,
                  ),
                  SizedBox(height: 20),
                  BouncyTap(
                    onTap: isSending ? null : () async {
                      if (titleController.text.trim().isEmpty) return;
                      if (!isEveryone && selectedGrades.isEmpty) return;
                      setModalState(() => isSending = true);
                      try {
                        final title = titleController.text.trim();
                        final body = bodyController.text.trim();
                        final grades = isEveryone ? <String>[] : selectedGrades.toList()..sort();

                        List<Map<String, dynamic>> allAttachments = [
                          ...urlAttachments.map((a) => a.toJson()),
                        ];

                        if (pendingFiles.isNotEmpty) {
                          final uploaded = await api.uploadAnnouncementFiles(
                            pendingFiles.map((f) => f.bytes).toList(),
                            pendingFiles.map((f) => f.name).toList(),
                          );
                          allAttachments.addAll(uploaded);
                        }

                        await api.createAnnouncement(
                          title: title,
                          body: body,
                          grades: grades,
                          attachments: allAttachments,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        final newAnn = AnnouncementModel(
                          id: '',
                          title: title,
                          body: body,
                          audience: isEveryone ? Audience.everyone : Audience.grades,
                          grades: grades,
                          createdBy: uid,
                          createdByName: userName,
                          createdByRole: userRole,
                          attachments: allAttachments.map((a) => Attachment.fromJson(a)).toList(),
                        );
                        onAnnouncementCreated(newAnn);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              isEveryone
                                  ? 'Announcement sent to everyone!'
                                  : 'Announcement sent to Grade ${grades.join(", ")}!',
                              style: TextStyle()),
                          backgroundColor: TatvaColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ));
                      } finally {
                        if (ctx.mounted) setModalState(() => isSending = false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: isSending ? TatvaColors.neutral400 : TatvaColors.primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: isSending ? [] : [
                            BoxShadow(
                                color:
                                    TatvaColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: Offset(0, 4))
                          ]),
                      child: Center(
                          child: isSending
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text('Send Announcement',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white))),
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
    required List<_PendingAttachment> pendingFiles,
    required List<Attachment> urlAttachments,
    required StateSetter setModalState,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Attachments',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900)),
          Spacer(),
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
                    pendingFiles.add(_PendingAttachment(f.name, f.bytes!));
                  }
                }
              });
            }
          }),
          SizedBox(width: 8),
          _attachBtn(Icons.link, 'URL', () {
            _showAddUrlDialog(context, (att) {
              setModalState(() => urlAttachments.add(att));
            });
          }),
        ]),
        if (pendingFiles.isNotEmpty || urlAttachments.isNotEmpty) ...[
          SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ...pendingFiles.asMap().entries.map((e) => _fileChip(
                  e.value.name,
                  onRemove: () => setModalState(() => pendingFiles.removeAt(e.key)),
                )),
            ...urlAttachments.asMap().entries.map((e) => _fileChip(
                  e.value.isYouTube ? 'YouTube: ${e.value.name}' : e.value.name.isEmpty ? e.value.url : e.value.name,
                  icon: e.value.isYouTube ? Icons.play_circle_outline : Icons.link,
                  onRemove: () => setModalState(() => urlAttachments.removeAt(e.key)),
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
          SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: TatvaColors.primary)),
        ]),
      ),
    );
  }

  static Widget _fileChip(String label, {IconData icon = Icons.insert_drive_file, required VoidCallback onRemove}) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: TatvaColors.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: TatvaColors.neutral600),
        SizedBox(width: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 150),
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: TatvaColors.neutral600)),
        ),
        SizedBox(width: 2),
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

  static Widget _scopeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: selected ? TatvaColors.primary : TatvaColors.bgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? TatvaColors.primary : Colors.grey.shade200)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.white : TatvaColors.neutral400,
                      fontWeight: FontWeight.w600))),
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
      );
}

class _PendingAttachment {
  final String name;
  final Uint8List bytes;
  const _PendingAttachment(this.name, this.bytes);
}
