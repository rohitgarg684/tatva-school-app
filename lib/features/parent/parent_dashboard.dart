import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../messaging/messaging_screen.dart';
import '../../shared/animations/animations.dart';
import '../auth/welcome_screen.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/vote_service.dart';
import '../../services/story_service.dart';
import '../../services/attendance_service.dart';
import '../../services/report_service.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/grade_model.dart';
import '../../models/announcement_model.dart';
import '../../models/vote_model.dart';
import '../../models/child_info.dart';
import '../../models/behavior_point.dart';
import '../../models/behavior_category.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/story_post.dart';
import '../../models/activity_event.dart';
import '../../models/content_item.dart';
import '../../models/weekly_report.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
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
  final _voteSvc = VoteService();
  final _storySvc = StoryService();
  String _uid = '';

  UserModel? _user;
  int _selectedChildIndex = 0;
  List<ChildDashboardData> _childrenData = [];
  List<StoryPost> _storyPosts = [];
  List<ActivityEvent> _activityFeed = [];
  List<ContentItem> _contentItems = [];
  List<AnnouncementModel> _announcements = [];
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
      _uid = AuthRepository().currentUid ?? 'parent_suresh';
      final data = await _dashSvc.loadParentDashboard(overrideUid: _uid);
      _user = data.user;
      _childrenData = data.childrenData;
      _announcements = data.announcements;
      _activeVotes = data.activeVotes;
      _storyPosts = data.storyPosts;
      _activityFeed = data.activityFeed;
      _contentItems = data.contentItems;
      if (_selectedChildIndex >= _childrenData.length) {
        _selectedChildIndex = 0;
      }
    } catch (_) {}
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
    await _voteSvc.castVote(voteId: voteId, option: option, voterUid: _uid);
    if (!mounted) return;
    await _loadData();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Vote submitted!',
          style: TextStyle(fontFamily: 'Raleway')),
      backgroundColor: success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  ChildDashboardData? get _currentChild =>
      _childrenData.isNotEmpty ? _childrenData[_selectedChildIndex] : null;

  // ── TEACHER PROFILE SHEET ──────────────────────────────────────────────────
  void _showTeacherProfile() {
    final child = _currentChild;
    final tName = child?.info.teacherName ?? '';
    final tEmail = child?.info.teacherEmail ?? '';
    final tUid = child?.info.teacherUid ?? '';
    final subj = child?.info.subject ?? '';
    final cls = child?.info.className ?? '';
    final code = child?.childClass?.classCode ?? '';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          // Avatar
          CircleAvatar(
              radius: 36,
              backgroundColor: primary.withOpacity(0.1),
              child: Text(tName.isNotEmpty ? tName[0] : '?',
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary))),
          const SizedBox(height: 14),
          Text(tName,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          Text('$subj Teacher · $cls',
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 13, color: textLight)),
          const SizedBox(height: 24),
          // Email row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: info.withOpacity(0.15))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      const Icon(Icons.email_outlined, color: info, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('School Email',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: textLight)),
                    const SizedBox(height: 2),
                    Text(tEmail,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark)),
                  ])),
            ]),
          ),
          const SizedBox(height: 12),
          // Class code row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primary.withOpacity(0.1))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.class_outlined,
                      color: primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Class Code',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: textLight)),
                    const SizedBox(height: 2),
                    Text(code,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primary,
                            letterSpacing: 3)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          // Message button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MessagingScreen(
                            otherUserId: tUid,
                            otherUserName: tName,
                            otherUserRole: 'Teacher',
                            otherUserEmail: tEmail,
                            avatarColor: primary,
                          )));
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Send a Message',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  void _logout() {
    LogoutSheet.show(context, onConfirm: () {
      AppRouter.toWelcomeAndClearStack(context);
    });
  }

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
            _homeTab(),
            _progressTab(),
            _buildBehaviorTab(),
            _learnTab(),
            _storyTab(),
            _voteTab(),
            _profileTab(),
          ])));

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.home_outlined,
        'active': Icons.home_rounded,
        'label': 'Home'
      },
      {
        'icon': Icons.bar_chart_outlined,
        'active': Icons.bar_chart_rounded,
        'label': 'Progress'
      },
      {
        'icon': Icons.emoji_events_outlined,
        'active': Icons.emoji_events_rounded,
        'label': 'Behavior'
      },
      {
        'icon': Icons.lightbulb_outline,
        'active': Icons.lightbulb_rounded,
        'label': 'Learn'
      },
      {
        'icon': Icons.auto_stories_outlined,
        'active': Icons.auto_stories_rounded,
        'label': 'Story'
      },
      {
        'icon': Icons.how_to_vote_outlined,
        'active': Icons.how_to_vote_rounded,
        'label': 'Vote'
      },
      {
        'icon': Icons.person_outline_rounded,
        'active': Icons.person_rounded,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                child: Row(
                    children: List.generate(items.length, (i) {
                  final isActive = _currentTab == i;
                  return Expanded(
                      child: GestureDetector(
                          onTap: () => _switchTab(i),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                  color: isActive
                                      ? purple.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                            isActive
                                                ? items[i]['active'] as IconData
                                                : items[i]['icon'] as IconData,
                                            key: ValueKey(isActive),
                                            color:
                                                isActive ? purple : textLight,
                                            size: 22)),
                                    const SizedBox(height: 4),
                                    AnimatedDefaultTextStyle(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        style: TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 10,
                                            color:
                                                isActive ? purple : textLight,
                                            fontWeight: isActive
                                                ? FontWeight.w700
                                                : FontWeight.w500),
                                        child:
                                            Text(items[i]['label'] as String)),
                                  ]))));
                })))));
  }

  Widget _childSwitcher() {
    if (_childrenData.length <= 1) return const SizedBox.shrink();
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _childrenData.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isActive = i == _selectedChildIndex;
          final name = _childrenData[i].info.childName;
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
                color: isActive ? purple : bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isActive ? purple : Colors.grey.shade200),
              ),
              child: Text(name,
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : textMid)),
            ),
          );
        },
      ),
    );
  }

  // ─── HOME ──────────────────────────────────────────────────────────────────
  Widget _homeTab() {
    final child = _currentChild;
    final grades = child?.grades ?? [];
    double total = grades.fold(
        0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
    final avg = grades.isEmpty ? 0.0 : total / grades.length;
    final attSummary = child != null
        ? AttendanceService().computeSummary(child.attendance)
        : (present: 0, absent: 0, tardy: 0, total: 0);
    return RefreshIndicator(
        color: purple,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            FadeTransition(
                opacity: _greetingFade,
                child: SlideTransition(
                    position: _greetingSlide,
                    child: ScaleTransition(
                        scale: _greetingScale, child: _greetingCard(avg)))),
            _childSwitcher(),
            const SizedBox(height: 20),
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: purple.withOpacity(0.15))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.class_outlined, color: purple, size: 15),
                        const SizedBox(width: 6),
                        Text("${child?.info.childName ?? ''}'s Class",
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: purple,
                                fontWeight: FontWeight.w700))
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(child?.info.className ?? '',
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: _showTeacherProfile,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${child?.info.subject ?? ''} · ',
                                          style: const TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 12,
                                              color: textLight)),
                                      Text(child?.info.teacherName ?? '',
                                          style: const TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 12,
                                              color: info,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: info)),
                                      const SizedBox(width: 3),
                                      const Icon(Icons.open_in_new_rounded,
                                          size: 11, color: info),
                                    ]),
                              ),
                            ])),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: accent.withOpacity(0.3))),
                            child: Text(child?.childClass?.classCode ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                    letterSpacing: 2))),
                      ]),
                    ])),
            const SizedBox(height: 16),
            // Attendance summary
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            color: info, size: 15),
                        const SizedBox(width: 6),
                        const Text('Attendance',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: info,
                                fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        _attChip('${attSummary.present}', 'Present', success),
                        const SizedBox(width: 10),
                        _attChip('${attSummary.absent}', 'Absent', danger),
                        const SizedBox(width: 10),
                        _attChip('${attSummary.tardy}', 'Tardy', accent),
                        const Spacer(),
                        if (attSummary.total > 0)
                          Text(
                              '${(attSummary.present / attSummary.total * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: success)),
                      ]),
                    ]),
              ),
            ),
            const SizedBox(height: 12),
            // Behavior score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.star_rounded,
                          color: purple, size: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('Behavior Score',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: textLight)),
                        const SizedBox(height: 2),
                        Text('${child?.behaviorScore ?? 0} points',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark)),
                      ])),
                  GestureDetector(
                    onTap: () => _switchTab(2),
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Details',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: purple,
                                fontWeight: FontWeight.w600))),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _qaBtn('Message\nTeacher', Icons.chat_outlined, info,
                      _showTeacherProfile),
                  const SizedBox(width: 8),
                  _qaBtn('Progress\nReport', Icons.bar_chart_rounded, purple,
                      () => _switchTab(1)),
                  const SizedBox(width: 8),
                  _qaBtn('Cast\nVote', Icons.how_to_vote_outlined, accent,
                      () => _switchTab(5)),
                ])),
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
            ..._announcements.asMap().entries.map((e) => Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: e.key == 0
                              ? purple.withOpacity(0.2)
                              : Colors.grey.shade100)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(e.value.title,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textDark))),
                          if (e.key == 0)
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
                                        fontWeight: FontWeight.w700))),
                        ]),
                        const SizedBox(height: 5),
                        Text(e.value.body,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: textMid,
                                height: 1.55)),
                        const SizedBox(height: 4),
                        Text('By ${e.value.createdByName}',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 10,
                                color: textLight)),
                      ]),
                )),
            if (_activityFeed.isNotEmpty) ...[
              const SizedBox(height: 24),
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
              ..._activityFeed.take(5).toList().asMap().entries.map((entry) {
                final evt = entry.value;
                final timeAgo = evt.createdAt != null
                    ? _formatTimeAgo(evt.createdAt!)
                    : '';
                IconData evtIcon;
                Color evtColor;
                switch (evt.type) {
                  case ActivityType.behaviorPoint:
                    evtIcon = Icons.star_rounded;
                    evtColor = purple;
                    break;
                  case ActivityType.attendance:
                    evtIcon = Icons.calendar_today_rounded;
                    evtColor = info;
                    break;
                  case ActivityType.homeworkAssigned:
                    evtIcon = Icons.assignment_outlined;
                    evtColor = accent;
                    break;
                  case ActivityType.homeworkSubmitted:
                    evtIcon = Icons.assignment_turned_in_outlined;
                    evtColor = success;
                    break;
                  case ActivityType.gradeEntered:
                    evtIcon = Icons.grading_rounded;
                    evtColor = info;
                    break;
                  case ActivityType.announcement:
                    evtIcon = Icons.campaign_outlined;
                    evtColor = danger;
                    break;
                  case ActivityType.storyPost:
                    evtIcon = Icons.auto_stories_outlined;
                    evtColor = purple;
                    break;
                  case ActivityType.voteCreated:
                    evtIcon = Icons.how_to_vote_outlined;
                    evtColor = accent;
                    break;
                  case ActivityType.studentEnrolled:
                    evtIcon = Icons.person_add_outlined;
                    evtColor = success;
                    break;
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: evtColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(evtIcon, color: evtColor, size: 18)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(evt.title,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark)),
                          if (evt.body.isNotEmpty)
                            Text(evt.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: textMid)),
                        ])),
                    if (timeAgo.isNotEmpty)
                      Text(timeAgo,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              color: textLight)),
                  ]),
                );
              }),
            ],
            const SizedBox(height: 24),
          ]),
        ));
  }

  Widget _attChip(String val, String label, Color color) => Column(children: [
        Text(val,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Raleway', fontSize: 10, color: textLight)),
      ]);

  Widget _greetingCard(double avg) {
    final child = _currentChild;
    final grades = child?.grades ?? [];
    final childNames = _childrenData.map((c) => c.info.childName).toList();
    final parentOfLabel = childNames.length <= 1
        ? 'Parent of ${childNames.isNotEmpty ? childNames.first : ''}'
        : 'Parent of ${childNames.join(' & ')}';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: const [
          Color(0xFF6A1B9A),
          Color(0xFF8E24AA),
          Color(0xFFAB47BC)
        ],
        boxShadow: [
          BoxShadow(
              color: purple.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10))
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
                                      color: Colors.white.withOpacity(0.7)))
                            ]),
                            const SizedBox(height: 6),
                            TypewriterText(
                                text: _user?.name ?? '',
                                delayMs: 400,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 4),
                            Text(parentOfLabel,
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'parent_avatar',
                          initial: _user?.initial ?? '?',
                          radius: 26,
                          bgColor: Colors.white.withOpacity(0.15),
                          textColor: Colors.white,
                          borderColor: Colors.white.withOpacity(0.3)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _miniStat(
                          '${avg.toStringAsFixed(0)}%', 'Avg Grade', accent),
                      const SizedBox(width: 20),
                      _miniStat('${grades.length}', 'Tests', Colors.white),
                      const SizedBox(width: 20),
                      _miniStat('${grades.map((g) => g.subject).toSet().length}', 'Subjects', Colors.white),
                    ]),
                  ])),
        ]),
      ),
    );
  }

  Widget _miniStat(String val, String label, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(val,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 10,
                color: Colors.white.withOpacity(0.5))),
      ]);

  // ─── PROGRESS ──────────────────────────────────────────────────────────────
  Widget _progressTab() {
    final child = _currentChild;
    final grades = child?.grades ?? [];
    final bySubject = <String, List<GradeModel>>{};
    for (final g in grades)
      bySubject.putIfAbsent(g.subject, () => []).add(g);
    double total = grades.fold(
        0.0, (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0));
    final overallAvg = grades.isEmpty ? 0.0 : total / grades.length;
    final colors = [info, success, accent, purple, danger];

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: Text("${child?.info.childName ?? ''}'s Progress",
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('This Academic Term',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 20),
          FadeSlideIn(
              delayMs: 80,
              child: WaveCard(
                gradientColors: const [
                  Color(0xFF6A1B9A),
                  Color(0xFF8E24AA),
                  Color(0xFFAB47BC)
                ],
                boxShadow: [
                  BoxShadow(
                      color: purple.withOpacity(0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ],
                child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Row(children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                    overallAvg >= 90
                                        ? '🏆 Excellent'
                                        : overallAvg >= 75
                                            ? '👍 Good'
                                            : '📈 Improving',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600))),
                          ]),
                      const Spacer(),
                      Column(children: [
                        Text('${grades.length}',
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
                    ])),
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
            final i = entry.key;
            final subName = entry.value.key;
            final subGrades = entry.value.value;
            final color = colors[i % colors.length];
            double subAvg = subGrades.isEmpty
                ? 0.0
                : subGrades.fold(0.0,
                        (s, g) => s + (g.total > 0 ? g.score / g.total * 100 : 0.0)) /
                    subGrades.length;
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
                index: i,
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
                            Text(subName,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textDark)),
                            Text('${subGrades.length} assessments',
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
                          delayMs: 200 + i * 80),
                    ]),
                    const SizedBox(height: 10),
                    AnimatedProgressBar(
                        value: subAvg / 100,
                        color: color,
                        height: 6,
                        delayMs: 300 + i * 80),
                    const SizedBox(height: 12),
                    ...subGrades.map((g) {
                      final pct = g.total > 0 ? g.score / g.total : 0.0;
                      final c = pct >= 0.9
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
                                decoration: BoxDecoration(
                                    color: c, shape: BoxShape.circle)),
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
                                    color: c.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text(
                                    '${g.score.toInt()}/${g.total.toInt()}',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 11,
                                        color: c,
                                        fontWeight: FontWeight.bold))),
                          ]));
                    }),
                  ]),
                ));
          }),
        ]));
  }

  // ─── BEHAVIOR ────────────────────────────────────────────────────────────
  Widget _buildBehaviorTab() {
    final child = _currentChild;
    final points = child?.behaviorPoints ?? [];
    final score = child?.behaviorScore ?? 0;

    final catSummary = <String, int>{};
    for (final p in points) {
      catSummary[p.categoryId] = (catSummary[p.categoryId] ?? 0) + p.points;
    }
    final sortedCats = catSummary.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: Text("${child?.info.childName ?? ''}'s Behavior",
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Tracking positive & constructive moments',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 20),
          FadeSlideIn(
              delayMs: 80,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: score >= 0
                            ? [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)]
                            : [danger.withOpacity(0.8), danger]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: (score >= 0 ? purple : danger).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ]),
                child: Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net Score',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7))),
                        Text('$score',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ]),
                  const Spacer(),
                  Column(children: [
                    Text('${points.where((p) => p.isPositive).length}',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Positive',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6))),
                    const SizedBox(height: 6),
                    Text('${points.where((p) => !p.isPositive).length}',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('Needs Work',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.6))),
                  ]),
                ]),
              )),
          if (sortedCats.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Top Categories',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 12),
            ...sortedCats.take(5).map((e) {
              final cat = BehaviorCategory.fromId(e.key);
              final isPos = e.value >= 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  Icon(cat.icon,
                      color: isPos ? success : danger, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(cat.name,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textDark))),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: (isPos ? success : danger).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                          '${isPos ? '+' : ''}${e.value}',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPos ? success : danger))),
                ]),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text('Recent Activity',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 12),
          if (points.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Center(
                  child: Column(children: [
                Icon(Icons.emoji_events_outlined, color: textLight, size: 40),
                const SizedBox(height: 12),
                const Text('No behavior points yet',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        color: textLight)),
              ])),
            )
          else
            ...points.take(20).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final cat = BehaviorCategory.fromId(p.categoryId);
              final timeAgo = p.createdAt != null
                  ? _formatTimeAgo(p.createdAt!)
                  : '';
              return StaggeredItem(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100)),
                    child: Row(children: [
                      Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: (p.isPositive ? success : danger)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(cat.icon,
                              color: p.isPositive ? success : danger,
                              size: 18)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(cat.name,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textDark)),
                            Text('By ${p.awardedByName}',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: textLight)),
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                        Text(p.isPositive ? '+1' : '-1',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: p.isPositive ? success : danger)),
                        if (timeAgo.isNotEmpty)
                          Text(timeAgo,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: textLight)),
                      ]),
                    ]),
                  ));
            }),
          const SizedBox(height: 24),
        ]));
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  // ─── LEARN ──────────────────────────────────────────────────────────────────
  Widget _learnTab() {
    final child = _currentChild;
    final childUid = child?.childUid ?? '';
    final Map<String, List<ContentItem>> byCategory = {};
    for (final item in _contentItems) {
      final key = '${item.category.emoji} ${item.category.label}';
      byCategory.putIfAbsent(key, () => []).add(item);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        _childSwitcher(),
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
            child: Text(
                "At-home learning for ${child?.info.childName ?? 'your child'}",
                style: const TextStyle(
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
                    final completed = ci.isCompletedBy(childUid);
                    return StaggeredItem(
                      index: catIdx * 10 + itemEntry.key,
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
                    );
                  }),
                ]);
          }),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ─── STORY ──────────────────────────────────────────────────────────────────
  Widget _storyTab() {
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
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Updates from the classroom',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 24),
          if (_storyPosts.isEmpty)
            FadeSlideIn(
                delayMs: 80,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.auto_stories_outlined,
                        color: textLight, size: 40),
                    const SizedBox(height: 12),
                    const Text('No story posts yet',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textLight)),
                  ])),
                ))
          else
            ..._storyPosts.asMap().entries.map((entry) {
              final i = entry.key;
              final post = entry.value;
              final timeAgo = post.createdAt != null
                  ? _formatTimeAgo(post.createdAt!)
                  : '';
              return FadeSlideIn(
                  delayMs: 80 + i * 60,
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: i < _storyPosts.length - 1 ? 14 : 0),
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
                                backgroundColor: purple.withOpacity(0.1),
                                child: Text(
                                    post.authorName.isNotEmpty
                                        ? post.authorName[0]
                                        : '?',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: purple))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(post.authorName,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textDark)),
                                  Text(
                                      '${post.authorRole}${post.className.isNotEmpty ? ' · ${post.className}' : ''}',
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 11,
                                          color: textLight)),
                                ])),
                            if (timeAgo.isNotEmpty)
                              Text(timeAgo,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 11,
                                      color: textLight)),
                          ]),
                          if (post.text.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(post.text,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: textMid,
                                    height: 1.5)),
                          ],
                          if (post.mediaUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                                height: 160,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                    child: Icon(
                                        post.mediaType == StoryMediaType.video
                                            ? Icons.play_circle_outline
                                            : Icons.image_outlined,
                                        color: textLight,
                                        size: 36))),
                          ],
                          const SizedBox(height: 10),
                          Row(children: [
                            GestureDetector(
                              onTap: () async {
                                await _storySvc.toggleLike(post.id, _uid);
                                _loadData();
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        post.isLikedBy(_uid)
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: post.isLikedBy(_uid)
                                            ? danger
                                            : textLight,
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount}',
                                        style: TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 12,
                                            color: post.isLikedBy(_uid)
                                                ? danger
                                                : textLight)),
                                  ]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline_rounded,
                                color: textLight, size: 15),
                            const SizedBox(width: 4),
                            Text('${post.commentCount}',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                          ]),
                        ]),
                  ));
            }),
          const SizedBox(height: 24),
        ]));
  }

  // ─── VOTE ──────────────────────────────────────────────────────────────────
  Widget _voteTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Active Vote',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Your vote matters for school decisions',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 24),
          if (_activeVotes.isEmpty)
            FadeSlideIn(
                delayMs: 80,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.how_to_vote_outlined,
                        color: textLight, size: 40),
                    const SizedBox(height: 12),
                    const Text('No active votes right now',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textLight)),
                  ])),
                ))
          else
            ..._activeVotes.asMap().entries.map((entry) {
              final i = entry.key;
              final voteData = entry.value;
              final total = voteData.votes.total;
              final hasVoted = voteData.hasVoted(_uid);
              return FadeSlideIn(
                  delayMs: 80 + i * 60,
                  child: Container(
                    margin: EdgeInsets.only(
                        bottom: i < _activeVotes.length - 1 ? 16 : 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: info.withOpacity(0.2), width: 1.5)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                    color: info.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(voteData.type,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 11,
                                        color: info,
                                        fontWeight: FontWeight.w700))),
                            const Spacer(),
                            Text('$total votes',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                          ]),
                          const SizedBox(height: 14),
                          Text(voteData.question,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                  height: 1.4)),
                          const SizedBox(height: 20),
                          if (!hasVoted)
                            ...[
                              'school',
                              'no_school',
                              'undecided'
                            ].map((opt) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GestureDetector(
                                    onTap: () => _castVote(i, opt),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                      decoration: BoxDecoration(
                                          color: info.withOpacity(0.06),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: info.withOpacity(0.2))),
                                      child: Row(children: [
                                        Icon(
                                            opt == 'school'
                                                ? Icons.school_outlined
                                                : opt == 'no_school'
                                                    ? Icons.home_outlined
                                                    : Icons
                                                        .help_outline_rounded,
                                            color: info,
                                            size: 18),
                                        const SizedBox(width: 12),
                                        Text(
                                            opt == 'school'
                                                ? '🏫 School as usual'
                                                : opt == 'no_school'
                                                    ? '🏠 No school tomorrow'
                                                    : '🤷 Undecided',
                                            style: const TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: textDark)),
                                      ]),
                                    ))))
                          else
                            ...{
                              '🏫 School': voteData.votes.school,
                              '🏠 No School': voteData.votes.noSchool,
                              '🤷 Undecided': voteData.votes.undecided,
                            }.entries.map((e) {
                              final pct =
                                  total > 0 ? e.value / total : 0.0;
                              final c = e.key.contains('School') &&
                                      !e.key.contains('No')
                                  ? success
                                  : e.key.contains('No')
                                      ? danger
                                      : accent;
                              return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(children: [
                                    SizedBox(
                                        width: 110,
                                        child: Text(e.key,
                                            style: const TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 12,
                                                color: textLight))),
                                    Expanded(
                                        child: AnimatedProgressBar(
                                            value: pct,
                                            color: c,
                                            height: 6,
                                            delayMs: 0)),
                                    const SizedBox(width: 8),
                                    Text(
                                        '${(pct * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 12,
                                            color: c,
                                            fontWeight: FontWeight.bold)),
                                  ]));
                            }),
                          if (hasVoted)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                  color: success.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8)),
                              child:
                                  Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.check_circle_outline,
                                    color: success, size: 14),
                                const SizedBox(width: 6),
                                const Text('Your vote has been submitted',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        color: success))
                              ]),
                            ),
                        ]),
                  ));
            }),
        ]));
  }

  // ─── PROFILE ───────────────────────────────────────────────────────────────
  Widget _profileTab() {
    final child = _currentChild;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          FadeSlideIn(
              child: HeroAvatar(
                  heroTag: 'parent_avatar',
                  initial: _user?.initial ?? '?',
                  radius: 46,
                  bgColor: purple.withOpacity(0.1),
                  textColor: purple,
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
                      color: purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Parent',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: purple,
                          fontWeight: FontWeight.w700)))),
          const SizedBox(height: 28),
          FadeSlideIn(
              delayMs: 130,
              child: GestureDetector(
                onTap: _showTeacherProfile,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primary.withOpacity(0.15))),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 22,
                        backgroundColor: primary.withOpacity(0.1),
                        child: Text((child?.info.teacherName ?? '').isNotEmpty ? child!.info.teacherName[0] : '?',
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
                          Text(child?.info.teacherName ?? '',
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark)),
                          Text("${child?.info.childName ?? ''}'s Teacher · ${child?.info.subject ?? ''}",
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  color: textLight)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.email_outlined,
                                size: 11, color: info),
                            const SizedBox(width: 4),
                            Text(child?.info.teacherEmail ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 10,
                                    color: info)),
                          ]),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: primary)),
                  ]),
                ),
              )),
          ...List.generate(4, (i) {
            final items = [
              [Icons.child_care_outlined, 'Child', child?.info.childName ?? ''],
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.class_outlined, 'Class', child?.info.className ?? ''],
              [Icons.verified_outlined, 'Status', 'Verified'],
            ];
            return StaggeredItem(
                index: i,
                child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: RippleTap(
                        rippleColor: purple,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade100)),
                          child: Row(children: [
                            Icon(items[i][0] as IconData,
                                color: purple, size: 18),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(items[i][1] as String,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 13,
                                        color: textLight))),
                            Text(items[i][2] as String,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: textDark,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ))));
          }),
          const SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 180,
              child: BouncyTap(
                  onTap: _generateWeeklyReport,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: info.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: info.withOpacity(0.15))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assessment_outlined,
                              color: info, size: 18),
                          const SizedBox(width: 8),
                          const Text('Weekly Report',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: info)),
                        ]),
                  ))),
          const SizedBox(height: 12),
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
        ]));
  }

  Future<void> _generateWeeklyReport() async {
    final child = _currentChild;
    if (child == null) return;
    HapticFeedback.lightImpact();

    final now = DateTime.now();
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = (DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reportSvc = ReportService();
      final report = await reportSvc.generateWeeklyReport(
        studentUid: child.childUid,
        studentName: child.info.childName,
        className: child.info.className,
        classIds: child.info.classId.isNotEmpty ? [child.info.classId] : [],
        weekStart: fmt(weekStart),
        weekEnd: fmt(weekEnd),
      );
      if (!mounted) return;
      Navigator.pop(context);
      _showReportSheet(report, reportSvc);
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  void _showReportSheet(WeeklyReport report, ReportService reportSvc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(
                child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('📊 Weekly Report',
                style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark)),
            const SizedBox(height: 4),
            Text('${report.studentName} · ${report.weekLabel}',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 12, color: textLight)),
            const SizedBox(height: 20),
            _reportRow('📚 Grade Average',
                '${report.gradeAverage.toStringAsFixed(1)}%'),
            _reportRow('✅ Attendance Rate',
                '${report.attendanceRate.toStringAsFixed(0)}%'),
            _reportRow('📅 Present / Absent / Tardy',
                '${report.daysPresent} / ${report.daysAbsent} / ${report.daysTardy}'),
            _reportRow('⭐ Behavior Points', '${report.behaviorPointsTotal}'),
            _reportRow('👍 Positive', '${report.positivePoints}'),
            _reportRow('👎 Needs Work', '${report.negativePoints}'),
            _reportRow('📝 Homework',
                '${report.homeworkCompleted}/${report.homeworkTotal}'),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                final csv = reportSvc.exportToCsv(report);
                Clipboard.setData(ClipboardData(text: csv));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Report copied to clipboard',
                      style: TextStyle(fontFamily: 'Raleway')),
                  backgroundColor: success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    color: info,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: info.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ]),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.copy_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text('Export CSV to Clipboard',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _reportRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textMid))),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textDark)),
      ]));

  Widget _qaBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Column(children: [
                    Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, color: color, size: 18)),
                    const SizedBox(height: 7),
                    Text(label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: textMid,
                            fontWeight: FontWeight.w600,
                            height: 1.3)),
                  ]))));
}
