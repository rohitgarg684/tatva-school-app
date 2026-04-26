import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/announcement_model.dart';
import '../../../models/audience.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class NewAnnouncementSheet {
  static void show(
    BuildContext context, {
    required ApiService api,
    required String uid,
    required String userName,
    required void Function(AnnouncementModel ann) onAnnouncementCreated,
  }) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedAudience = 'Everyone';
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
                Row(
                  children: ['Everyone', 'Parents Only', 'Teachers Only']
                      .map((audience) {
                    bool isSel = selectedAudience == audience;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(
                            () => selectedAudience = audience),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: audience != 'Teachers Only' ? 8 : 0),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: isSel
                                  ? TatvaColors.primary
                                  : TatvaColors.bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSel
                                      ? TatvaColors.primary
                                      : Colors.grey.shade200)),
                          child: Center(
                              child: Text(audience,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isSel
                                          ? Colors.white
                                          : TatvaColors.neutral400,
                                      fontWeight: FontWeight.w600))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                  decoration: InputDecoration(
                    hintText: 'e.g. School Closure Notice',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: TatvaColors.bgLight,
                    contentPadding: EdgeInsets.symmetric(
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
                  decoration: InputDecoration(
                    hintText: 'Write your announcement here...',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: TatvaColors.bgLight,
                    contentPadding: EdgeInsets.all(16),
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
                SizedBox(height: 20),
                BouncyTap(
                  onTap: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();
                    await api.createAnnouncement(
                      title: title,
                      body: body,
                      audience: selectedAudience,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    final newAnn = AnnouncementModel(
                      id: '',
                      title: title,
                      body: body,
                      audience: Audience.fromString(selectedAudience),
                      createdBy: uid,
                      createdByName: userName,
                      createdByRole: 'Principal',
                    );
                    onAnnouncementCreated(newAnn);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          'Announcement sent to $selectedAudience!',
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
                        color: TatvaColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  TatvaColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ]),
                    child: Center(
                        child: Text('Send Announcement',
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
