import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/animations/animations.dart';
import '../../shared/theme/colors.dart';
import '../../shared/utils/greeting.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import '../../models/announcement_model.dart';
import '../../models/homework_model.dart';
import '../../models/vote_model.dart';
import '../../models/class_model.dart';
import '../../models/behavior_point.dart';
import '../../models/attendance_record.dart';
import '../../models/activity_event.dart';
import '../../models/content_item.dart';
import 'tabs/home_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/homework_tab.dart';
import 'tabs/grades_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/profile_tab.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Homework'),
    TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Grades'),
    TabItem(icon: Icons.lightbulb_outline_rounded, activeIcon: Icons.lightbulb_rounded, label: 'Learn'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentTab = 0;
  bool isLoading = true;

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  StudentDashboardData? _data;
  List<AnnouncementModel> _announcements = [];
  final Set<String> _completedIds = {};

  late AnimationController _shimmerController;
  late AnimationController _greetingController;
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadStudentDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _announcements = List.of(data.announcements);
      _completedIds.clear();
      for (final hw in data.homework) {
        if (hw.isSubmittedBy(_uid)) _completedIds.add(hw.id);
      }
    } catch (e) {
      debugPrint('StudentDashboard._loadData error: $e');
    }
    if (!mounted) return;
    setState(() => isLoading = false);
    _greetingController.forward();
    _tabController.forward();
  }

  String get _motivationalText {
    final h = DateTime.now().hour;
    if (h < 12) return 'Start strong today! 💪';
    if (h < 17) return 'Keep pushing forward! 🚀';
    return 'Great work today! 🌟';
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

  void _handleMarkDone(String hwId) {
    setState(() => _completedIds.add(hwId));
    _api.submitHomework(hwId);
  }

  void _handleMarkIncomplete(String hwId) {
    setState(() => _completedIds.remove(hwId));
  }

  void _handleToggleAnnouncementLike(AnnouncementModel ann) {
    if (ann.id.isEmpty) return;
    setState(() {
      final idx = _announcements.indexWhere((a) => a.id == ann.id);
      if (idx < 0) return;
      final current = _announcements[idx];
      final liked = current.likedBy.contains(_uid);
      final newLikedBy = List<String>.from(current.likedBy);
      liked ? newLikedBy.remove(_uid) : newLikedBy.add(_uid);
      _announcements[idx] = current.copyWith(likedBy: newLikedBy);
    });
    _api.toggleAnnouncementLike(ann.id);
  }

  void _handleMarkCompleted(ContentItem item) {
    setState(() => item.completedBy.add(_uid));
    _api.markContentCompleted(item.id);
  }

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
          Expanded(child: _shimmerBox(double.infinity, 88)),
        ]),
        const SizedBox(height: 28),
        _shimmerBox(140, 18),
        const SizedBox(height: 14),
        _shimmerBox(double.infinity, 72),
        const SizedBox(height: 10),
        _shimmerBox(double.infinity, 72),
      ]),
    ));
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
            colors: const [
              Color(0xFFE8F0E8),
              Color(0xFFF5FAF5),
              Color(0xFFE8F0E8)
            ],
            stops: [
              (_shimmerAnim.value - 1).clamp(0.0, 1.0),
              _shimmerAnim.value.clamp(0.0, 1.0),
              (_shimmerAnim.value + 1).clamp(0.0, 1.0),
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
      child: IndexedStack(index: _currentTab, children: [
        StudentHomeTab(
          user: _data?.user,
          primaryClass: _data?.primaryClass,
          pendingHomeworkCount: (_data?.homework ?? []).where((h) => !_completedIds.contains(h.id)).length,
          grades: _data?.grades ?? [],
          announcements: _announcements,
          behaviorPoints: _data?.behaviorPoints ?? [],
          behaviorScore: _data?.behaviorScore ?? 0,
          attendance: _data?.attendance ?? [],
          activityFeed: _data?.activityFeed ?? [],
          activeVotes: _data?.activeVotes ?? [],
          motivationalText: _motivationalText,
          greetingFade: _greetingFade,
          greetingSlide: _greetingSlide,
          greetingScale: _greetingScale,
          onSwitchToHomework: () => _switchTab(2),
          onRefresh: _loadUser,
          uid: _uid,
          onToggleAnnouncementLike: _handleToggleAnnouncementLike,
        ),
        StudentScheduleTab(
          primaryClass: _data?.primaryClass,
          api: _api,
        ),
        StudentHomeworkTab(
          homework: _data?.homework ?? [],
          completedIds: _completedIds,
          uid: _uid,
          api: _api,
          onMarkDone: _handleMarkDone,
          onMarkIncomplete: _handleMarkIncomplete,
        ),
        StudentGradesTab(grades: _data?.grades ?? []),
        StudentLearnTab(
          contentItems: _data?.contentItems ?? [],
          uid: _uid,
          onMarkCompleted: _handleMarkCompleted,
        ),
        StudentProfileTab(
          user: _data?.user,
          primaryClass: _data?.primaryClass,
          onLogout: _logout,
        ),
      ]),
    ));
  }

  Widget _buildBottomNav() {
    return TatvaBottomNavBar(items: _tabs, currentIndex: _currentTab, onTap: _switchTab);
  }
}
