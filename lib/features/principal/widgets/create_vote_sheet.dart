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
    String selectedType = 'Weather Day';
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
            decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24))),
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
                  children: ['Weather Day', 'Event', 'Policy', 'Other']
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
                        child: Text(type,
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
                  onTap: () async {
                    if (questionController.text.trim().isEmpty) return;
                    final question = questionController.text.trim();
                    await api.createVote(question: question);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final newVote = VoteModel(
                      id: '',
                      question: question,
                      type: selectedType
                          .toLowerCase()
                          .replaceAll(' ', '_'),
                      createdBy: uid,
                      createdByName: userName,
                      createdByRole: 'Principal',
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
                        child: Text('Send Vote to All Parents',
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
    );
  }
}
