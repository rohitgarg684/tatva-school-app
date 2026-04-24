import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/animations/animations.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../auth/welcome_screen.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../models/audience.dart';
import '../../models/user_model.dart';
import '../../models/grade_model.dart';
import '../../models/announcement_model.dart';
import '../../models/homework_model.dart';
import '../../models/vote_model.dart';
import '../../models/class_model.dart';
import '../../models/behavior_point.dart';
import '../../models/behavior_category.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/story_post.dart';
import '../../models/activity_event.dart';
import '../../models/content_item.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  bool isLoading = true;

  static const Color bg = TatvaColors.bgLight;
  static const Color bgCard = TatvaColors.bgCard;
  static const Color primary = TatvaColors.primary;
  static const Color accent = TatvaColors.accent;
  static const Color textDark = TatvaColors.neutral900;
  static const Color textMid = TatvaColors.neutral600;
  static const Color textLight = TatvaColors.neutral400;
  static const Color danger = TatvaColors.error;
  static const Color success = TatvaColors.success;
  static const Color info = TatvaColors.info;
  static const Color purple = TatvaColors.purple;

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  UserModel? _user;
  ClassModel? _primaryClass;
  List<GradeModel> _grades = [];
  List<AnnouncementModel> _announcements = [];
  List<HomeworkModel> _homework = [];
  List<VoteModel> _activeVotes = [];
  final Set<String> _completedIds = {};
  List<BehaviorPoint> _behaviorPoints = [];
  int _behaviorScore = 0;
  List<AttendanceRecord> _attendance = [];
  List<StoryPost> _storyPosts = [];
  List<ActivityEvent> _activityFeed = [];
  List<ContentItem> _contentItems = [];

  // ── ANIMATIONS ─────────────────────────────────────────────────────────────
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
      _uid = AuthRepository().currentUid ?? 'student_arjun';
      final data = await _dashSvc.loadStudentDashboard(overrideUid: _uid, forceRefresh: true);
      _user = data.user;
      _primaryClass = data.primaryClass;
      _grades = data.grades;
      _announcements = data.announcements;
      _homework = data.homework;
      _activeVotes = data.activeVotes;
      _behaviorPoints = data.behaviorPoints;
      _behaviorScore = data.behaviorScore;
      _attendance = data.attendance;
      _storyPosts = data.storyPosts;
      _activityFeed = data.activityFeed;
      _contentItems = data.contentItems;
      _completedIds.clear();
      for (final hw in _homework) {
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

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌤️';
    if (h < 17) return '☀️';
    return '🌙';
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

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Raleway')),
        backgroundColor: info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  void _logout() {
    LogoutSheet.show(context, onConfirm: () {
      AppRouter.toWelcomeAndClearStack(context);
    });
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: bg,
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
        _buildHomeTab(),
        _buildHomeworkTab(),
        _buildGradesTab(),
        _buildStoryTab(),
        _buildLearnTab(),
        _buildProfileTab(),
      ]),
    ));
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home_rounded,
        'label': 'Home'
      },
      {
        'icon': Icons.assignment_outlined,
        'activeIcon': Icons.assignment_rounded,
        'label': 'Homework'
      },
      {
        'icon': Icons.bar_chart_outlined,
        'activeIcon': Icons.bar_chart_rounded,
        'label': 'Grades'
      },
      {
        'icon': Icons.auto_stories_outlined,
        'activeIcon': Icons.auto_stories_rounded,
        'label': 'Story'
      },
      {
        'icon': Icons.lightbulb_outline_rounded,
        'activeIcon': Icons.lightbulb_rounded,
        'label': 'Learn'
      },
      {
        'icon': Icons.person_outline_rounded,
        'activeIcon': Icons.person_rounded,
        'label': 'Profile'
      },
    ];
    return Container(
      decoration: BoxDecoration(
          color: bgCard,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, -6))
          ]),
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
                children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = _currentTab == index;
              // Badge for pending homework
              final pendingHw = _homework
                  .where((h) => !_completedIds.contains(h.id))
                  .length;
              return Expanded(
                  child: GestureDetector(
                onTap: () => _switchTab(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                      color: isActive
                          ? info.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                              isActive
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
                              key: ValueKey(isActive),
                              color: isActive ? info : textLight,
                              size: 22)),
                      if (index == 1 && pendingHw > 0 && !isActive)
                        Positioned(
                          top: -3,
                          right: -4,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                                color: danger,
                                shape: BoxShape.circle,
                                border: Border.all(color: bgCard, width: 1.5)),
                            child: Center(
                                child: Text('$pendingHw',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold))),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: isActive ? info : textLight,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500),
                        child: Text(item['label'] as String)),
                  ]),
                ),
              ));
            })),
          )),
    );
  }

  // ─── HOME TAB ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    final pendingHw =
        _homework.where((h) => !_completedIds.contains(h.id)).length;
    return RefreshIndicator(
      color: info,
      onRefresh: _loadUser,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeTransition(
              opacity: _greetingFade,
              child: SlideTransition(
                  position: _greetingSlide,
                  child: ScaleTransition(
                      scale: _greetingScale, child: _buildGreetingCard()))),
          const SizedBox(height: 20),
          // Quick stats
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _miniStat(
                    '$pendingHw',
                    'Pending\nHomework',
                    Icons.assignment_outlined,
                    pendingHw > 0 ? accent : success),
                const SizedBox(width: 10),
                _miniStat('${_grades.length}', 'Grades\nReceived',
                    Icons.grade_outlined, info),
                const SizedBox(width: 10),
                _miniStat('${_announcements.length}', 'New\nPosts',
                    Icons.campaign_outlined, purple),
              ])),
          const SizedBox(height: 24),
          // Pending homework nudge
          if (pendingHw > 0) ...[
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _switchTab(1),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.3))),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.assignment_outlined,
                              color: accent, size: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(
                                '$pendingHw homework assignment${pendingHw > 1 ? 's' : ''} due',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textDark)),
                            const Text('Tap to view and mark as done',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: textLight)),
                          ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: accent),
                    ]),
                  ),
                )),
            const SizedBox(height: 20),
          ],
          // ── Behavior Points ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.star_rounded, color: accent, size: 18)),
                  const SizedBox(width: 10),
                  const Expanded(
                      child: Text('Behavior Points',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textDark))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _behaviorScore >= 0
                            ? success.withOpacity(0.1)
                            : danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded,
                          size: 14,
                          color: _behaviorScore >= 0 ? success : danger),
                      const SizedBox(width: 4),
                      Text('$_behaviorScore pts',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _behaviorScore >= 0 ? success : danger)),
                    ]),
                  ),
                ]),
                if (_behaviorPoints.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ...(_behaviorPoints.length > 3
                          ? _behaviorPoints.sublist(0, 3)
                          : _behaviorPoints)
                      .map((bp) {
                    final cat = BehaviorCategory.fromId(bp.categoryId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(cat.icon, size: 14, color: TatvaColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(cat.name,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textDark)),
                              if (bp.note.isNotEmpty)
                                Text(bp.note,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 11,
                                        color: textLight)),
                            ])),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: bp.isPositive
                                  ? success.withOpacity(0.1)
                                  : danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                              '${bp.isPositive ? '+' : '-'}${bp.points}',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: bp.isPositive ? success : danger)),
                        ),
                      ]),
                    );
                  }),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 16),
          // ── Attendance Summary ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: info.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: info, size: 16)),
                  const SizedBox(width: 10),
                  const Text('Attendance',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                ]),
                const SizedBox(height: 14),
                Builder(builder: (_) {
                  final presentCount = _attendance
                      .where((r) => r.status == AttendanceStatus.present)
                      .length;
                  final absentCount = _attendance
                      .where((r) => r.status == AttendanceStatus.absent)
                      .length;
                  final tardyCount = _attendance
                      .where((r) => r.status == AttendanceStatus.tardy)
                      .length;
                  return Row(children: [
                    _attendanceStat(
                        '${AttendanceStatus.present.emoji} Present',
                        '$presentCount',
                        success),
                    const SizedBox(width: 10),
                    _attendanceStat(
                        '${AttendanceStatus.absent.emoji} Absent',
                        '$absentCount',
                        danger),
                    const SizedBox(width: 10),
                    _attendanceStat(
                        '${AttendanceStatus.tardy.emoji} Tardy',
                        '$tardyCount',
                        accent),
                  ]);
                }),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Announcements',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3))),
          const SizedBox(height: 12),
          _buildAnnouncements(),
          const SizedBox(height: 28),
          _buildRecentActivity(),
          const SizedBox(height: 28),
          _buildVoteResults(),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon, Color color) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 14)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.5)),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 10,
                  color: textLight,
                  height: 1.3)),
        ]),
      ));

  Widget _attendanceStat(String label, String value, Color color) => Expanded(
          child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 11, color: textMid)),
        ]),
      ));

  Widget _buildAnnouncements() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final a = _announcements[index];
        return StaggeredItem(
          index: index,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: index == 0
                        ? info.withOpacity(0.2)
                        : Colors.grey.shade100)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.campaign_outlined, color: info, size: 16)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(a.title,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textDark))),
                      if (index == 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('New',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: danger,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ]),
                    const SizedBox(height: 5),
                    Text(a.body,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textMid,
                            height: 1.55)),
                    const SizedBox(height: 4),
                    Text('By ${a.createdByName}',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: textLight)),
                  ])),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity() {
    if (_activityFeed.isEmpty) return const SizedBox.shrink();
    final events = _activityFeed.length > 5
        ? _activityFeed.sublist(0, 5)
        : _activityFeed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Recent Activity',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.3))),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100)),
          child: Column(
            children: events.asMap().entries.map((entry) {
              final idx = entry.key;
              final event = entry.value;
              final icon = _activityIcon(event.type.name);
              final timeAgo = event.createdAt != null
                  ? _formatTimeAgo(event.createdAt!)
                  : '';
              return Column(children: [
                if (idx > 0)
                  Divider(height: 1, color: Colors.grey.shade100),
                Padding(
                  padding: EdgeInsets.only(
                      top: idx == 0 ? 0 : 10,
                      bottom: idx == events.length - 1 ? 0 : 10),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: info.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 16, color: info)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(event.title,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark))),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              color: textLight)),
                  ]),
                ),
              ]);
            }).toList(),
          ),
        ),
      ),
    ]);
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'behavior':
        return Icons.star;
      case 'attendance':
        return Icons.check_circle;
      case 'homework':
        return Icons.assignment;
      case 'grades':
        return Icons.grade;
      case 'announcements':
        return Icons.campaign;
      case 'story':
        return Icons.photo_camera;
      default:
        return Icons.circle;
    }
  }

  Widget _buildVoteResults() {
    if (_activeVotes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Current Votes',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.3))),
      const SizedBox(height: 4),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Text('Parents are voting on these now',
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 12, color: textLight))),
      const SizedBox(height: 12),
      ...List.generate(_activeVotes.length, (i) {
        final v = _activeVotes[i];
        final total = v.votes.total;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: info.withOpacity(0.2), width: 1.5)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: info.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(v.type,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: info,
                            fontWeight: FontWeight.w700))),
                const Spacer(),
                const Icon(Icons.how_to_vote_outlined,
                    color: textLight, size: 13),
                const SizedBox(width: 4),
                Text('$total votes',
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 11, color: textLight)),
              ]),
              const SizedBox(height: 10),
              Text(v.question,
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      height: 1.4)),
              const SizedBox(height: 12),
              _simpleVoteBar('🏫 School', v.votes.school, total, success),
              const SizedBox(height: 6),
              _simpleVoteBar(
                  '🏠 No School', v.votes.noSchool, total, danger),
              const SizedBox(height: 6),
              _simpleVoteBar(
                  '🤷 Undecided', v.votes.undecided, total, accent),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _simpleVoteBar(String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0;
    return Row(children: [
      SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 11, color: textLight))),
      Expanded(
          child: AnimatedProgressBar(
              value: pct, color: color, height: 5, delayMs: 0)),
      const SizedBox(width: 8),
      Text('${(pct * 100).toStringAsFixed(0)}%',
          style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    ]);
  }

  // ─── HOMEWORK TAB ──────────────────────────────────────────────────────────
  Widget _buildHomeworkTab() {
    final pending =
        _homework.where((h) => !_completedIds.contains(h.id)).toList();
    final done =
        _homework.where((h) => _completedIds.contains(h.id)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Homework',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text('${pending.length} pending · ${done.length} done',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        // Summary strip
        FadeSlideIn(
          delayMs: 80,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [info.withOpacity(0.12), info.withOpacity(0.04)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: info.withOpacity(0.15))),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${done.length}/${_homework.length} completed',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0,
                            end: _homework.isEmpty
                                ? 0.0
                                : done.length / _homework.length),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: info.withOpacity(0.1),
                          valueColor:
                              AlwaysStoppedAnimation(v >= 1.0 ? success : info),
                        ),
                      ),
                    ),
                  ])),
              const SizedBox(width: 16),
              Text(
                  _homework.isEmpty
                      ? '—'
                      : '${(_homework.isEmpty ? 0 : done.length / _homework.length * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: done.length == _homework.length ? success : info)),
            ]),
          ),
        ),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('To Do',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const SizedBox(height: 12),
          ...pending
              .asMap()
              .entries
              .map((e) => _hwStudentCard(e.value, e.key, false)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Completed ✓',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: success)),
          const SizedBox(height: 12),
          ...done
              .asMap()
              .entries
              .map((e) => _hwStudentCard(e.value, e.key, true)),
        ],
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _hwStudentCard(HomeworkModel hw, int idx, bool isDone) {
    final color = isDone ? success : info;
    return StaggeredItem(
      index: idx,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    isDone ? success.withOpacity(0.15) : Colors.grey.shade100)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [color.withOpacity(0.08), color.withOpacity(0.02)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.assignment_outlined,
                      color: color,
                      size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(hw.title,
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                            decoration:
                                isDone ? TextDecoration.lineThrough : null,
                            decorationColor: textLight)),
                    Text(hw.subject,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: textLight)),
                  ])),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hw.description,
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: textMid,
                      height: 1.5)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: textLight),
                const SizedBox(width: 4),
                Text('Due ${hw.dueDate}',
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 11, color: textLight)),
                const SizedBox(width: 12),
                Icon(Icons.person_outline, size: 12, color: textLight),
                const SizedBox(width: 4),
                Text(hw.teacherName,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 11, color: textLight)),
              ]),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    if (isDone) {
                      _completedIds.remove(hw.id);
                    } else {
                      _completedIds.add(hw.id);
                      _api.submitHomework(hw.id);
                    }
                  });
                  if (!isDone) _snack('Marked as done! Great work 🎉');
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color:
                          isDone ? Colors.grey.shade50 : info.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isDone
                              ? Colors.grey.shade200
                              : info.withOpacity(0.2))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isDone ? Icons.undo_rounded : Icons.check_rounded,
                            size: 16, color: isDone ? textLight : info),
                        const SizedBox(width: 6),
                        Text(isDone ? 'Mark as Incomplete' : 'Mark as Done',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDone ? textLight : info)),
                      ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── GRADES TAB ────────────────────────────────────────────────────────────
  Widget _buildGradesTab() {
    final Map<String, List<GradeModel>> bySubject = {};
    for (final g in _grades)
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    double totalPct = 0;
    for (final g in _grades) totalPct += g.percentage;
    final overallAvg = _grades.isEmpty ? 0.0 : totalPct / _grades.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('My Grades',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        FadeSlideIn(
            delayMs: 80,
            child: const Text('Your academic performance this term',
                style: TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        FadeSlideIn(
            child: WaveCard(
          gradientColors: const [
            Color(0xFF1565C0),
            Color(0xFF1E88E5),
            Color(0xFF42A5F5)
          ],
          boxShadow: [
            BoxShadow(
                color: info.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10))
          ],
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Overall Average',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7))),
                const SizedBox(height: 4),
                SlotNumber(
                    value: overallAvg,
                    decimals: 1,
                    suffix: '%',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      overallAvg >= 90
                          ? '🏆 Excellent'
                          : overallAvg >= 75
                              ? '👍 Good'
                              : overallAvg >= 60
                                  ? '📈 Improving'
                                  : '💪 Needs Work',
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const Spacer(),
              Column(children: [
                Text('${_grades.length}',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text('Assessments',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6))),
              ]),
            ]),
          ),
        )),
        const SizedBox(height: 24),
        const Text('By Subject',
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDark)),
        const SizedBox(height: 12),
        ...bySubject.entries.toList().asMap().entries.map((entry) {
          final index = entry.key;
          final subjectName = entry.value.key;
          final subjectGrades = entry.value.value;
          final colors = [info, success, accent, purple, danger];
          final color = colors[index % colors.length];
          double subAvg = subjectGrades
                  .map((g) => g.percentage)
                  .reduce((a, b) => a + b) /
              subjectGrades.length;
          final grade = subAvg >= 90
              ? 'A+'
              : subAvg >= 80
                  ? 'A'
                  : subAvg >= 70
                      ? 'B'
                      : subAvg >= 60
                          ? 'C'
                          : 'D';
          return StaggeredItem(
            index: index,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Column(children: [
                Row(children: [
                  Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(grade,
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: color)))),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(subjectName,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark)),
                        Text(
                            '${subjectGrades.length} assessment${subjectGrades.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 11,
                                color: textLight)),
                      ])),
                  SlotNumber(
                      value: subAvg,
                      decimals: 1,
                      suffix: '%',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color),
                      delayMs: 200 + index * 80),
                ]),
                const SizedBox(height: 10),
                AnimatedProgressBar(
                    value: subAvg / 100,
                    color: color,
                    height: 6,
                    delayMs: 300 + index * 80),
                const SizedBox(height: 12),
                ...subjectGrades.map((g) {
                  final score = g.score;
                  final total = g.total;
                  final pct = total > 0 ? score / total : 0.0;
                  final gc = pct >= 0.9
                      ? success
                      : pct >= 0.75
                          ? accent
                          : danger;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration:
                              BoxDecoration(color: gc, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(g.assessmentName,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  color: textMid))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: gc.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('${score.toInt()}/${total.toInt()}',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 11,
                                color: gc,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  );
                }),
              ]),
            ),
          );
        }),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ─── PROFILE TAB ───────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        FadeSlideIn(
            child: HeroAvatar(
                heroTag: 'student_avatar',
                initial: _user?.initial ?? '?',
                radius: 46,
                bgColor: info.withOpacity(0.1),
                textColor: info,
                borderColor: accent)),
        const SizedBox(height: 16),
        FadeSlideIn(
            delayMs: 80,
            child: Text(_user?.name ?? '',
                style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.5))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 100,
            child: Text(_user?.email ?? '',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 10),
        FadeSlideIn(
            delayMs: 120,
            child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                    color: info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Student',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: info,
                        fontWeight: FontWeight.w700)))),
        const SizedBox(height: 28),
        FadeSlideIn(
            delayMs: 130,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: info.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: info.withOpacity(0.15))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.class_outlined, color: info, size: 15),
                      const SizedBox(width: 6),
                      const Text('My Class',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: info,
                              fontWeight: FontWeight.w700))
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_primaryClass?.name ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark)),
                            Text(_primaryClass?.subject ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: accent.withOpacity(0.3))),
                          child: Text(_primaryClass?.classCode ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                  letterSpacing: 2))),
                    ]),
                  ]),
            )),
        FadeSlideIn(
            delayMs: 150,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Row(children: [
                CircleAvatar(
                    radius: 22,
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text((_primaryClass?.teacherName ?? '?').isNotEmpty ? _primaryClass!.teacherName[0] : '?',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_primaryClass?.teacherName ?? '',
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                      Text('Your Teacher · ${_primaryClass?.subject ?? ''}',
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: textLight)),
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.email_outlined,
                            size: 11, color: textLight),
                        const SizedBox(width: 4),
                        Text(_primaryClass?.teacherEmail ?? '',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 10,
                                color: textLight)),
                      ]),
                    ])),
              ]),
            )),
        const SizedBox(height: 12),
        ...List.generate(2, (index) {
          final items = [
            [Icons.school_outlined, 'School', 'Tatva Academy'],
            [Icons.verified_outlined, 'Status', 'Verified'],
          ];
          return StaggeredItem(
              index: index,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: RippleTap(
                    rippleColor: info,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100)),
                      child: Row(children: [
                        Icon(items[index][0] as IconData,
                            color: info, size: 18),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Text(items[index][1] as String,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: textLight))),
                        Text(items[index][2] as String,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: textDark,
                                fontWeight: FontWeight.w600)),
                      ]),
                    )),
              ));
        }),
        const SizedBox(height: 24),
        FadeSlideIn(
            delayMs: 200,
            child: BouncyTap(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: danger.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: danger.withOpacity(0.15))),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, color: danger, size: 18),
                        const SizedBox(width: 8),
                        const Text('Sign Out',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: danger)),
                      ]),
                ))),
        const SizedBox(height: 16),
        const Text('v1.0.0 · Tatva Academy',
            style: TextStyle(
                fontFamily: 'Raleway', fontSize: 11, color: textLight)),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ─── STORY TAB ─────────────────────────────────────────────────────────────
  Widget _buildStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Class Story',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: Text('${_storyPosts.length} posts from your class',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        if (_storyPosts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.auto_stories_outlined,
                    size: 48, color: textLight.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No stories yet',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
              ]),
            ),
          )
        else
          ...List.generate(_storyPosts.length, (i) {
            final post = _storyPosts[i];
            final timeAgo = post.createdAt != null ? _formatTimeAgo(post.createdAt!) : '';
            return StaggeredItem(
              index: i,
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor: info.withOpacity(0.1),
                            child: Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0]
                                    : '?',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: info))),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(post.authorName,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textDark)),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(post.authorRole,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: purple)),
                                ),
                                const SizedBox(width: 6),
                                Text(timeAgo,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 10,
                                        color: textLight)),
                              ]),
                            ])),
                      ]),
                      const SizedBox(height: 12),
                      Text(post.text,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              color: textMid,
                              height: 1.5)),
                      if (post.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12)),
                          child: Center(
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                const Icon(Icons.photo_library_outlined,
                                    color: textLight, size: 18),
                                const SizedBox(width: 6),
                                Text('${post.mediaUrls.length} photo${post.mediaUrls.length > 1 ? 's' : ''}',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        color: textLight)),
                              ])),
                        ),
                      ],
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          final liked = post.likedBy;
                          setState(() {
                            if (liked.contains(_uid)) {
                              liked.remove(_uid);
                            } else {
                              liked.add(_uid);
                            }
                          });
                          _api.toggleStoryLike(post.id);
                        },
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(
                              post.isLikedBy(_uid)
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: post.isLikedBy(_uid) ? danger : textLight),
                          const SizedBox(width: 4),
                          Text('${post.likeCount}',
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textMid)),
                        ]),
                      ),
                    ]),
              ),
            );
          }),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ─── LEARN TAB ────────────────────────────────────────────────────────────
  Widget _buildLearnTab() {
    final Map<String, List<ContentItem>> byCategory = {};
    for (final item in _contentItems) {
      final key = '${item.category.emoji} ${item.category.label}';
      byCategory.putIfAbsent(key, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Beyond School',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: const Text('Big ideas & extra learning',
                style: TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        if (_contentItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(children: [
                Icon(Icons.lightbulb_outline_rounded,
                    size: 48, color: textLight.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('No content yet',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
              ]),
            ),
          )
        else
          ...byCategory.entries.toList().asMap().entries.map((entry) {
            final catIdx = entry.key;
            final catLabel = entry.value.key;
            final items = entry.value.value;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (catIdx > 0) const SizedBox(height: 20),
                  StaggeredItem(
                    index: catIdx,
                    child: Text(catLabel,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                  ),
                  const SizedBox(height: 10),
                  ...items.asMap().entries.map((itemEntry) {
                    final ci = itemEntry.value;
                    final completed = ci.isCompletedBy(_uid);
                    return StaggeredItem(
                      index: catIdx * 10 + itemEntry.key,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: completed
                            ? null
                            : () {
                                setState(() {
                                  ci.completedBy.add(_uid);
                                });
                                _api.markContentCompleted(ci.id);
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: completed
                                      ? success.withOpacity(0.2)
                                      : Colors.grey.shade100)),
                          child: Row(children: [
                          Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: completed
                                      ? success.withOpacity(0.08)
                                      : info.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(
                                  completed
                                      ? Icons.check_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  color: completed ? success : info,
                                  size: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(ci.title,
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                        decoration: completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                        decorationColor: textLight)),
                                if (ci.description.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(ci.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 11,
                                            color: textMid,
                                            height: 1.4)),
                                  ),
                                const SizedBox(height: 4),
                                Row(children: [
                                  const Icon(Icons.schedule_rounded,
                                      size: 11, color: textLight),
                                  const SizedBox(width: 4),
                                  Text(ci.duration,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 10,
                                          color: textLight)),
                                  if (completed) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: success.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: const Text('Completed',
                                          style: TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: success)),
                                    ),
                                  ],
                                ]),
                              ])),
                          ]),
                        ),
                      ),
                    );
                  }),
                ]);
          }),
        const SizedBox(height: 24),
      ]),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  // ─── GREETING CARD ─────────────────────────────────────────────────────────
  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: const [
          Color(0xFF1565C0),
          Color(0xFF1E88E5),
          Color(0xFF42A5F5)
        ],
        boxShadow: [
          BoxShadow(
              color: info.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10)),
          BoxShadow(
              color: info.withOpacity(0.15),
              blurRadius: 48,
              offset: const Offset(0, 20)),
        ],
        child: Stack(children: [
          Positioned(
              top: -20,
              right: 60,
              child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
          Positioned(
              top: 10,
              right: -20,
              child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.04)))),
          Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Row(children: [
                              Text(_greetingEmoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(_greeting,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500)),
                            ]),
                            const SizedBox(height: 6),
                            TypewriterText(
                                text: _user?.name ?? '',
                                delayMs: 400,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 6),
                            Text('${_primaryClass?.name ?? ''} · ${_primaryClass?.subject ?? ''}',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'student_avatar',
                          initial: _user?.initial ?? '?',
                          radius: 26,
                          bgColor: Colors.white.withOpacity(0.15),
                          textColor: Colors.white,
                          borderColor: Colors.white.withOpacity(0.3)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        Icon(Icons.lightbulb_outline_rounded,
                            color: accent, size: 16),
                        const SizedBox(width: 8),
                        Text(_motivationalText,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ])),
        ]),
      ),
    );
  }
}
