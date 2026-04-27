import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/announcement_model.dart';
import '../../shared/utils/announcement_helpers.dart';
import '../../models/class_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/vote_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_service.dart';
import '../../services/dashboard_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/mixins/dashboard_mixin.dart';
import 'tabs/overview_tab.dart';
import 'tabs/activity_tab.dart';
import 'tabs/grade_trends_tab.dart';
import 'tabs/teacher_workload_tab.dart';
import 'tabs/students_tab.dart';
import 'tabs/classes_tab.dart';
import 'tabs/communicate_tab.dart';
import 'tabs/profile_tab.dart';
import 'widgets/class_detail_sheet.dart';
import 'widgets/create_class_sheet.dart';
import 'widgets/create_vote_sheet.dart';
import 'widgets/new_announcement_sheet.dart';
import 'widgets/report_sheet.dart';
import 'widgets/student_enrollment_detail_sheet.dart';
import 'widgets/student_picker_sheet.dart';
import 'widgets/student_user_detail_sheet.dart';
import 'widgets/subject_grade_detail_sheet.dart';
import 'widgets/teacher_detail_sheet.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  _PrincipalDashboardState createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard>
    with TickerProviderStateMixin, DashboardMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Overview'),
    TabItem(icon: Icons.timeline_outlined, activeIcon: Icons.timeline_rounded, label: 'Activity'),
    TabItem(icon: Icons.show_chart_outlined, activeIcon: Icons.show_chart_rounded, label: 'Grades'),
    TabItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Teachers'),
    TabItem(icon: Icons.school_outlined, activeIcon: Icons.school_rounded, label: 'Students'),
    TabItem(icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Classes'),
    TabItem(icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, label: 'Communicate'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  final _studentSearchCtrl = TextEditingController();
  bool _studentsLoading = false;

  final _api = ApiService();
  final _dashSvc = DashboardService();
  String _uid = '';

  PrincipalDashboardData? _data;
  List<AnnouncementModel> _announcementModels = [];
  List<VoteModel> _voteModels = [];

  @override
  void initState() {
    super.initState();
    initDashboardAnimations();
    _loadUser();
  }

  @override
  void dispose() {
    disposeDashboardAnimations();
    _studentSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadPrincipalDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _announcementModels = List.of(data.announcements);
      _voteModels = List.of(data.activeVotes);
    } catch (e) {
      debugPrint('PrincipalDashboard._loadUser error: $e');
    }
    onDataLoaded();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _studentsLoading = true);
    try {
      final rawList = await _api.getStudents();
      final all = rawList.map((m) => StudentModel.fromJson(m)).toList();
      if (!mounted) return;
      setState(() {
        _students = all;
        _filterStudents(_studentSearchCtrl.text);
        _studentsLoading = false;
      });
    } catch (e) {
      debugPrint('_loadStudents error: $e');
      if (mounted) setState(() => _studentsLoading = false);
    }
  }

  void _filterStudents(String query) {
    final lower = query.trim().toLowerCase();
    setState(() {
      if (lower.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((s) =>
                s.name.toLowerCase().contains(lower) ||
                s.rollNumber.toLowerCase().contains(lower) ||
                s.displayGradeSection.toLowerCase().contains(lower))
            .toList();
      }
    });
  }


  // ─── Sheet orchestrators ──────────────────────────────────────────────────────

  void _showSubjectGradeDetail(String subject, Color color) =>
      SubjectGradeDetailSheet.show(context,
          subject: subject, allGrades: _data?.allGrades ?? [], color: color);

  void _showStudentPickerForReport() => StudentPickerSheet.show(
        context,
        students: _students,
        loading: _studentsLoading,
        onStudentSelected: _generateReport,
      );

  void _showTeacherDetail(
          UserModel teacher, List<ClassModel> teacherClasses, Color color) =>
      TeacherDetailSheet.show(
        context,
        teacher: teacher,
        teacherClasses: teacherClasses,
        allGrades: _data?.allGrades ?? [],
        color: color,
        onShowClassDetail: _showClassDetail,
      );

  void _showClassDetail(ClassModel cls, Color color) =>
      ClassDetailSheet.show(
        context,
        cls: cls,
        color: color,
        studentUsers: _data?.students ?? [],
        allGrades: _data?.allGrades ?? [],
        parents: _data?.parents ?? [],
        onShowStudentDetail: _showStudentUserDetail,
      );

  void _showStudentUserDetail(UserModel student, Color color) =>
      StudentUserDetailSheet.show(
        context,
        student: student,
        allGrades: _data?.allGrades ?? [],
        color: color,
        onGenerateReport: _generateReport,
      );

  void _showStudentEnrollmentDetail(StudentModel student, Color color) =>
      StudentEnrollmentDetailSheet.show(
        context,
        student: student,
        allClasses: _data?.allClasses ?? [],
        allGrades: _data?.allGrades ?? [],
        color: color,
        onShowClassDetail: _showClassDetail,
        onGenerateReport: _generateReport,
      );

  void _toggleAnnouncementLike(AnnouncementModel ann) {
    setState(() => _announcementModels = toggleAnnouncementLike(_announcementModels, ann.id, _uid));
    _api.toggleAnnouncementLike(ann.id);
  }

  void _showNewAnnouncement() {
    final grades = (_data?.allClasses ?? [])
        .map((c) => c.grade)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    NewAnnouncementSheet.show(
      context,
      api: _api,
      uid: _uid,
      userName: _data?.user?.name ?? '',
      userRole: 'Principal',
      availableGrades: grades,
      onAnnouncementCreated: (ann) =>
          setState(() => _announcementModels.insert(0, ann)),
    );
  }

  void _showCreateVote() => CreateVoteSheet.show(
        context,
        api: _api,
        uid: _uid,
        userName: _data?.user?.name ?? '',
        onVoteCreated: (vote) =>
            setState(() => _voteModels.insert(0, vote)),
      );

  void _showCreateClass() => CreateClassSheet.show(
        context,
        onClassCreated: _loadUser,
      );

  Future<void> _generateReport(StudentModel student) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
          child: CircularProgressIndicator(color: TatvaColors.primary)),
    );

    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(Duration(days: 7));
      final report = await _api.getWeeklyReport(
        studentUid: student.id,
        startDate:
            '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}',
        endDate:
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      if (mounted) Navigator.pop(context);
      if (mounted) ReportSheet.show(context, student: student, report: report);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error generating report: $e', style: TextStyle()),
          backgroundColor: TatvaColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildDashboardScaffold(
      tabs: _tabs,
      bodyBuilder: () => IndexedStack(
          index: currentTab,
          children: [
            OverviewTab(
              user: _data?.user,
              teacherCount: _data?.teacherCount ?? 0,
              studentCount: _data?.studentCount ?? 0,
              classCount: _data?.classCount ?? 0,
              subjectAverages: _data?.subjectAverages ?? {},
              activityFeed: _data?.activityFeed ?? [],
              announcements: _announcementModels,
              api: _api,
              uid: _uid,
              onToggleAnnouncementLike: _toggleAnnouncementLike,
              greetingFade: greetingFade,
              greetingSlide: greetingSlide,
              greetingScale: greetingScale,
              onRefresh: _loadUser,
              onShowSubjectDetail: _showSubjectGradeDetail,
              onShowStudentPickerForReport: _showStudentPickerForReport,
              onSwitchTab: switchTab,
            ),
            ActivityTab(api: _api),
            GradeTrendsTab(subjectAverages: _data?.subjectAverages ?? {}),
            TeacherWorkloadTab(
              teacherCount: _data?.teacherCount ?? 0,
              classCount: _data?.classCount ?? 0,
              teachers: _data?.teachers ?? [],
              allClasses: _data?.allClasses ?? [],
              onShowTeacherDetail: _showTeacherDetail,
            ),
            StudentsTab(
              students: _students,
              filteredStudents: _filteredStudents,
              searchController: _studentSearchCtrl,
              loading: _studentsLoading,
              onFilterStudents: _filterStudents,
              onLoadStudents: _loadStudents,
              onShowStudentDetail: _showStudentEnrollmentDetail,
            ),
            ClassesTab(
              allClasses: _data?.allClasses ?? [],
              onShowClassDetail: _showClassDetail,
              onCreateClass: _showCreateClass,
              onRefresh: _loadUser,
            ),
            CommunicateTab(
              voteModels: _voteModels,
              parents: _data?.parents ?? [],
              api: _api,
              onNewAnnouncement: _showNewAnnouncement,
              onCreateVote: _showCreateVote,
              onVoteClosed: (vote) =>
                  setState(() => _voteModels.removeWhere((v) => v.id == vote.id)),
            ),
            ProfileTab(
              user: _data?.user,
              teacherCount: _data?.teacherCount ?? 0,
              onLogout: logout,
            ),
          ],
        ),
    );
  }
}
