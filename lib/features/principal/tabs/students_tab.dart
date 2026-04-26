import 'package:flutter/material.dart';
import '../../../models/student_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/add_student_sheet.dart';

class StudentsTab extends StatelessWidget {
  final List<StudentModel> students;
  final List<StudentModel> filteredStudents;
  final TextEditingController searchController;
  final bool loading;
  final void Function(String query) onFilterStudents;
  final VoidCallback onLoadStudents;
  final void Function(StudentModel student, Color color)
      onShowStudentDetail;

  const StudentsTab({
    super.key,
    required this.students,
    required this.filteredStudents,
    required this.searchController,
    required this.loading,
    required this.onFilterStudents,
    required this.onLoadStudents,
    required this.onShowStudentDetail,
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
                      Text('Student Directory',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900,
                              letterSpacing: -0.8)),
                      SizedBox(height: 4),
                      Text(
                          loading
                              ? 'Loading...'
                              : '${students.length} students enrolled',
                          style: TextStyle(
                              fontSize: 13,
                              color: TatvaColors.neutral400)),
                    ],
                  ),
                ),
                BouncyTap(
                  onTap: () => AddStudentSheet.show(context,
                      onStudentAdded: onLoadStudents),
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
                          Icon(Icons.person_add_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Add Student',
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: FadeSlideIn(
            delayMs: 60,
            child: TextField(
              controller: searchController,
              onChanged: onFilterStudents,
              style: TextStyle(
                  fontSize: 14, color: TatvaColors.neutral900),
              decoration: InputDecoration(
                hintText:
                    'Search by name, roll number or grade...',
                hintStyle: TextStyle(
                    fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search,
                    color: TatvaColors.neutral400, size: 20),
                filled: true,
                fillColor: TatvaColors.bgCard,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color:
                            TatvaColors.primary.withOpacity(0.5),
                        width: 1.5)),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: loading
              ? Center(
                  child: CircularProgressIndicator(
                      color: TatvaColors.primary))
              : filteredStudents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined,
                                color: TatvaColors.neutral400,
                                size: 48),
                            SizedBox(height: 12),
                            Text(
                              searchController.text.isNotEmpty
                                  ? 'No students match your search'
                                  : 'No students enrolled yet',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: TatvaColors.neutral400),
                            ),
                            SizedBox(height: 6),
                            Text(
                                'Tap "Add Student" to enroll one',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        TatvaColors.neutral400)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: TatvaColors.primary,
                      onRefresh: () async => onLoadStudents(),
                      child: ListView.builder(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredStudents.length,
                        itemBuilder: (_, index) => _studentCard(
                            filteredStudents[index], index),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _studentCard(StudentModel student, int index) {
    final colors = [
      TatvaColors.primary,
      TatvaColors.info,
      TatvaColors.accent,
      TatvaColors.purple,
      TatvaColors.success,
      TatvaColors.error
    ];
    final cardColor = colors[index % colors.length];

    return StaggeredItem(
      index: index,
      child: GestureDetector(
        onTap: () => onShowStudentDetail(student, cardColor),
        child: Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: cardColor.withOpacity(0.12),
              child: Text(
                student.name.isNotEmpty
                    ? student.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cardColor),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900,
                          letterSpacing: -0.2)),
                  SizedBox(height: 2),
                  Row(children: [
                    if (student.rollNumber.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.08),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: Text(student.rollNumber,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: cardColor)),
                      ),
                      SizedBox(width: 8),
                    ],
                    if (student
                        .displayGradeSection.isNotEmpty)
                      Text(student.displayGradeSection,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  TatvaColors.neutral400)),
                  ]),
                  if (student.parentName.isNotEmpty) ...[
                    SizedBox(height: 2),
                    Text('Parent: ${student.parentName}',
                        style: TextStyle(
                            fontSize: 11,
                            color: TatvaColors.neutral400)),
                  ],
                ],
              ),
            ),
            if (student.classIds.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TatvaColors.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    '${student.classIds.length} class${student.classIds.length > 1 ? 'es' : ''}',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: TatvaColors.info)),
              ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_ios_rounded,
                color: TatvaColors.neutral400, size: 12),
          ]),
        ),
      ),
    );
  }
}
