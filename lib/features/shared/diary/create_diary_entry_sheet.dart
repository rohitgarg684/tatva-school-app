import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../models/diary_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/typography.dart';

class CreateDiaryEntrySheet extends StatefulWidget {
  final String classId;
  final ValueChanged<DiaryEntry> onCreated;
  final DiaryEntry? editEntry;

  const CreateDiaryEntrySheet({
    super.key,
    required this.classId,
    required this.onCreated,
    this.editEntry,
  });

  @override
  State<CreateDiaryEntrySheet> createState() => _CreateDiaryEntrySheetState();
}

class _CreateDiaryEntrySheetState extends State<CreateDiaryEntrySheet> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final List<MapEntry<String, Uint8List>> _pickedFiles = [];
  bool _submitting = false;

  bool get _isEditing => widget.editEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleCtrl.text = widget.editEntry!.title;
      _bodyCtrl.text = widget.editEntry!.body;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes != null && _pickedFiles.length < 5) {
        _pickedFiles.add(MapEntry(f.name, f.bytes!));
      }
    }
    setState(() {});
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required'), backgroundColor: TatvaColors.warning),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isEditing) {
        await _api.updateDiaryEntry(widget.editEntry!.id, title: title, body: body);
        widget.onCreated(widget.editEntry!.copyWith(title: title, body: body));
      } else {
        final result = await _api.createDiaryEntry(classId: widget.classId, title: title, body: body);
        final entryId = result['id'] as String;

        List<DiaryAttachment> attachments = [];
        if (_pickedFiles.isNotEmpty) {
          final uploaded = await _api.uploadDiaryEntryFiles(entryId, _pickedFiles);
          attachments = uploaded.map((e) => DiaryAttachment.fromJson(e)).toList();
        }

        final now = DateTime.now();
        widget.onCreated(DiaryEntry(
          id: entryId,
          classId: widget.classId,
          teacherUid: '',
          teacherName: '',
          date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
          title: title,
          body: body,
          attachments: attachments,
          createdAt: now,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: TatvaColors.error),
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: TatvaColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: TatvaColors.neutral300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isEditing ? 'Edit Entry' : 'New Diary Entry',
            style: TatvaText.h3.copyWith(color: TatvaColors.neutral900),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: TatvaColors.neutral500),
              filled: true,
              fillColor: TatvaColors.neutral50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bodyCtrl,
            decoration: InputDecoration(
              labelText: 'What happened today?',
              labelStyle: TextStyle(color: TatvaColors.neutral500),
              filled: true,
              fillColor: TatvaColors.neutral50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            minLines: 4,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 14),
          if (!_isEditing) ...[
            Row(children: [
              TextButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file_rounded, size: 18),
                label: Text('Attach files (${_pickedFiles.length}/5)'),
                style: TextButton.styleFrom(foregroundColor: TatvaColors.primary),
              ),
            ]),
            if (_pickedFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: List.generate(_pickedFiles.length, (i) {
                final file = _pickedFiles[i];
                return Chip(
                  label: Text(file.key, style: const TextStyle(fontSize: 12)),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _pickedFiles.removeAt(i)),
                  backgroundColor: TatvaColors.neutral100,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                );
              })),
            ],
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: TatvaColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Publish Entry', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
