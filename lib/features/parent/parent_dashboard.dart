import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../messaging/messaging_screen.dart';
import '../../shared/animations/animations.dart';
import '../auth/welcome_screen.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../models/child_info.dart';
import '../../models/announcement_model.dart';
import '../../models/vote_model.dart';
import '../../models/story_post.dart';
import '../../models/activity_event.dart';
import '../../models/content_item.dart';
import '../../models/weekly_report.dart';
import 'widgets/teacher_profile_sheet.dart';
import 'widgets/weekly_report_sheet.dart';
import 'tabs/home_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/behavior_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/story_tab.dart';
import 'tabs/vote_tab.dart';
import 'tabs/profile_tab.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Progress'),
    TabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Behavior'),
    TabItem(icon: Icons.lightbulb_outline, activeIcon: Icons.lightbulb_rounded, label: 'Learn'),
    TabItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Story'),
    TabItem(icon: Icons.how_to_vote_outlined, activeIcon: Icons.how_to_vote_rounded, label: 'Vote'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  int _currentTab = 0;
  bool isLoading = true;

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  ParentDashboardData? _data;
  int _selectedChildIndex = 0;
  List<StoryPost> _storyPosts = [];
  List<VoteModel> _activeVotes = [];

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
        curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _greetingSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _greetingController,
                curve: const Interval(0, 0.7, curve: Curves.easeOutCubic)));
    _greetingScale = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
            parent: _greetingController,
            curve: const Interval(0, 0.7, curve: Curves.easeOut)));
    _tabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _tabFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _tabController, curve: Curves.easeOut));
    _loadData();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _greetingController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadParentDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _activeVotes = List.of(data.activeVotes);
      _storyPosts = List.of(data.storyPosts);
      if (_selectedChildIndex >= data.childrenData.length) {
        _selectedChildIndex = 0;
      }
    } catch (e) {
      debugPrint('ParentDashboard._loadData error: $e');
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

  void _castVote(int index, String option) async {
    if (_activeVotes[index].hasVoted(_uid)) return;
    final voteId = _activeVotes[index].id;
    final old = _activeVotes[index];
    final oldVotes = old.votes;
    setState(() {
      _activeVotes[index] = VoteModel(
        id: old.id,
        question: old.question,
        type: old.type,
        createdBy: old.createdBy,
        createdByName: old.createdByName,
        createdByRole: old.createdByRole,
        votes: VoteCount(
          school: oldVotes.school + (option == 'school' ? 1 : 0),
          noSchool: oldVotes.noSchool + (option == 'no_school' ? 1 : 0),
          undecided: oldVotes.undecided + (option == 'undecided' ? 1 : 0),
        ),
        voters: [...old.voters, _uid],
        active: old.active,
        createdAt: old.createdAt,
      );
    });
    _api.castVote(voteId, option);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Vote submitted!', style: TextStyle()),
      backgroundColor: TatvaColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  ChildDashboardData? get _currentChild {
    final children = _data?.childrenData ?? [];
    return children.isNotEmpty ? children[_selectedChildIndex] : null;
  }

  void _showTeacherProfile() {
    final child = _currentChild;
    TeacherProfileSheet.show(
      context,
      teacherName: child?.info.teacherName ?? '',
      teacherEmail: child?.info.teacherEmail ?? '',
      teacherUid: child?.info.teacherUid ?? '',
      subject: child?.info.subject ?? '',
      className: child?.info.className ?? '',
      classCode: child?.childClass?.classCode ?? '',
    );
  }

  void _toggleStoryLike(String postId) {
    setState(() {
      _storyPosts = [
        for (final p in _storyPosts)
          if (p.id == postId)
            StoryPost(
              id: p.id,
              authorUid: p.authorUid,
              authorName: p.authorName,
              authorRole: p.authorRole,
              classId: p.classId,
              className: p.className,
              text: p.text,
              mediaUrls: p.mediaUrls,
              mediaType: p.mediaType,
              likedBy: p.isLikedBy(_uid)
                  ? p.likedBy.where((uid) => uid != _uid).toList()
                  : [...p.likedBy, _uid],
              commentCount: p.commentCount,
              createdAt: p.createdAt,
            )
          else
            p,
      ];
    });
    _api.toggleStoryLike(postId);
  }

  void _logout() {
    LogoutSheet.show(context, onConfirm: () async {
      await AuthRepository().signOut();
      if (context.mounted) {
        AppRouter.toWelcomeAndClearStack(context);
      }
    });
  }

  Future<void> _generateWeeklyReport() async {
    final child = _currentChild;
    if (child == null) return;
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final json = await _api.getWeeklyReport(
        studentUid: child.childUid,
        startDate: fmt(weekStart),
        endDate: fmt(weekEnd),
      );

      final grades = (json['grades'] as List? ?? []);
      double gradeAvg = 0;
      if (grades.isNotEmpty) {
        double sum = 0;
        for (final g in grades) {
          final total = (g['total'] as num?) ?? 0;
          final score = (g['score'] as num?) ?? 0;
          sum += total > 0 ? score / total * 100 : 0;
        }
        gradeAvg = sum / grades.length;
      }

      final attList = (json['attendance'] as List? ?? []);
      int present = 0, absent = 0, tardy = 0;
      for (final a in attList) {
        switch ((a['status'] as String? ?? '').toLowerCase()) {
          case 'present':
            present++;
          case 'absent':
            absent++;
          case 'tardy':
            tardy++;
        }
      }
      final totalDays = present + absent + tardy;

      final bpList = (json['behaviorPoints'] as List? ?? []);
      int pos = 0, neg = 0;
      for (final bp in bpList) {
        if (bp['isPositive'] == true) {
          pos++;
        } else {
          neg++;
        }
      }

      final report = WeeklyReport(
        studentName: child.info.childName,
        className: child.info.className,
        weekLabel: '${fmt(weekStart)} to ${fmt(weekEnd)}',
        behaviorPointsTotal: pos - neg,
        positivePoints: pos,
        negativePoints: neg,
        daysPresent: present,
        daysAbsent: absent,
        daysTardy: tardy,
        totalSchoolDays: totalDays > 0 ? totalDays : 5,
        gradeAverage: gradeAvg,
      );
      if (!mounted) return;
      Navigator.pop(context);
      WeeklyReportSheet.show(context, report);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  Widget _childSwitcher() {
    final childrenData = _data?.childrenData ?? [];
    if (childrenData.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: childrenData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isActive = i == _selectedChildIndex;
          final name = childrenData[i].info.childName;
          return GestureDetector(
            onTap: () {
              if (i == _selectedChildIndex) return;
              HapticFeedback.selectionClick();
              setState(() => _selectedChildIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? TatvaColors.purple : TatvaColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive ? TatvaColors.purple : Colors.grey.shade200),
              ),
              child: Text(name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : TatvaColors.neutral600)),
            ),
          );
        },
      ),
    );
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

  Widget _buildShimmer() => SafeArea(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            _sBox(double.infinity, 200, r: 24),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _sBox(double.infinity, 88)),
              const SizedBox(width: 10),
              Expanded(child: _sBox(double.infinity, 88)),
              const SizedBox(width: 10),
              Expanded(child: _sBox(double.infinity, 88))
            ]),
            const SizedBox(height: 20),
            _sBox(double.infinity, 80),
            const SizedBox(height: 10),
            _sBox(double.infinity, 80),
          ])));

  Widget _sBox(double w, double h, {double r = 12}) => AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(r),
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
                  ]))));

  Widget _buildBody() => SafeArea(
      child: FadeTransition(
          opacity: _tabFade,
          child: IndexedStack(index: _currentTab, children: [
            ParentHomeTab(
              user: _data?.user,
              currentChild: _currentChild,
              childrenData: _data?.childrenData ?? [],
              selectedChildIndex: _selectedChildIndex,
              announcements: _data?.announcements ?? [],
              activityFeed: _data?.activityFeed ?? [],
              greetingFade: _greetingFade,
              greetingSlide: _greetingSlide,
              greetingScale: _greetingScale,
              onShowTeacherProfile: _showTeacherProfile,
              onSwitchTab: _switchTab,
              onRefresh: _loadData,
              childSwitcher: _childSwitcher(),
            ),
            ParentScheduleTab(
              childrenData: _data?.childrenData ?? [],
              selectedChildIndex: _selectedChildIndex,
              api: _api,
            ),
            ParentProgressTab(currentChild: _currentChild),
            ParentBehaviorTab(currentChild: _currentChild),
            ParentLearnTab(
              currentChild: _currentChild,
              contentItems: _data?.contentItems ?? [],
              childSwitcher: _childSwitcher(),
            ),
            ParentStoryTab(
              storyPosts: _storyPosts,
              uid: _uid,
              onToggleLike: _toggleStoryLike,
            ),
            ParentVoteTab(
              activeVotes: _activeVotes,
              uid: _uid,
              onCastVote: _castVote,
            ),
            ParentProfileTab(
              user: _data?.user,
              currentChild: _currentChild,
              onShowTeacherProfile: _showTeacherProfile,
              onGenerateReport: _generateWeeklyReport,
              onLogout: _logout,
            ),
          ])));

  Widget _buildBottomNav() {
    return TatvaBottomNavBar(items: _tabs, currentIndex: _currentTab, onTap: _switchTab);
  }
}
