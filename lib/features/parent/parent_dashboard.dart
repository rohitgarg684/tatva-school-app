import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../messaging/messaging_screen.dart';
import '../../shared/animations/animations.dart';
import '../auth/welcome_screen.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';

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

  // ── FAKE DATA ──────────────────────────────────────────────────────────────
  final String userName = 'Mr. Suresh Mehta';
  final String userEmail = 'suresh.mehta@gmail.com';
  final String childName = 'Arjun Mehta';
  final String className = 'Grade 8 — Section A';
  final String subject = 'Mathematics';
  final String teacherName = 'Mrs. Priya Sharma';
  final String teacherEmail = 'priya.sharma@tatva.edu';
  final String classCode = 'MATH312';

  final List<Map<String, dynamic>> _grades = [
    {
      'subject': 'Mathematics',
      'assessmentName': 'Unit Test 3',
      'score': 46.0,
      'total': 50.0
    },
    {
      'subject': 'Mathematics',
      'assessmentName': 'Worksheet 5',
      'score': 38.0,
      'total': 40.0
    },
    {
      'subject': 'Mathematics',
      'assessmentName': 'Unit Test 2',
      'score': 42.0,
      'total': 50.0
    },
    {
      'subject': 'Science',
      'assessmentName': 'Lab Report',
      'score': 39.0,
      'total': 50.0
    },
    {
      'subject': 'Science',
      'assessmentName': 'Unit Test 2',
      'score': 44.0,
      'total': 50.0
    },
    {
      'subject': 'English',
      'assessmentName': 'Essay — Nature',
      'score': 44.0,
      'total': 50.0
    },
    {
      'subject': 'English',
      'assessmentName': 'Grammar Test',
      'score': 36.0,
      'total': 40.0
    },
  ];

  final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Parent-Teacher Meeting — Dec 5',
      'body':
          'PTM scheduled from 10 AM – 1 PM. Please confirm your slot through the app.',
      'by': 'Principal'
    },
    {
      'title': 'Holiday Homework Uploaded',
      'body':
          'Winter break assignments are now live. Please ensure Arjun completes them before Jan 6.',
      'by': 'Mrs. Priya Sharma'
    },
    {
      'title': 'Sports Day — Dec 15',
      'body':
          'Annual Sports Day. Students must wear sports uniform. Water bottles are mandatory.',
      'by': 'School Admin'
    },
  ];

  final Map<String, dynamic> _vote = {
    'question':
        'Should we cancel school tomorrow due to heavy rainfall forecast?',
    'type': 'Weather Day',
    'votes': {'school': 15, 'no_school': 6, 'undecided': 2},
    'myVote': null,
  };

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
    await Future.delayed(const Duration(milliseconds: 800));
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

  void _castVote(String option) {
    if (_vote['myVote'] != null) return;
    setState(() {
      _vote['votes'][option] = (_vote['votes'][option] as int) + 1;
      _vote['myVote'] = option;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Vote submitted! ✅',
          style: TextStyle(fontFamily: 'Raleway')),
      backgroundColor: success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── TEACHER PROFILE SHEET ──────────────────────────────────────────────────
  void _showTeacherProfile() {
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
              child: Text(teacherName[0],
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary))),
          const SizedBox(height: 14),
          Text(teacherName,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          Text('$subject Teacher · $className',
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
                    Text(teacherEmail,
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
                    Text(classCode,
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
                            otherUserId: 'teacher1',
                            otherUserName: teacherName,
                            otherUserRole: 'Teacher',
                            otherUserEmail: teacherEmail,
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

  // ─── HOME ──────────────────────────────────────────────────────────────────
  Widget _homeTab() {
    double total = _grades.fold(0.0,
        (s, g) => s + (g['score'] as double) / (g['total'] as double) * 100);
    final avg = total / _grades.length;
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
            const SizedBox(height: 20),
            // Class card with tappable teacher name
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
                        Text("$childName's Class",
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
                              Text(className,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: textDark)),
                              const SizedBox(height: 4),
                              // Tappable teacher name
                              GestureDetector(
                                onTap: _showTeacherProfile,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('$subject · ',
                                          style: const TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 12,
                                              color: textLight)),
                                      Text(teacherName,
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
                            child: Text(classCode,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                    letterSpacing: 2))),
                      ]),
                    ])),
            const SizedBox(height: 16),
            // Quick actions
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
                      () => _switchTab(2)),
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
                              child: Text(e.value['title'],
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
                        Text(e.value['body'],
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: textMid,
                                height: 1.55)),
                        const SizedBox(height: 4),
                        Text('By ${e.value['by']}',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 10,
                                color: textLight)),
                      ]),
                )),
            const SizedBox(height: 24),
          ]),
        ));
  }

  Widget _greetingCard(double avg) {
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
                                text: userName,
                                delayMs: 400,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 4),
                            Text('Parent of $childName',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'parent_avatar',
                          initial: userName[0],
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
                      _miniStat('${_grades.length}', 'Tests', Colors.white),
                      const SizedBox(width: 20),
                      _miniStat('3', 'Subjects', Colors.white),
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
    final bySubject = <String, List<Map<String, dynamic>>>{};
    for (final g in _grades)
      bySubject.putIfAbsent(g['subject'], () => []).add(g);
    double total = _grades.fold(0.0,
        (s, g) => s + (g['score'] as double) / (g['total'] as double) * 100);
    final overallAvg = total / _grades.length;
    final colors = [info, success, accent, purple, danger];

    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: Text("$childName's Progress",
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
            double subAvg = subGrades.fold(
                    0.0,
                    (s, g) =>
                        s +
                        (g['score'] as double) / (g['total'] as double) * 100) /
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
                      final pct =
                          (g['score'] as double) / (g['total'] as double);
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
                                child: Text(g['assessmentName'],
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
                                    '${(g['score'] as double).toInt()}/${(g['total'] as double).toInt()}',
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

  // ─── VOTE ──────────────────────────────────────────────────────────────────
  Widget _voteTab() {
    final votes = _vote['votes'] as Map<String, dynamic>;
    final total = (votes['school'] as int) +
        (votes['no_school'] as int) +
        (votes['undecided'] as int);
    final myVote = _vote['myVote'] as String?;

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
          FadeSlideIn(
              delayMs: 80,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: info.withOpacity(0.2), width: 1.5)),
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
                            child: Text(_vote['type'],
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
                      Text(_vote['question'],
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              height: 1.4)),
                      const SizedBox(height: 20),
                      if (myVote == null)
                        ...[
                          'school',
                          'no_school',
                          'undecided'
                        ].map((opt) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GestureDetector(
                                onTap: () => _castVote(opt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  decoration: BoxDecoration(
                                      color: info.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: info.withOpacity(0.2))),
                                  child: Row(children: [
                                    Icon(
                                        opt == 'school'
                                            ? Icons.school_outlined
                                            : opt == 'no_school'
                                                ? Icons.home_outlined
                                                : Icons.help_outline_rounded,
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
                          '🏫 School': votes['school'] as int,
                          '🏠 No School': votes['no_school'] as int,
                          '🤷 Undecided': votes['undecided'] as int,
                        }.entries.map((e) {
                          final pct = total > 0 ? e.value / total : 0.0;
                          final c =
                              e.key.contains('School') && !e.key.contains('No')
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
                                Text('${(pct * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        color: c,
                                        fontWeight: FontWeight.bold)),
                              ]));
                        }),
                      if (myVote != null)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: success.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
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
              )),
        ]));
  }

  // ─── PROFILE ───────────────────────────────────────────────────────────────
  Widget _profileTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          FadeSlideIn(
              child: HeroAvatar(
                  heroTag: 'parent_avatar',
                  initial: userName[0],
                  radius: 46,
                  bgColor: purple.withOpacity(0.1),
                  textColor: purple,
                  borderColor: accent)),
          const SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 80,
              child: Text(userName,
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.5))),
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 100,
              child: Text(userEmail,
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
          // Teacher contact card
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
                        child: Text(teacherName[0],
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
                          Text(teacherName,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textDark)),
                          Text("$childName's Teacher · $subject",
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  color: textLight)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.email_outlined,
                                size: 11, color: info),
                            const SizedBox(width: 4),
                            Text(teacherEmail,
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
              [Icons.child_care_outlined, 'Child', childName],
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.class_outlined, 'Class', className],
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
        ]));
  }

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
