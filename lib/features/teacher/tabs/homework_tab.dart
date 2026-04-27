import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/homework_model.dart';
import '../../shared/homework_comments_sheet.dart';

class TeacherHomeworkTab extends StatelessWidget {
  final List<HomeworkModel> homework;
  final List<UserModel> students;
  final List<ClassModel> classes;
  final String uid;
  final UserModel? user;
  final void Function(HomeworkModel) onHomeworkAdded;
  final void Function(String) onHomeworkDeleted;

  const TeacherHomeworkTab({
    super.key,
    required this.homework,
    required this.students,
    required this.classes,
    required this.uid,
    required this.user,
    required this.onHomeworkAdded,
    required this.onHomeworkDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final active = homework;
    final done = <HomeworkModel>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Homework',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: TatvaColors.neutral900,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text('${active.length} active · ${done.length} completed',
                style: const TextStyle(
                    fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 16),
        FadeSlideIn(
            delayMs: 80,
            child: GestureDetector(
              onTap: () => _showPostHomeworkSheet(context),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TatvaColors.accent.withOpacity(0.25),
                          width: 1.5)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded,
                            color: TatvaColors.accent, size: 20),
                        const SizedBox(width: 8),
                        const Text('Post New Homework',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.accent)),
                      ])),
            )),
        if (active.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Active',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 12),
          ...active
              .asMap()
              .entries
              .map((e) => _hwCard(context, e.value, e.key)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Completed',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: TatvaColors.neutral400)),
          const SizedBox(height: 12),
          ...done
              .asMap()
              .entries
              .map((e) => _hwCard(context, e.value, e.key)),
        ],
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _hwCard(BuildContext context, HomeworkModel hw, int idx) {
    final subs = hw.submissionCount;
    final total = students.length;
    final pct = total > 0 ? subs / total : 0.0;
    final color = TatvaColors.accent;
    return StaggeredItem(
      index: idx,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.08),
                      color.withOpacity(0.02)
                    ]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.assignment_outlined,
                      color: color, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(hw.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                    Text('${hw.className} · ${hw.subject}',
                        style: const TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400)),
                  ])),
              GestureDetector(
                onTap: () => _deleteHomework(context, hw),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: TatvaColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded,
                      color: TatvaColors.error.withOpacity(0.5), size: 16),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hw.description.isNotEmpty)
                    Text(hw.description,
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
                          IconData icon;
                          Color c;
                          switch (a.type) {
                            case 'pdf':
                              icon = Icons.picture_as_pdf_rounded;
                              c = TatvaColors.error;
                            case 'image':
                              icon = Icons.image_rounded;
                              c = TatvaColors.info;
                            default:
                              icon = Icons.link_rounded;
                              c = TatvaColors.primary;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: c.withOpacity(0.15))),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: 14, color: c),
                                  const SizedBox(width: 4),
                                  Text(
                                      a.name.isNotEmpty
                                          ? a.name
                                          : 'Attachment',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: c)),
                                ]),
                          );
                        }).toList()),
                  ],
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 12, color: TatvaColors.neutral400),
                    const SizedBox(width: 4),
                    Text('Due ${hw.dueDate}',
                        style: const TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400)),
                    const Spacer(),
                    Text('$subs/$total submitted',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: pct),
                      duration: Duration(milliseconds: 600 + idx * 80),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        backgroundColor: color.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  if (subs > 0) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showSubmissions(context, hw),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                            color: TatvaColors.info.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: TatvaColors.info.withOpacity(0.15))),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.visibility_rounded,
                                  size: 14, color: TatvaColors.info),
                              const SizedBox(width: 6),
                              Text(
                                  'View $subs Submission${subs > 1 ? 's' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.info)),
                            ]),
                      ),
                    ),
                  ],
                ]),
          ),
        ]),
      ),
    );
  }

  void _showSubmissions(BuildContext context, HomeworkModel hw) async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmissionsSheet(hw: hw),
    );
  }

  void _deleteHomework(BuildContext context, HomeworkModel hw) {
    if (hw.id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete homework?',
            style: TextStyle(fontSize: 16)),
        content:
            Text(hw.title, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteHomework(hw.id);
                onHomeworkDeleted(hw.id);
                if (context.mounted) {
                  TatvaSnackbar.show(context, 'Homework deleted');
                }
              } catch (_) {
                if (context.mounted) {
                  TatvaSnackbar.show(context, 'Failed to delete');
                }
              }
            },
            child:
                Text('Delete', style: TextStyle(color: TatvaColors.error)),
          ),
        ],
      ),
    );
  }

  void _showPostHomeworkSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedClassId = classes[0].id;
    String selectedClassName = classes[0].name;
    String selectedSubject = classes[0].subject;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final attachments = <HomeworkAttachment>[];
    final pickedFiles = <MapEntry<String, Uint8List>>[];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                  const SizedBox(height: 20),
                  const Text('Post Homework',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900)),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClassId,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                            fontSize: 14, color: TatvaColors.neutral900),
                        items: classes
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text('${c.subject} — ${c.name}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: TatvaColors.neutral900)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final cls = classes.firstWhere((c) => c.id == v);
                          setModal(() {
                            selectedClassId = v;
                            selectedClassName = cls.name;
                            selectedSubject = cls.subject;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: _hwFieldDecor('Assignment title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration:
                        _hwFieldDecor('Instructions for students...'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx2, child) => Theme(
                          data: Theme.of(ctx2).copyWith(
                              colorScheme: ColorScheme.light(
                                  primary: TatvaColors.accent)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setModal(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: TatvaColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: TatvaColors.neutral400),
                        const SizedBox(width: 8),
                        Text(
                            'Due: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 14,
                                color: TatvaColors.neutral900)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Attachments',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral400)),
                  const SizedBox(height: 8),
                  ...attachments.asMap().entries.map((e) {
                    final a = e.value;
                    final i = e.key;
                    IconData icon;
                    Color c;
                    switch (a.type) {
                      case 'pdf':
                        icon = Icons.picture_as_pdf_rounded;
                        c = TatvaColors.error;
                      case 'image':
                        icon = Icons.image_rounded;
                        c = TatvaColors.info;
                      default:
                        icon = Icons.link_rounded;
                        c = TatvaColors.primary;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: c.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.withOpacity(0.15))),
                      child: Row(children: [
                        Icon(icon, size: 16, color: c),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                    a.name.isNotEmpty ? a.name : a.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: c)),
                                if (a.name.isNotEmpty)
                                  Text(a.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              TatvaColors.neutral400)),
                              ]),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setModal(() => attachments.removeAt(i)),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: TatvaColors.neutral400),
                        ),
                      ]),
                    );
                  }),
                  ...pickedFiles.asMap().entries.map((e) {
                    final f = e.value;
                    final ext = f.key.split('.').last.toLowerCase();
                    final isImg =
                        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: (isImg
                                  ? TatvaColors.info
                                  : TatvaColors.error)
                              .withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: (isImg
                                      ? TatvaColors.info
                                      : TatvaColors.error)
                                  .withOpacity(0.15))),
                      child: Row(children: [
                        Icon(
                            isImg
                                ? Icons.image_rounded
                                : Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: isImg
                                ? TatvaColors.info
                                : TatvaColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isImg
                                      ? TatvaColors.info
                                      : TatvaColors.error)),
                        ),
                        Text(
                            '${(f.value.length / 1024).toStringAsFixed(0)} KB',
                            style: const TextStyle(
                                fontSize: 10,
                                color: TatvaColors.neutral400)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setModal(
                              () => pickedFiles.removeAt(e.key)),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: TatvaColors.neutral400),
                        ),
                      ]),
                    );
                  }),
                  Row(children: [
                    _attachBtn('Upload\nFiles', Icons.upload_file_rounded,
                        TatvaColors.accent, () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf',
                          'jpg',
                          'jpeg',
                          'png',
                          'gif',
                          'webp',
                          'docx',
                          'xlsx',
                          'pptx'
                        ],
                        withData: true,
                      );
                      if (result == null) return;
                      setModal(() {
                        for (final f in result.files) {
                          if (f.bytes != null) {
                            pickedFiles
                                .add(MapEntry(f.name, f.bytes!));
                          }
                        }
                      });
                    }),
                    const SizedBox(width: 8),
                    _attachBtn(
                        'Add\nLink',
                        Icons.link_rounded,
                        TatvaColors.primary,
                        () => _addAttachment(
                            context, setModal, attachments, 'link')),
                  ]),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            setModal(() => isSubmitting = true);
                            final dueDateStr =
                                '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
                            final resp =
                                await ApiService().createHomework(
                              title: title,
                              classId: selectedClassId,
                              description: descCtrl.text.trim(),
                              subject: selectedSubject,
                              className: selectedClassName,
                              dueDate: dueDateStr,
                              attachments: attachments
                                  .map((a) => a.toJson())
                                  .toList(),
                            );
                            final newId =
                                resp['id'] as String? ?? '';

                            List<HomeworkAttachment> uploadedAtts = [
                              ...attachments
                            ];
                            if (pickedFiles.isNotEmpty &&
                                newId.isNotEmpty) {
                              final uploaded = await ApiService()
                                  .uploadHomeworkFiles(
                                      newId, pickedFiles);
                              for (final u in uploaded) {
                                uploadedAtts.add(HomeworkAttachment(
                                  url: u['url'] as String? ?? '',
                                  name: u['name'] as String? ?? '',
                                  type: u['type'] as String? ??
                                      'document',
                                ));
                              }
                            }

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            onHomeworkAdded(HomeworkModel(
                              id: newId,
                              title: title,
                              description: descCtrl.text.trim(),
                              subject: selectedSubject,
                              classId: selectedClassId,
                              className: selectedClassName,
                              teacherUid: uid,
                              teacherName: user?.name ?? '',
                              dueDate: dueDateStr,
                              attachments: uploadedAtts,
                              createdAt: DateTime.now(),
                            ));
                            TatvaSnackbar.show(
                                context, 'Homework posted!');
                          },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: TatvaColors.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: TatvaColors.accent
                                    .withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : const Text('Post Homework',
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

  InputDecoration _hwFieldDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TatvaColors.accent.withOpacity(0.5), width: 1.5)),
      );

  Widget _attachBtn(
          String label, IconData icon, Color c, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c)),
            ]),
          ),
        ),
      );

  static Widget _statusBadge(String status) {
    final Color c;
    final String label;
    switch (status) {
      case 'accepted':
        c = TatvaColors.success;
        label = 'Accepted';
      case 'returned':
        c = TatvaColors.accent;
        label = 'Returned';
      default:
        c = TatvaColors.info;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: c.withOpacity(0.25))),
      child: Text(label,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c)),
    );
  }

  void _addAttachment(BuildContext context, StateSetter setModal,
      List<HomeworkAttachment> attachments, String type) {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Add ${type == 'pdf' ? 'PDF' : type == 'image' ? 'Image' : 'Link'}',
            style: const TextStyle(fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: urlCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: type == 'link'
                  ? 'https://...'
                  : type == 'pdf'
                      ? 'PDF URL'
                      : 'Image URL',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Display name (optional)',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              setModal(() => attachments.add(HomeworkAttachment(
                    url: url,
                    name: nameCtrl.text.trim(),
                    type: type,
                  )));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _SubmissionsSheet extends StatefulWidget {
  final HomeworkModel hw;
  const _SubmissionsSheet({required this.hw});

  @override
  State<_SubmissionsSheet> createState() => _SubmissionsSheetState();
}

class _SubmissionsSheetState extends State<_SubmissionsSheet> {
  List<Map<String, dynamic>>? _subs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final subs = await ApiService().getHomeworkSubmissions(widget.hw.id);
      if (!mounted) return;
      setState(() { _subs = subs; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _setStatus(int index, String studentUid, String status) async {
    try {
      await ApiService().updateSubmissionStatus(widget.hw.id, studentUid, status);
      if (!mounted) return;
      setState(() { _subs![index]['status'] = status; });
      TatvaSnackbar.show(context, status == 'accepted' ? 'Accepted' : 'Returned');
    } catch (_) {
      if (mounted) TatvaSnackbar.show(context, 'Failed to update');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subs = _subs ?? [];
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: subs.isEmpty && _error == null ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Submissions — ${widget.hw.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: TatvaColors.neutral900)),
          const SizedBox(height: 4),
          Text('${subs.length} student${subs.length != 1 ? 's' : ''} submitted',
              style: const TextStyle(fontSize: 12, color: TatvaColors.neutral400)),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_error != null)
            Center(child: Padding(padding: const EdgeInsets.all(24),
                child: Text('Failed to load submissions', style: TextStyle(fontSize: 14, color: TatvaColors.error))))
          else if (subs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(24),
                child: Text('No submissions yet', style: TextStyle(fontSize: 14, color: TatvaColors.neutral400))))
          else
            Expanded(
              child: ListView.builder(
                itemCount: subs.length,
                itemBuilder: (_, i) => _submissionCard(i, subs[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _submissionCard(int index, Map<String, dynamic> s) {
    final files = (s['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final name = s['studentName'] as String? ?? 'Student';
    final note = s['note'] as String? ?? '';
    final at = s['submittedAt'] as String?;
    final status = s['status'] as String? ?? 'pending';
    final studentUid = s['studentUid'] as String? ?? '';
    final commentCount = s['commentCount'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: TatvaColors.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: TatvaColors.info.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TatvaColors.info))),
          const SizedBox(width: 8),
          Expanded(child: Text(name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.neutral900))),
          TeacherHomeworkTab._statusBadge(status),
          if (at != null) ...[
            const SizedBox(width: 6),
            Text(_timeLabel(at), style: const TextStyle(fontSize: 10, color: TatvaColors.neutral400)),
          ],
        ]),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(note, style: const TextStyle(fontSize: 12, color: TatvaColors.neutral600)),
        ],
        if (files.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: files.map((f) {
            final fType = f['type'] as String? ?? 'document';
            final fName = f['name'] as String? ?? 'File';
            final fUrl = f['url'] as String? ?? '';
            final ic = fType == 'pdf' ? Icons.picture_as_pdf_rounded
                : fType == 'image' ? Icons.image_rounded : Icons.insert_drive_file_rounded;
            final fc = fType == 'pdf' ? TatvaColors.error
                : fType == 'image' ? TatvaColors.info : TatvaColors.accent;
            return GestureDetector(
              onTap: () {
                if (fUrl.isNotEmpty) launchUrl(Uri.parse(fUrl), mode: LaunchMode.externalApplication);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: fc.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: fc.withOpacity(0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ic, size: 13, color: fc),
                  const SizedBox(width: 4),
                  Text(fName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fc)),
                  const SizedBox(width: 2),
                  Icon(Icons.open_in_new_rounded, size: 10, color: fc.withOpacity(0.6)),
                ]),
              ),
            );
          }).toList()),
        ],
        const SizedBox(height: 10),
        Row(children: [
          if (status != 'accepted')
            _actionChip('Accept', Icons.check_rounded, TatvaColors.success,
                () => _setStatus(index, studentUid, 'accepted')),
          if (status != 'accepted') const SizedBox(width: 6),
          if (status != 'returned')
            _actionChip('Return', Icons.reply_rounded, TatvaColors.accent,
                () => _setStatus(index, studentUid, 'returned')),
          const Spacer(),
          GestureDetector(
            onTap: () => HomeworkCommentsSheet.show(
              context,
              homeworkId: widget.hw.id,
              studentUid: studentUid,
              studentName: name,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _actionChip(String label, IconData icon, Color c, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
        ]),
      ),
    );
  }

  String _timeLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
