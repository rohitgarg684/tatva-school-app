import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/class_model.dart';
import '../../../services/api_service.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class ClassesTab extends StatelessWidget {
  final List<ClassModel> allClasses;
  final void Function(ClassModel cls, Color color) onShowClassDetail;
  final VoidCallback onCreateClass;
  final VoidCallback onRefresh;

  const ClassesTab({
    super.key,
    required this.allClasses,
    required this.onShowClassDetail,
    required this.onCreateClass,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: FadeSlideIn(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Classes',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900,
                              letterSpacing: -0.8)),
                      SizedBox(height: 4),
                      Text('${allClasses.length} classes',
                          style: TextStyle(
                              fontSize: 13,
                              color: TatvaColors.neutral400)),
                    ],
                  ),
                ),
                BouncyTap(
                  onTap: onCreateClass,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: TatvaColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color:
                                TatvaColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Create Class',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: allClasses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.class_outlined,
                          color: TatvaColors.neutral400, size: 48),
                      SizedBox(height: 12),
                      Text('No classes yet',
                          style: TextStyle(
                              fontSize: 15,
                              color: TatvaColors.neutral400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: TatvaColors.primary,
                  onRefresh: () async => onRefresh(),
                  child: ListView.builder(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20),
                    itemCount: allClasses.length,
                    itemBuilder: (_, index) {
                      final cls = allClasses[index];
                      final colors = [
                        TatvaColors.primary,
                        TatvaColors.info,
                        TatvaColors.accent,
                        TatvaColors.purple,
                        TatvaColors.success,
                        TatvaColors.error
                      ];
                      final cardColor =
                          colors[index % colors.length];
                      return StaggeredItem(
                        index: index,
                        child: GestureDetector(
                          onTap: () => onShowClassDetail(
                              cls, cardColor),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                                color: TatvaColors.bgCard,
                                borderRadius:
                                    BorderRadius.circular(16),
                                border: Border.all(
                                    color:
                                        Colors.grey.shade100)),
                            child: Column(children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [
                                          cardColor
                                              .withOpacity(0.12),
                                          cardColor
                                              .withOpacity(0.04),
                                        ]),
                                    borderRadius:
                                        BorderRadius.vertical(
                                            top: Radius.circular(
                                                16))),
                                child: Row(children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                        Text(cls.name,
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                color: TatvaColors
                                                    .neutral900)),
                                        Text(cls.subject,
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: TatvaColors
                                                    .neutral400)),
                                      ])),
                                  Container(
                                      padding:
                                          EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6),
                                      decoration: BoxDecoration(
                                          color: TatvaColors
                                              .accent
                                              .withOpacity(
                                                  0.15),
                                          borderRadius:
                                              BorderRadius
                                                  .circular(20),
                                          border: Border.all(
                                              color: TatvaColors
                                                  .accent
                                                  .withOpacity(
                                                      0.3))),
                                      child: Text(
                                          cls.classCode,
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight
                                                      .bold,
                                              color: TatvaColors
                                                  .accent,
                                              letterSpacing:
                                                  2))),
                                ]),
                              ),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      16, 12, 16, 8),
                                  child: Row(children: [
                                    Icon(
                                        Icons.person_outline,
                                        color: TatvaColors
                                            .neutral400,
                                        size: 16),
                                    SizedBox(width: 4),
                                    Text(cls.teacherName,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: TatvaColors
                                                .neutral400)),
                                    SizedBox(width: 12),
                                    Icon(
                                        Icons.people_outline,
                                        color: TatvaColors
                                            .neutral400,
                                        size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                        '${cls.studentUids.length} students',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: TatvaColors
                                                .neutral400)),
                                    Spacer(),
                                    GestureDetector(
                                        onTap: () =>
                                            _confirmDeleteClass(
                                                context,
                                                cls),
                                        child: Container(
                                            padding: EdgeInsets
                                                .symmetric(
                                                    horizontal:
                                                        10,
                                                    vertical:
                                                        6),
                                            decoration: BoxDecoration(
                                                color: TatvaColors
                                                    .error
                                                    .withOpacity(
                                                        0.08),
                                                borderRadius:
                                                    BorderRadius
                                                        .circular(
                                                            8),
                                                border: Border.all(
                                                    color: TatvaColors
                                                        .error
                                                        .withOpacity(
                                                            0.2))),
                                            child: Icon(
                                                Icons
                                                    .delete_outline_rounded,
                                                color:
                                                    TatvaColors
                                                        .error,
                                                size: 16))),
                                  ])),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _confirmDeleteClass(BuildContext context, ClassModel cls) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${cls.name}"?\n\n'
            'This will remove ${cls.studentUids.length} student(s) and '
            '${cls.parentUids.length} parent(s) from this class. '
            'This action cannot be undone.',
            style: TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: TatvaColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteClass(cls.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('"${cls.name}" deleted')));
                }
                onRefresh();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to delete class')));
                }
                debugPrint('Delete class error: $e');
              }
            },
            child: Text('Delete',
                style: TextStyle(
                    color: TatvaColors.error,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
