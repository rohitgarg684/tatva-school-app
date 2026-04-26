import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/animations/animations.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/tatva_snackbar.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/grade_model.dart';
import '../../models/announcement_model.dart';
import '../../models/homework_model.dart';
import '../../models/behavior_point.dart';
import '../../models/attendance_record.dart';
import '../../models/story_post.dart';
import '../../models/activity_event.dart';
import 'tabs/home_tab.dart';
import 'tabs/classes_tab.dart';
import 'tabs/behavior_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/grades_tab.dart';
import 'tabs/homework_tab.dart';
import 'tabs/story_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/profile_tab.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
    TabItem(icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Classes'),
    TabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Behavior'),
    TabItem(icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, label: 'Attend'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.grade_outlined, activeIcon: Icons.grade_rounded, label: 'Grades'),
    TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Homework'),
    TabItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Story'),
    TabItem(icon: Icons.chat_outlined, activeIcon: Icons.chat_rounded, label: 'Messages'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentTab = 0;
  bool isLoading = true;

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  TeacherDashboardData? _data;
  List<HomeworkModel> _homework = [];
  List<BehaviorPoint> _classBehavior = [];
  List<AttendanceRecord> _todayAttendance = [];
  List<StoryPost> _classStory = [];

  // ── ANIMATIONS
  late AnimationController _shimmerController;
  late AnimationController _greetingController;
  late AnimationController _cardsController;
  late AnimationController _tabController;
  late Animation<double> _shimmerAnim;
  late Animation<double> _greetingFade;
  late Animation<Offset> _greetingSlide;
  late Animation<double> _greetingScale;
  late Animation<double> _tabFade;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _shimmerAnim = Tween<double>(begin: -1, end: 2).animate(_shimmerController);

    _greetingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _greetingFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _greetingController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _greetingSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _greetingController,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    _greetingScale = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
            parent: _greetingController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    _cardsController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _tabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _tabFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _tabController, curve: Curves.easeOut));

    _loadUser();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _greetingController.dispose();
    _cardsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadTeacherDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _homework = List.of(data.homework);
      _classBehavior = List.of(data.classBehavior);
      _todayAttendance = List.of(data.todayAttendance);
      _classStory = List.of(data.classStory);
    } catch (e) {
      debugPrint('TeacherDashboard._loadData error: $e');
    }
    if (!mounted) return;
    setState(() => isLoading = false);
    _greetingController.forward();
    _tabController.forward();
  }

  void _switchTab(int index) {
    if (index == _currentTab) return;
    HapticFeedback.selectionClick();
    _tabController.reset();
    setState(() => _currentTab = index);
    _tabController.forward();
  }

  void _logout() {
    LogoutSheet.show(context, onConfirm: () async {
      await AuthRepository().signOut();
      if (context.mounted) {
        AppRouter.toWelcomeAndClearStack(context);
      }
    });
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
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
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        _shimmerBox(double.infinity, 200, radius: 24),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _shimmerBox(double.infinity, 88)),
          const SizedBox(width: 10),
          Expanded(child: _shimmerBox(double.infinity, 88)),
          const SizedBox(width: 10),
          Expanded(child: _shimmerBox(double.infinity, 88))
        ]),
        const SizedBox(height: 20),
        _shimmerBox(double.infinity, 100),
        const SizedBox(height: 10),
        _shimmerBox(double.infinity, 100),
      ]),
    ));
  }

  Widget _shimmerBox(double width, double height, {double radius = 12}) =>
      AnimatedBuilder(
        animation: _shimmerAnim,
        builder: (_, __) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: const [
                    Color(0xFFE8F0E8),
                    Color(0xFFF5FAF5),
                    Color(0xFFE8F0E8)
                  ],
                  stops: [
                    (_shimmerAnim.value - 1).clamp(0.0, 1.0),
                    _shimmerAnim.value.clamp(0.0, 1.0),
                    (_shimmerAnim.value + 1).clamp(0.0, 1.0)
                  ])),
        ),
      );

  Widget _buildBody() => SafeArea(
      child: FadeTransition(
          opacity: _tabFade,
          child: IndexedStack(index: _currentTab, children: [
            TeacherHomeTab(
              user: _data?.user,
              classes: _data?.classes ?? [],
              homework: _homework,
              activityFeed: _data?.activityFeed ?? [],
              greetingFade: _greetingFade,
              greetingSlide: _greetingSlide,
              greetingScale: _greetingScale,
              onRefresh: _loadUser,
              onSwitchTab: _switchTab,
              onViewClassStudents: (cls) => _showClassStudents(cls),
              onDeleteClass: (cls) => _confirmDeleteClass(cls),
            ),
            TeacherClassesTab(
              classes: _data?.classes ?? [],
              students: _data?.studentsInFirstClass ?? [],
              onRefresh: _loadUser,
              onSwitchTab: _switchTab,
            ),
            TeacherBehaviorTab(
              classBehavior: _classBehavior,
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              uid: _uid,
              user: _data?.user,
              onBehaviorAdded: (bp) => setState(() => _classBehavior.add(bp)),
              onBehaviorDeleted: (id) =>
                  setState(() => _classBehavior.removeWhere((b) => b.id == id)),
            ),
            TeacherAttendanceTab(
              allSchoolStudents: _data?.allStudents ?? [],
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              todayAttendance: _todayAttendance,
              uid: _uid,
              onAttendanceSaved: (records) =>
                  setState(() => _todayAttendance = records),
            ),
            TeacherScheduleTab(
              classes: _data?.classes ?? [],
              uid: _uid,
            ),
            TeacherGradesTab(
              classes: _data?.classes ?? [],
              allGrades: _data?.allTeacherGrades ?? [],
              allSchoolStudents: _data?.allStudents ?? [],
              testTitles: _data?.testTitles ?? [],
              onRefresh: _loadUser,
            ),
            TeacherHomeworkTab(
              homework: _homework,
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              uid: _uid,
              user: _data?.user,
              onHomeworkAdded: (hw) =>
                  setState(() => _homework.insert(0, hw)),
              onHomeworkDeleted: (id) =>
                  setState(() => _homework.removeWhere((h) => h.id == id)),
            ),
            TeacherStoryTab(
              classStory: _classStory,
              classes: _data?.classes ?? [],
              uid: _uid,
              user: _data?.user,
              onStoryAdded: (post) =>
                  setState(() => _classStory.insert(0, post)),
              onStoryUpdated: (i, post) =>
                  setState(() => _classStory[i] = post),
            ),
            TeacherMessagesTab(parents: _data?.parentsInFirstClass ?? []),
            TeacherProfileTab(
              user: _data?.user,
              classCount: _data?.classes.length ?? 0,
              onLogout: _logout,
            ),
          ])));

  Widget _buildBottomNav() {
    return TatvaBottomNavBar(
        items: _tabs, currentIndex: _currentTab, onTap: _switchTab);
  }

  // ─── SHARED SHEETS (used by HomeTab callbacks) ────────────────────────────

  void _showClassStudents(ClassModel cls) {
    HapticFeedback.lightImpact();
    final classStudents = (_data?.studentsInFirstClass ?? [])
        .where((s) => cls.studentUids.contains(s.uid))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text('${cls.subject} · ${classStudents.length} students',
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (classStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline,
                    color: TatvaColors.neutral400, size: 40),
                const SizedBox(height: 8),
                const Text('No students in this class yet',
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral400)),
              ]),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: classStudents.length,
                itemBuilder: (_, i) {
                  final s = classStudents[i];
                  final initials = s.name.isNotEmpty
                      ? s.name
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                      : '?';
                  final colors = [
                    TatvaColors.primary,
                    TatvaColors.info,
                    TatvaColors.accent,
                    TatvaColors.purple,
                    TatvaColors.success
                  ];
                  final c = colors[i % colors.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.withOpacity(0.1))),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: c.withOpacity(0.12),
                        child: Text(initials,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: c)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral900)),
                              Text(s.email,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: TatvaColors.neutral400)),
                            ]),
                      ),
                    ]),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _confirmDeleteClass(ClassModel cls) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${cls.name}"?\n\n'
            'This will remove ${cls.studentUids.length} student(s) and '
            '${cls.parentUids.length} parent(s) from this class. '
            'This action cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: TatvaColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteClass(cls.id);
                TatvaSnackbar.show(context, '"${cls.name}" deleted');
                _loadUser();
              } catch (e) {
                TatvaSnackbar.show(context, 'Failed to delete class');
                debugPrint('Delete class error: $e');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: TatvaColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
