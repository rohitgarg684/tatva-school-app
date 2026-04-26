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
    required String userRole,
    required List<String> availableGrades,
    required void Function(AnnouncementModel ann) onAnnouncementCreated,
  }) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    bool isEveryone = true;
    Set<String> selectedGrades = {};
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
                  SizedBox(height: 20),
                  BouncyTap(
                    onTap: () async {
                      if (titleController.text.trim().isEmpty) return;
                      if (!isEveryone && selectedGrades.isEmpty) return;
                      final title = titleController.text.trim();
                      final body = bodyController.text.trim();
                      final grades = isEveryone ? <String>[] : selectedGrades.toList()..sort();
                      await api.createAnnouncement(
                        title: title,
                        body: body,
                        grades: grades,
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
