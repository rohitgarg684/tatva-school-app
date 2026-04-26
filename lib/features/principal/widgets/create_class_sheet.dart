import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class CreateClassSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onClassCreated,
  }) {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
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
            bool isCreating = false;
            return Container(
              decoration: BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
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
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: TatvaColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.class_outlined,
                          color: TatvaColors.primary, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('Create New Class',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.neutral900)),
                  ]),
                  SizedBox(height: 4),
                  Text('A unique class code will be generated',
                      style: TextStyle(
                          fontSize: 13, color: TatvaColors.neutral400)),
                  SizedBox(height: 20),
                  Text('Class Name',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grade 8 — Section A',
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
                              color:
                                  TatvaColors.primary.withOpacity(0.5),
                              width: 1.5)),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Subject',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: TatvaColors.neutral900)),
                  SizedBox(height: 8),
                  TextField(
                    controller: subjectCtrl,
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral900),
                    decoration: InputDecoration(
                      hintText: 'e.g. Mathematics',
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
                              color:
                                  TatvaColors.primary.withOpacity(0.5),
                              width: 1.5)),
                    ),
                  ),
                  SizedBox(height: 24),
                  BouncyTap(
                    onTap: isCreating
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                subjectCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() => isCreating = true);
                            final code = String.fromCharCodes(
                              List.generate(
                                  6, (_) => Random().nextInt(26) + 65),
                            );
                            final name = nameCtrl.text.trim();
                            try {
                              await ApiService().createClass(
                                name: name,
                                subject: subjectCtrl.text.trim(),
                                classCode: code,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Class "$name" created! Code: $code')));
                              onClassCreated();
                            } catch (e) {
                              if (!ctx.mounted) return;
                              setModalState(
                                  () => isCreating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to create class')));
                            }
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
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: isCreating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : Text('Create Class',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
