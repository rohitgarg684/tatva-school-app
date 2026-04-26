import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/student_model.dart';
import '../../../shared/theme/colors.dart';

class StudentPickerSheet {
  static void show(
    BuildContext context, {
    required List<StudentModel> students,
    required bool loading,
    required void Function(StudentModel student) onStudentSelected,
  }) {
    final searchCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? students
              : students
                  .where((s) =>
                      s.name.toLowerCase().contains(query) ||
                      s.rollNumber.toLowerCase().contains(query))
                  .toList();
          return Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7),
            decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
                SizedBox(height: 16),
                Text('Select Student for Report',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
                SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchCtrl,
                    onChanged: (_) => setModalState(() {}),
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search by name or roll number...',
                      prefixIcon: Icon(Icons.search,
                          color: TatvaColors.neutral400),
                      filled: true,
                      fillColor: TatvaColors.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                              loading
                                  ? 'Loading students...'
                                  : 'No students found',
                              style: TextStyle(
                                  color: TatvaColors.neutral400)))
                      : ListView.builder(
                          itemCount: filtered.length,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: TatvaColors.primary
                                    .withOpacity(0.1),
                                child: Text(
                                    s.name.isNotEmpty
                                        ? s.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.primary)),
                              ),
                              title: Text(s.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral900)),
                              subtitle: Text(
                                  '${s.rollNumber}${s.grade.isNotEmpty ? ' • ${s.grade}' : ''}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: TatvaColors.neutral400)),
                              trailing: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: TatvaColors.neutral400),
                              onTap: () {
                                Navigator.pop(ctx);
                                onStudentSelected(s);
                              },
                            );
                          },
                        ),
                ),
                SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
