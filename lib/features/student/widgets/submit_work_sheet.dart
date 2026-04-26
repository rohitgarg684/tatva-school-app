import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/tatva_snackbar.dart';
import '../../../services/api_service.dart';
import '../../../models/homework_model.dart';

class SubmitWorkSheet {
  static void show(
    BuildContext context, {
    required HomeworkModel hw,
    required Color color,
    required ApiService api,
    required void Function(Map<String, dynamic>? submission) onSubmitted,
  }) {
    final noteCtrl = TextEditingController();
    final pickedFiles = <MapEntry<String, Uint8List>>[];
    bool isSubmitting = false;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
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
                  const SizedBox(height: 16),
                  Text('Submit: ${hw.title}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900)),
                  Text('${hw.subject} · ${hw.className}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: TatvaColors.neutral400)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      filled: true,
                      fillColor: TatvaColors.bgLight,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: color.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Attach Files',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral400)),
                  const SizedBox(height: 8),
                  ...pickedFiles.asMap().entries.map((e) {
                    final f = e.value;
                    final ext =
                        f.key.split('.').last.toLowerCase();
                    final isImg =
                        ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color:
                              (isImg ? TatvaColors.info : TatvaColors.error).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: (isImg ? TatvaColors.info : TatvaColors.error)
                                  .withOpacity(0.15))),
                      child: Row(children: [
                        Icon(
                            isImg
                                ? Icons.image_rounded
                                : Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: isImg ? TatvaColors.info : TatvaColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isImg ? TatvaColors.info : TatvaColors.error)),
                        ),
                        Text(
                            '${(f.value.length / 1024).toStringAsFixed(0)} KB',
                            style: const TextStyle(
                                fontSize: 10,
                                color: TatvaColors.neutral400)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              setModal(() => pickedFiles.removeAt(e.key)),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: TatvaColors.neutral400),
                        ),
                      ]),
                    );
                  }),
                  GestureDetector(
                    onTap: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp',
                          'docx', 'xlsx', 'pptx'
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
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.2))),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                size: 16, color: color),
                            const SizedBox(width: 6),
                            Text('Choose Files',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: color)),
                          ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            setModal(() => isSubmitting = true);
                            final resp = await api.submitHomeworkFiles(
                              hw.id,
                              pickedFiles,
                              note: noteCtrl.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            if (resp['error'] == null) {
                              final files = (resp['files'] as List?)
                                  ?.cast<Map<String, dynamic>>() ?? [];
                              onSubmitted({
                                'files': files,
                                'note': noteCtrl.text.trim(),
                              });
                              TatvaSnackbar.show(context, 'Submitted! 🎉');
                            } else {
                              TatvaSnackbar.show(context, 'Failed to submit');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: color.withOpacity(0.35),
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
                              : const Text('Submit',
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
}
