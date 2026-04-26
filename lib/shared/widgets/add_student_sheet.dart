import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../theme/colors.dart';
import '../animations/animations.dart';

class AddStudentSheet extends StatefulWidget {
  /// If non-null, the student is auto-assigned to this class upon creation.
  final String? classId;
  final VoidCallback? onStudentAdded;

  const AddStudentSheet({super.key, this.classId, this.onStudentAdded});

  static Future<void> show(
    BuildContext context, {
    String? classId,
    VoidCallback? onStudentAdded,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AddStudentSheet(
        classId: classId,
        onStudentAdded: onStudentAdded,
      ),
    );
  }

  @override
  State<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends State<AddStudentSheet> {
  final _nameCtrl = TextEditingController();
  final _rollCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();

  String _selectedGrade = '';
  String _selectedSection = '';
  bool _isSaving = false;
  String _error = '';

  static const _grades = ['6', '7', '8', '9', '10', '11', '12'];
  static const _sections = ['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollCtrl.dispose();
    _parentNameCtrl.dispose();
    _parentPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Student name is required');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = '';
    });

    try {
      final result = await ApiService().enrollStudent(
        name: name,
        rollNumber: _rollCtrl.text.trim(),
        grade: _selectedGrade,
        section: _selectedSection,
        parentName: _parentNameCtrl.text.trim(),
        parentPhone: _parentPhoneCtrl.text.trim(),
        classIds: widget.classId != null ? [widget.classId!] : [],
      );

      if (!mounted) return;

      if (result['enrolled'] == true || result['id'] != null) {
        widget.onStudentAdded?.call();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$name added successfully',
              style: const TextStyle()),
          backgroundColor: TatvaColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      } else {
        setState(() {
          _isSaving = false;
          _error = 'Failed to add student. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = 'Failed to add student. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                  child: const Icon(Icons.person_add_outlined,
                      color: TatvaColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Add Student',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
              ]),
              const SizedBox(height: 4),
              Text(
                widget.classId != null
                    ? 'Student will be added to this class'
                    : 'Enroll a new student into the school',
                style: const TextStyle(
                    fontSize: 13,
                    color: TatvaColors.neutral400),
              ),
              const SizedBox(height: 20),

              _label('Student Name *'),
              const SizedBox(height: 8),
              _field(_nameCtrl, 'e.g. Arjun Sharma', Icons.person_outline),
              const SizedBox(height: 16),

              _label('Roll Number'),
              const SizedBox(height: 8),
              _field(_rollCtrl, 'e.g. 2024-001', Icons.tag),
              const SizedBox(height: 16),

              _label('Grade'),
              const SizedBox(height: 8),
              _chipRow(
                items: _grades,
                selected: _selectedGrade,
                onSelected: (v) => setState(() => _selectedGrade = v),
              ),
              const SizedBox(height: 16),

              _label('Section'),
              const SizedBox(height: 8),
              _chipRow(
                items: _sections,
                selected: _selectedSection,
                onSelected: (v) => setState(() => _selectedSection = v),
              ),
              const SizedBox(height: 16),

              _label('Parent / Guardian Name'),
              const SizedBox(height: 8),
              _field(_parentNameCtrl, 'e.g. Mr. Sharma',
                  Icons.family_restroom_outlined),
              const SizedBox(height: 16),

              _label('Parent Phone'),
              const SizedBox(height: 8),
              _field(
                _parentPhoneCtrl,
                'e.g. +91 98765 43210',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.info_outline,
                      size: 13, color: TatvaColors.error),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_error,
                        style: const TextStyle(
                            fontSize: 12,
                            color: TatvaColors.error)),
                  ),
                ]),
              ],

              const SizedBox(height: 24),
              BouncyTap(
                onTap: _isSaving ? null : _save,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _isSaving
                        ? TatvaColors.neutral300
                        : TatvaColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isSaving
                        ? []
                        : [
                            BoxShadow(
                                color: TatvaColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4)),
                          ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Add Student',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: TatvaColors.neutral900));

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(
fontSize: 14, color: TatvaColors.neutral900),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: TatvaColors.neutral400, size: 18),
        filled: true,
        fillColor: TatvaColors.bgLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    );
  }

  Widget _chipRow({
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSel = selected == item;
        return GestureDetector(
          onTap: () => onSelected(isSel ? '' : item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? TatvaColors.primary : TatvaColors.bgLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSel ? TatvaColors.primary : Colors.grey.shade200),
            ),
            child: Text(item,
                style: TextStyle(
                    fontSize: 13,
                    color: isSel ? Colors.white : TatvaColors.neutral400,
                    fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }
}
