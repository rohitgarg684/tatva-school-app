import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../theme/colors.dart';
import '../animations/animations.dart';

class StudentDetailSheet extends StatefulWidget {
  final UserModel student;

  const StudentDetailSheet({super.key, required this.student});

  static Future<void> show(BuildContext context, {required UserModel student}) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StudentDetailSheet(student: student),
    );
  }

  @override
  State<StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<StudentDetailSheet> {
  final _api = ApiService();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String _savedEmail = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentRecord();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentRecord() async {
    try {
      final result = await _api.getStudentByName(widget.student.name);
      final student = result['student'] as Map<String, dynamic>?;
      final email = student?['parentEmail'] as String? ?? '';
      _emailCtrl.text = email;
      _savedEmail = email;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final email = _emailCtrl.text.trim();
    if (email == _savedEmail) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      await _api.updateStudentParentEmail(
        studentName: widget.student.name,
        parentEmail: email,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Parent email updated', style: TextStyle()),
        backgroundColor: TatvaColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to update. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: TatvaColors.primary.withOpacity(0.1),
                child: Text(
                  s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                    if (s.email.isNotEmpty)
                      Text(s.email,
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const Text('Parent Email',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TatvaColors.neutral900)),
            const SizedBox(height: 4),
            const Text(
                'When a parent registers with this email, they will be auto-linked to this student.',
                style:
                    TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: TatvaColors.primary))),
              )
            else ...[
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                    fontSize: 14, color: TatvaColors.neutral900),
                decoration: InputDecoration(
                  hintText: 'e.g. parent@example.com',
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: TatvaColors.neutral400, size: 18),
                  filled: true,
                  fillColor: TatvaColors.bgLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
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
                          color: TatvaColors.primary.withOpacity(0.5),
                          width: 1.5)),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: TatvaColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_error,
                        style: const TextStyle(
                            fontSize: 12, color: TatvaColors.error)),
                  ),
                ]),
              ],
              const SizedBox(height: 20),
              BouncyTap(
                onTap: _saving ? null : _save,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _saving
                        ? TatvaColors.neutral300
                        : TatvaColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _saving
                        ? []
                        : [
                            BoxShadow(
                                color:
                                    TatvaColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                  ),
                  child: Center(
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
