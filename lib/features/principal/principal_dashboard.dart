import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/announcement_model.dart';
import '../../models/class_model.dart';
import '../../models/grade_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/vote_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/activity_event.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../shared/animations/animations.dart';
import '../../core/router/app_router.dart';
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
    with TickerProviderStateMixin {
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

  int _currentTab = 0;
  bool isLoading = true;

  List<StudentModel> _students = [];
  List<StudentModel> _filteredStudents = [];
  final _studentSearchCtrl = TextEditingController();
  bool _studentsLoading = false;

  late AnimationController _shimmerController;
  late AnimationController _greetingController;
  late AnimationController _tabController;
  late Animation<double> _shimmerAnim;
  late Animation<double> _greetingFade;
  late Animation<Offset> _greetingSlide;
  late Animation<double> _greetingScale;
  late Animation<double> _tabFade;

  final _api = ApiService();
  final _dashSvc = DashboardService();
  String _uid = '';

  PrincipalDashboardData? _data;
  List<AnnouncementModel> _announcementModels = [];
  List<VoteModel> _voteModels = [];

  @override
  void initState() {
    super.initState();
    _shimmerController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1200))
          ..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(_shimmerController);

    _greetingController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1000));
    _greetingFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _greetingController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut)));
    _greetingSlide = Tween<Offset>(begin: Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _greetingController,
            curve: Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _greetingScale = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
            parent: _greetingController,
            curve: Interval(0.0, 0.7, curve: Curves.easeOut)));

    _tabController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    _tabFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _tabController, curve: Curves.easeOut));

    _loadUser();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _greetingController.dispose();
    _tabController.dispose();
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
    if (!mounted) return;
    setState(() => isLoading = false);
    _greetingController.forward();
    _tabController.forward();
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

  void _switchTab(int index) {
    if (index == _currentTab) return;
    HapticFeedback.selectionClick();
    _tabController.reset();
    setState(() => _currentTab = index);
    _tabController.forward();
  }

  Future<void> _logout() async {
    LogoutSheet.show(context, onConfirm: () async {
      await AuthRepository().signOut();
      if (context.mounted) {
        AppRouter.toWelcomeAndClearStack(context);
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

  void _showNewAnnouncement() => NewAnnouncementSheet.show(
        context,
        api: _api,
        uid: _uid,
        userName: _data?.user?.name ?? '',
        onAnnouncementCreated: (ann) =>
            setState(() => _announcementModels.insert(0, ann)),
      );

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

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      body: isLoading ? _buildShimmer() : _buildBody(),
      bottomNavigationBar: isLoading ? null : _buildBottomNav(),
    );
  }

  Widget _buildShimmer() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _shimmerBox(double.infinity, 170, radius: 24),
            SizedBox(height: 20),
            Row(children: [
              Expanded(child: _shimmerBox(double.infinity, 88)),
              SizedBox(width: 10),
              Expanded(child: _shimmerBox(double.infinity, 88)),
              SizedBox(width: 10),
              Expanded(child: _shimmerBox(double.infinity, 88)),
            ]),
            SizedBox(height: 24),
            _shimmerBox(double.infinity, 200, radius: 16),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double width, double height, {double radius = 12}) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFE8F0E8), Color(0xFFF5FAF5), Color(0xFFE8F0E8)],
            stops: [
              (_shimmerAnim.value - 1).clamp(0.0, 1.0),
              _shimmerAnim.value.clamp(0.0, 1.0),
              (_shimmerAnim.value + 1).clamp(0.0, 1.0)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: FadeTransition(
        opacity: _tabFade,
        child: IndexedStack(
          index: _currentTab,
          children: [
            OverviewTab(
              user: _data?.user,
              teacherCount: _data?.teacherCount ?? 0,
              studentCount: _data?.studentCount ?? 0,
              classCount: _data?.classCount ?? 0,
              subjectAverages: _data?.subjectAverages ?? {},
              activityFeed: _data?.activityFeed ?? [],
              greetingFade: _greetingFade,
              greetingSlide: _greetingSlide,
              greetingScale: _greetingScale,
              onRefresh: _loadUser,
              onShowSubjectDetail: _showSubjectGradeDetail,
              onShowStudentPickerForReport: _showStudentPickerForReport,
              onSwitchTab: _switchTab,
            ),
            ActivityTab(
              activityFeed: _data?.activityFeed ?? [],
              onRefresh: _loadUser,
            ),
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
              onLogout: _logout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return TatvaBottomNavBar(
        items: _tabs, currentIndex: _currentTab, onTap: _switchTab);
  }
}
