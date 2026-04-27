import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/vote_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class TeacherCreateVoteSheet {
  static void show(
    BuildContext context, {
    required ApiService api,
    required String uid,
    VoteModel? existingVote,
    required void Function(VoteModel vote) onVoteCreated,
  }) {
    final isEditing = existingVote != null;
    final questionController = TextEditingController(text: existingVote?.question ?? '');
    String selectedType = existingVote?.type ?? 'school_decision';
    final optionControllers = <TextEditingController>[];
    bool useCustomOptions = existingVote != null &&
        existingVote.options.any((o) => !['school', 'no_school', 'undecided'].contains(o));

    if (existingVote != null && useCustomOptions) {
      for (final o in existingVote.options) {
        optionControllers.add(TextEditingController(text: o));
      }
    }

    DateTime votingDeadline = existingVote?.votingDeadline ?? DateTime.now().add(const Duration(days: 1));
    DateTime resultsVisibleUntil = existingVote?.resultsVisibleUntil ?? DateTime.now().add(const Duration(days: 3));
    bool isSaving = false;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> pickDate(DateTime initial, void Function(DateTime) onPicked) async {
              final date = await showDatePicker(
                context: ctx,
                initialDate: initial,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (c, child) => Theme(
                  data: Theme.of(c).copyWith(
                    colorScheme: ColorScheme.light(primary: TatvaColors.purple),
                  ),
                  child: child!,
                ),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(initial),
                );
                final dt = DateTime(date.year, date.month, date.day,
                    time?.hour ?? 23, time?.minute ?? 59);
                setModalState(() => onPicked(dt));
              }
            }

            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: const BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
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
                                borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: TatvaColors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(
                              isEditing ? Icons.edit_outlined : Icons.how_to_vote_outlined,
                              color: TatvaColors.purple,
                              size: 18)),
                      const SizedBox(width: 10),
                      Text(isEditing ? 'Edit Vote' : 'Create Vote',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                    ]),
                    const SizedBox(height: 4),
                    const Text('Set question, dates, and options',
                        style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
                    const SizedBox(height: 20),

                    const Text('Vote Type',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['school_decision', 'event', 'policy', 'other'].map((type) {
                        bool isSel = selectedType == type;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedType = type),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: isSel ? TatvaColors.purple : TatvaColors.bgLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSel ? TatvaColors.purple : Colors.grey.shade200)),
                            child: Text(type.replaceAll('_', ' '),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSel ? Colors.white : TatvaColors.neutral400,
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('Question',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14, color: TatvaColors.neutral900),
                      decoration: InputDecoration(
                        hintText: 'e.g. Should we cancel school tomorrow due to weather?',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: TatvaColors.bgLight,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: TatvaColors.purple.withOpacity(0.5), width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(children: [
                      const Text('Custom Options',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: TatvaColors.neutral900)),
                      const Spacer(),
                      Switch(
                        value: useCustomOptions,
                        activeColor: TatvaColors.purple,
                        onChanged: (v) {
                          setModalState(() {
                            useCustomOptions = v;
                            if (v && optionControllers.isEmpty) {
                              optionControllers.add(TextEditingController(text: 'Yes'));
                              optionControllers.add(TextEditingController(text: 'No'));
                            }
                          });
                        },
                      ),
                    ]),
                    if (!useCustomOptions)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: TatvaColors.purple.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TatvaColors.purple.withOpacity(0.15))),
                        child: Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: TatvaColors.purple, size: 15),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: Text(
                                  'Default options: School · No School · Undecided',
                                  style: TextStyle(
                                      fontSize: 12, color: TatvaColors.neutral600))),
                        ]),
                      ),
                    if (useCustomOptions) ...[
                      ...optionControllers.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: e.value,
                                  style: const TextStyle(
                                      fontSize: 13, color: TatvaColors.neutral900),
                                  decoration: InputDecoration(
                                    hintText: 'Option ${e.key + 1}',
                                    hintStyle: TextStyle(
                                        fontSize: 12, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: TatvaColors.bgLight,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide:
                                            BorderSide(color: Colors.grey.shade200)),
                                  ),
                                ),
                              ),
                              if (optionControllers.length > 2)
                                IconButton(
                                    icon: const Icon(Icons.remove_circle_outline,
                                        color: TatvaColors.error, size: 20),
                                    onPressed: () => setModalState(
                                        () => optionControllers.removeAt(e.key))),
                            ]),
                          )),
                      if (optionControllers.length < 6)
                        GestureDetector(
                          onTap: () => setModalState(
                              () => optionControllers.add(TextEditingController())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: TatvaColors.purple.withOpacity(0.3),
                                    style: BorderStyle.solid),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                                child: Text('+ Add Option',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: TatvaColors.purple,
                                        fontWeight: FontWeight.w600))),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),

                    const Text('Voting Deadline',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 8),
                    _DatePickerTile(
                      date: votingDeadline,
                      color: TatvaColors.purple,
                      onTap: () => pickDate(
                          votingDeadline, (d) => votingDeadline = d),
                    ),
                    const SizedBox(height: 16),

                    const Text('Results Visible Until',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    const SizedBox(height: 8),
                    _DatePickerTile(
                      date: resultsVisibleUntil,
                      color: TatvaColors.info,
                      onTap: () => pickDate(
                          resultsVisibleUntil, (d) => resultsVisibleUntil = d),
                    ),
                    const SizedBox(height: 20),

                    BouncyTap(
                      onTap: isSaving
                          ? null
                          : () async {
                              if (questionController.text.trim().isEmpty) return;
                              if (resultsVisibleUntil.isBefore(votingDeadline)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                  content: Text('Results end date must be after voting deadline'),
                                  backgroundColor: TatvaColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }

                              setModalState(() => isSaving = true);
                              final question = questionController.text.trim();
                              final List<String>? opts = useCustomOptions
                                  ? optionControllers
                                      .map((c) => c.text.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList()
                                  : null;

                              if (useCustomOptions && (opts == null || opts.length < 2)) {
                                setModalState(() => isSaving = false);
                                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                                  content: Text('At least 2 options required'),
                                  backgroundColor: TatvaColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }

                              try {
                                if (isEditing) {
                                  await api.updateVote(
                                    existingVote!.id,
                                    question: question,
                                    type: selectedType,
                                    options: opts,
                                    votingDeadline: votingDeadline.toUtc().toIso8601String(),
                                    resultsVisibleUntil:
                                        resultsVisibleUntil.toUtc().toIso8601String(),
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  final updated = existingVote.copyWith(
                                    question: question,
                                    type: selectedType,
                                    options: opts ?? existingVote.options,
                                    votingDeadline: votingDeadline,
                                    resultsVisibleUntil: resultsVisibleUntil,
                                  );
                                  onVoteCreated(updated);
                                } else {
                                  final result = await api.createVote(
                                    question: question,
                                    type: selectedType,
                                    options: opts,
                                    votingDeadline: votingDeadline.toUtc().toIso8601String(),
                                    resultsVisibleUntil:
                                        resultsVisibleUntil.toUtc().toIso8601String(),
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  final newVote = VoteModel(
                                    id: result['id'] as String? ?? '',
                                    question: question,
                                    type: selectedType,
                                    options: opts ?? ['school', 'no_school', 'undecided'],
                                    createdBy: uid,
                                    createdByName: '',
                                    votingDeadline: votingDeadline,
                                    resultsVisibleUntil: resultsVisibleUntil,
                                  );
                                  onVoteCreated(newVote);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(isEditing ? 'Vote updated' : 'Vote created!'),
                                    backgroundColor: TatvaColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10)),
                                  ));
                                }
                              } catch (e) {
                                setModalState(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: TatvaColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            color: TatvaColors.purple,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: TatvaColors.purple.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ]),
                        child: Center(
                            child: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(isEditing ? 'Save Changes' : 'Create Vote',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  final DateTime date;
  final Color color;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.date,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = date.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final timeStr =
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, color: color, size: 16),
          const SizedBox(width: 10),
          Text('${months[l.month - 1]} ${l.day}, ${l.year} at $timeStr',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          const Spacer(),
          Icon(Icons.edit_outlined, color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
  }
}
