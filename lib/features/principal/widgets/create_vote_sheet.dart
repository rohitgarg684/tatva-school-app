import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/vote_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class CreateVoteSheet {
  static void show(
    BuildContext context, {
    required ApiService api,
    required String uid,
    required String userName,
    required void Function(VoteModel vote) onVoteCreated,
  }) {
    final questionController = TextEditingController();
    String selectedType = 'school_decision';
    DateTime votingDeadline = DateTime.now().add(const Duration(days: 1));
    DateTime resultsVisibleUntil = DateTime.now().add(const Duration(days: 3));
    bool isSaving = false;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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

            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            String fmtDate(DateTime dt) {
              final l = dt.toLocal();
              return '${months[l.month - 1]} ${l.day}, ${l.year} at '
                  '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
            }

            return Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(
                  color: TatvaColors.bgCard,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                              color: TatvaColors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.how_to_vote_outlined,
                              color: TatvaColors.purple, size: 18)),
                      SizedBox(width: 10),
                      Text('Create Parent Vote',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                    ]),
                    SizedBox(height: 4),
                    Text('Parents will see this in their Announcements tab',
                        style: TextStyle(
                            fontSize: 13, color: TatvaColors.neutral400)),
                    SizedBox(height: 20),
                    Text('Vote Type',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['school_decision', 'event', 'policy', 'other']
                          .map((type) {
                        bool isSel = selectedType == type;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedType = type),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                                color: isSel
                                    ? TatvaColors.purple
                                    : TatvaColors.bgLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: isSel
                                        ? TatvaColors.purple
                                        : Colors.grey.shade200)),
                            child: Text(type.replaceAll('_', ' '),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isSel
                                        ? Colors.white
                                        : TatvaColors.neutral400,
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16),
                    Text('Question',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    SizedBox(height: 8),
                    TextField(
                      controller: questionController,
                      maxLines: 2,
                      style: TextStyle(
                          fontSize: 14, color: TatvaColors.neutral900),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Should we cancel school tomorrow due to weather?',
                        hintStyle: TextStyle(
                            fontSize: 12, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: TatvaColors.bgLight,
                        contentPadding: EdgeInsets.all(14),
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
                                color: TatvaColors.purple.withOpacity(0.5),
                                width: 1.5)),
                      ),
                    ),
                    SizedBox(height: 16),

                    Text('Voting Deadline',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickDate(votingDeadline, (d) => votingDeadline = d),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: TatvaColors.purple.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TatvaColors.purple.withOpacity(0.2))),
                        child: Row(children: [
                          Icon(Icons.calendar_today_rounded, color: TatvaColors.purple, size: 16),
                          SizedBox(width: 10),
                          Text(fmtDate(votingDeadline),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.purple)),
                          Spacer(),
                          Icon(Icons.edit_outlined, color: TatvaColors.purple.withOpacity(0.5), size: 14),
                        ]),
                      ),
                    ),
                    SizedBox(height: 16),

                    Text('Results Visible Until',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickDate(resultsVisibleUntil, (d) => resultsVisibleUntil = d),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: TatvaColors.info.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: TatvaColors.info.withOpacity(0.2))),
                        child: Row(children: [
                          Icon(Icons.calendar_today_rounded, color: TatvaColors.info, size: 16),
                          SizedBox(width: 10),
                          Text(fmtDate(resultsVisibleUntil),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                          Spacer(),
                          Icon(Icons.edit_outlined, color: TatvaColors.info.withOpacity(0.5), size: 14),
                        ]),
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: TatvaColors.purple.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: TatvaColors.purple.withOpacity(0.15))),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: TatvaColors.purple, size: 15),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Parents vote: School · No School · Undecided. Results are live.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral600))),
                      ]),
                    ),
                    SizedBox(height: 20),
                    BouncyTap(
                      onTap: isSaving
                          ? null
                          : () async {
                              if (questionController.text.trim().isEmpty) return;
                              if (resultsVisibleUntil.isBefore(votingDeadline)) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text('Results end date must be after voting deadline'),
                                  backgroundColor: TatvaColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              setModalState(() => isSaving = true);
                              final question = questionController.text.trim();
                              try {
                                final result = await api.createVote(
                                  question: question,
                                  type: selectedType,
                                  votingDeadline: votingDeadline.toUtc().toIso8601String(),
                                  resultsVisibleUntil: resultsVisibleUntil.toUtc().toIso8601String(),
                                );
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                final newVote = VoteModel(
                                  id: result['id'] as String? ?? '',
                                  question: question,
                                  type: selectedType,
                                  createdBy: uid,
                                  createdByName: userName,
                                  createdByRole: 'Principal',
                                  votingDeadline: votingDeadline,
                                  resultsVisibleUntil: resultsVisibleUntil,
                                );
                                onVoteCreated(newVote);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Vote sent to all parents!',
                                      style: TextStyle()),
                                  backgroundColor: TatvaColors.success,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ));
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
                                  offset: Offset(0, 4))
                            ]),
                        child: Center(
                            child: isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text('Send Vote to All Parents',
                                    style: TextStyle(
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
