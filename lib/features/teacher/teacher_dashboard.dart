import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../messaging/messaging_screen.dart';
import '../../shared/animations/animations.dart';
import '../auth/welcome_screen.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/add_student_sheet.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../shared/widgets/pick_student_sheet.dart';
import '../../core/router/app_router.dart';
import '../../services/class_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../repositories/auth_repository.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../models/grade_model.dart';
import '../../models/announcement_model.dart';
import '../../models/homework_model.dart';
import '../../models/behavior_point.dart';
import '../../models/behavior_category.dart';
import '../../models/attendance_record.dart';
import '../../models/attendance_status.dart';
import '../../models/story_post.dart';
import '../../models/activity_event.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
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
  List<ClassModel> _classes = [];
  List<UserModel> _students = [];
  List<UserModel> _parents = [];
  List<GradeModel> _grades = [];
  List<AnnouncementModel> _announcements = [];
  List<HomeworkModel> _homework = [];
  List<BehaviorPoint> _classBehavior = [];
  List<AttendanceRecord> _todayAttendance = [];
  List<StoryPost> _classStory = [];
  List<ActivityEvent> _activityFeed = [];

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

  // ── ANIMATIONS ─────────────────────────────────────────────────────────────
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
      _uid = AuthRepository().currentUid ?? 'teacher_priya';
      final data = await _dashSvc.loadTeacherDashboard(overrideUid: _uid, forceRefresh: true);
      _user = data.user;
      _classes = data.classes;
      _students = data.studentsInFirstClass;
      _parents = data.parentsInFirstClass;
      _grades = data.gradesInFirstClass;
      _announcements = data.announcements;
      _homework = data.homework;
      _classBehavior = data.classBehavior;
      _todayAttendance = data.todayAttendance;
      _classStory = data.classStory;
      _activityFeed = data.activityFeed;
    } catch (e) {
      debugPrint('TeacherDashboard._loadData error: $e');
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

  void _switchTab(int index) {
    if (index == _currentTab) return;
    HapticFeedback.selectionClick();
    _tabController.reset();
    setState(() => _currentTab = index);
    _tabController.forward();
  }

  void _logout() {
    LogoutSheet.show(context, onConfirm: () {
      AppRouter.toWelcomeAndClearStack(context);
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Raleway')),
        backgroundColor: primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

  void _showAddStudentOptions(String classId, List<String> existingStudentUids) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_add_outlined,
                    color: info, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Add Student to Class',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textDark)),
            ]),
            const SizedBox(height: 20),
            _addStudentOption(
              icon: Icons.person_search_outlined,
              color: info,
              title: 'Pick Existing Student',
              subtitle: 'Choose from students already enrolled in school',
              onTap: () {
                Navigator.pop(context);
                PickStudentSheet.show(context,
                    classId: classId,
                    excludeStudentIds: existingStudentUids,
                    onStudentAdded: () => _snack('Student added to class'));
              },
            ),
            const SizedBox(height: 10),
            _addStudentOption(
              icon: Icons.person_add_alt_1_outlined,
              color: primary,
              title: 'Create New Student',
              subtitle: 'Enroll a new student and add to this class',
              onTap: () {
                Navigator.pop(context);
                AddStudentSheet.show(context,
                    classId: classId,
                    onStudentAdded: () => _snack('Student created and added'));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateClass() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            bool isCreating = false;
            return Container(
              decoration: const BoxDecoration(
                color: TatvaColors.bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.class_outlined,
                          color: primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Create New Class',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('A unique class code will be generated',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: textLight)),
                  const SizedBox(height: 20),
                  const Text('Class Name',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grade 8 — Section A',
                      hintStyle: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: primary.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Subject',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: subjectCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'e.g. Mathematics',
                      hintStyle: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: primary.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  BouncyTap(
                    onTap: isCreating
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty ||
                                subjectCtrl.text.trim().isEmpty) {
                              return;
                            }
                            setModalState(() => isCreating = true);
                            final code = String.fromCharCodes(
                              List.generate(6, (_) => Random().nextInt(26) + 65),
                            );
                            final name = nameCtrl.text.trim();
                            final result = await ClassService().createClass(
                              name: name,
                              subject: subjectCtrl.text.trim(),
                              classCode: code,
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (result != null) {
                              _snack('Class "$name" created! Code: $code');
                            } else {
                              _snack('Failed to create class. Try again.');
                            }
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
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Center(
                        child: isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Create Class',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _addStudentOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: textLight)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 22),
        ]),
      ),
    );
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
            _buildHomeTab(),
            _buildClassesTab(),
            _buildBehaviorTab(),
            _buildAttendanceTab(),
            _buildGradesTab(),
            _buildHomeworkTab(),
            _buildStoryTab(),
            _buildMessagesTab(),
            _buildProfileTab(),
          ])));

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'active': Icons.dashboard_rounded,
        'label': 'Home'
      },
      {
        'icon': Icons.class_outlined,
        'active': Icons.class_rounded,
        'label': 'Classes'
      },
      {
        'icon': Icons.emoji_events_outlined,
        'active': Icons.emoji_events_rounded,
        'label': 'Behavior'
      },
      {
        'icon': Icons.fact_check_outlined,
        'active': Icons.fact_check_rounded,
        'label': 'Attend'
      },
      {
        'icon': Icons.grade_outlined,
        'active': Icons.grade_rounded,
        'label': 'Grades'
      },
      {
        'icon': Icons.assignment_outlined,
        'active': Icons.assignment_rounded,
        'label': 'Homework'
      },
      {
        'icon': Icons.auto_stories_outlined,
        'active': Icons.auto_stories_rounded,
        'label': 'Story'
      },
      {
        'icon': Icons.chat_outlined,
        'active': Icons.chat_rounded,
        'label': 'Messages'
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
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
            child: Row(
                children: List.generate(items.length, (i) {
              final isActive = _currentTab == i;
              return Expanded(
                  child: GestureDetector(
                      onTap: () => _switchTab(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                            color: isActive
                                ? primary.withOpacity(0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                  isActive
                                      ? items[i]['active'] as IconData
                                      : items[i]['icon'] as IconData,
                                  key: ValueKey(isActive),
                                  color: isActive ? primary : textLight,
                                  size: 20)),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 9,
                                  color: isActive ? primary : textLight,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500),
                              child: Text(items[i]['label'] as String)),
                        ]),
                      )));
            })),
          )),
    );
  }

  // ─── HOME TAB ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    final totalStudents =
        _classes.fold(0, (sum, c) => sum + c.studentUids.length);
    final activeHw = _homework.length;
    return RefreshIndicator(
      color: primary,
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
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _statCard('${_classes.length}', 'Classes', Icons.class_outlined,
                    primary),
                const SizedBox(width: 10),
                _statCard(
                    '$totalStudents', 'Students', Icons.people_outline, info),
                const SizedBox(width: 10),
                _statCard(
                    '$activeHw', 'Homework', Icons.assignment_outlined, accent),
              ])),
          const SizedBox(height: 24),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Quick Actions',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark))),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                _qaBtn('Enter\nGrades', Icons.edit_note_outlined, accent,
                    () => _switchTab(4)),
                const SizedBox(width: 8),
                _qaBtn('Post\nHomework', Icons.assignment_outlined, primary,
                    () => _switchTab(5)),
                const SizedBox(width: 8),
                _qaBtn('Behavior', Icons.emoji_events_outlined, info,
                    () => _switchTab(2)),
                const SizedBox(width: 8),
                _qaBtn('Messages', Icons.chat_outlined, purple,
                    () => _switchTab(7)),
              ])),
          if (_activityFeed.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('Recent Activity',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark))),
            const SizedBox(height: 12),
            ..._activityFeed.take(5).map((event) {
              final icon = switch (event.type.name) {
                'behaviorPoint' => Icons.star,
                'attendance' => Icons.check_circle,
                'homeworkAssigned' => Icons.assignment,
                'gradeEntered' => Icons.grade,
                'announcement' => Icons.campaign,
                'storyPost' => Icons.photo_camera,
                _ => Icons.circle,
              };
              final ago = event.createdAt != null
                  ? _timeAgo(event.createdAt!)
                  : '';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: textDark)),
                          if (event.body.isNotEmpty)
                            Text(event.body,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                        ],
                      ),
                    ),
                    if (ago.isNotEmpty)
                      Text(ago,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: textLight)),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 28),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('My Classes',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark))),
          const SizedBox(height: 12),
          ..._classes.asMap().entries.map((e) => _classCard(e.value, e.key)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: const [
          Color(0xFF1E5C3A),
          Color(0xFF2E6B4F),
          Color(0xFF3D8B6B)
        ],
        boxShadow: [
          BoxShadow(
              color: primary.withOpacity(0.35),
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
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500))
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
                            const SizedBox(height: 4),
                            Text('Tatva Academy · Teacher',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'teacher_avatar',
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
                          const Text('Inspiring minds every day! ✨',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500))
                        ])),
                  ])),
        ]),
      ),
    );
  }

  // ─── CLASSES TAB ───────────────────────────────────────────────────────────
  Widget _buildClassesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('My Classes',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        const SizedBox(height: 4),
        FadeSlideIn(
            delayMs: 60,
            child: const Text('Manage your classes and students',
                style: TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        FadeSlideIn(
            delayMs: 80,
            child: GestureDetector(
              onTap: _showCreateClass,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: primary.withOpacity(0.2), width: 1.5)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('Create New Class',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primary)),
                      ])),
            )),
        const SizedBox(height: 16),
        ..._classes.asMap().entries.map((e) => _classCard(e.value, e.key)),
      ]),
    );
  }

  Widget _classCard(ClassModel c, int index) {
    final studentCount = c.studentUids.length;
    final parentCount = c.parentUids.length;
    return StaggeredItem(
        index: index,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
              color: bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    primary.withOpacity(0.12),
                    primary.withOpacity(0.04)
                  ]),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(c.name,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                      Text(c.subject,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: textLight)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent.withOpacity(0.3))),
                    child: Text(c.classCode,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            letterSpacing: 2))),
              ]),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Icon(Icons.people_outline, color: textLight, size: 16),
                  const SizedBox(width: 4),
                  Text('$studentCount students',
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: textLight)),
                  const SizedBox(width: 12),
                  Icon(Icons.family_restroom_outlined,
                      color: textLight, size: 16),
                  const SizedBox(width: 4),
                  Text('$parentCount parents',
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: textLight)),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => _showAddStudentOptions(c.id, c.studentUids),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: info.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: info.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.person_add_outlined, color: info, size: 14),
                            const SizedBox(width: 4),
                            const Text('Add Student',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: info,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => _switchTab(4),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: primary.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.edit_outlined, color: primary, size: 14),
                            const SizedBox(width: 4),
                            const Text('Grades',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: primary,
                                    fontWeight: FontWeight.w600))
                          ]))),
                ])),
          ]),
        ));
  }

  // ─── BEHAVIOR TAB ──────────────────────────────────────────────────────────
  Widget _buildBehaviorTab() {
    final classId = _classes.isNotEmpty ? _classes.first.id : '';
    final studentScores = <String, int>{};
    for (final bp in _classBehavior) {
      studentScores.update(bp.studentUid, (v) => v + bp.points,
          ifAbsent: () => bp.points);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Behavior Points',
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
                _classes.isNotEmpty
                    ? '${_classes.first.name} · Tap a student to award points'
                    : 'No classes available',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5),
          itemCount: _students.length,
          itemBuilder: (_, i) {
            final s = _students[i];
            final score = studentScores[s.uid] ?? 0;
            final scoreColor = score > 0
                ? success
                : score < 0
                    ? danger
                    : textLight;
            return GestureDetector(
              onTap: () => _showBehaviorSheet(s.uid, s.name, classId),
              child: Container(
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 22,
                          backgroundColor: primary.withOpacity(0.1),
                          child: Text(s.initial,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: primary))),
                      const SizedBox(height: 8),
                      Text(s.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textDark)),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              '${score >= 0 ? '+' : ''}$score pts',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor))),
                    ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  void _showBehaviorSheet(String studentUid, String studentName, String classId) {
    final categories = BehaviorCategory.defaults;
    final positive = categories.where((c) => c.isPositive).toList();
    final negative = categories.where((c) => !c.isPositive).toList();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: TatvaColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(studentName,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          const Text('Select a behavior category',
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 13, color: textLight)),
          const SizedBox(height: 16),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Positive',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: positive
                .map((cat) => _behaviorChip(cat, true, studentUid,
                    studentName, classId))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Align(
              alignment: Alignment.centerLeft,
              child: Text('Needs Work',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: negative
                .map((cat) => _behaviorChip(cat, false, studentUid,
                    studentName, classId))
                .toList(),
          ),
        ]),
      ),
    );
  }

  Widget _behaviorChip(BehaviorCategory cat, bool isPositive,
      String studentUid, String studentName, String classId) {
    final chipColor = isPositive ? success : danger;
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        _api.awardBehaviorPoint(
          studentUid: studentUid,
          classId: classId,
          categoryId: cat.id,
          studentName: studentName,
          points: isPositive ? 1 : -1,
        );
        setState(() => _classBehavior.add(BehaviorPoint(
          studentUid: studentUid,
          studentName: studentName,
          classId: classId,
          categoryId: cat.id,
          points: isPositive ? 1 : -1,
          awardedBy: _uid,
          awardedByName: _user?.name ?? '',
          createdAt: DateTime.now(),
        )));
        _snack('${isPositive ? '+1' : '-1'} ${cat.name} for $studentName');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: chipColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: chipColor.withOpacity(0.25))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(cat.icon, size: 16, color: chipColor),
          const SizedBox(width: 6),
          Text(cat.name,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: chipColor)),
        ]),
      ),
    );
  }

  // ─── ATTENDANCE TAB ───────────────────────────────────────────────────────
  Widget _buildAttendanceTab() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final displayDate =
        '${_monthName(now.month)} ${now.day}, ${now.year}';
    final classId = _classes.isNotEmpty ? _classes.first.id : '';

    final preMarked = <String, AttendanceStatus>{};
    for (final r in _todayAttendance) {
      preMarked[r.studentUid] = r.status;
    }

    return StatefulBuilder(builder: (ctx, setLocal) {
      final statuses = <String, AttendanceStatus>{};
      for (final s in _students) {
        statuses[s.uid] = preMarked[s.uid] ?? AttendanceStatus.present;
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Attendance',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 60,
              child: Text(displayDate,
                  style: const TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 20),
          if (_todayAttendance.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: success.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: success.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.check_circle_outline, color: success, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Attendance already marked today. You can update it.',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textMid))),
              ]),
            ),
          ..._students.asMap().entries.map((e) {
            final s = e.value;
            final current = statuses[s.uid] ?? AttendanceStatus.present;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100)),
              child: Row(children: [
                CircleAvatar(
                    radius: 18,
                    backgroundColor: primary.withOpacity(0.1),
                    child: Text(s.initial,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: primary))),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(s.name,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark))),
                ...AttendanceStatus.values.map((st) => Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: GestureDetector(
                        onTap: () {
                          setLocal(() {
                            preMarked[s.uid] = st;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: current == st
                                  ? _attendanceColor(st).withOpacity(0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: current == st
                                      ? _attendanceColor(st)
                                      : Colors.grey.shade200)),
                          child: Text(st.label,
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  fontWeight: current == st
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: current == st
                                      ? _attendanceColor(st)
                                      : textLight)),
                        ),
                      ),
                    )),
              ]),
            );
          }),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final finalStatuses = <String, AttendanceStatus>{};
              final names = <String, String>{};
              for (final s in _students) {
                finalStatuses[s.uid] =
                    preMarked[s.uid] ?? AttendanceStatus.present;
                names[s.uid] = s.name;
              }
              final records = finalStatuses.entries.map((e) => {
                'studentUid': e.key,
                'studentName': names[e.key] ?? '',
                'classId': classId,
                'date': dateStr,
                'status': e.value.label,
              }).toList();
              _api.markAttendanceBatch(records);
              setState(() {
                _todayAttendance = finalStatuses.entries.map((e) =>
                  AttendanceRecord(
                    studentUid: e.key,
                    studentName: names[e.key] ?? '',
                    classId: classId,
                    date: dateStr,
                    status: e.value,
                    markedBy: _uid,
                    createdAt: DateTime.now(),
                  )).toList();
              });
              _snack('Attendance saved for $displayDate');
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
              child: const Center(
                  child: Text('Save Attendance',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      );
    });
  }

  Color _attendanceColor(AttendanceStatus st) {
    switch (st) {
      case AttendanceStatus.present:
        return success;
      case AttendanceStatus.absent:
        return danger;
      case AttendanceStatus.tardy:
        return accent;
    }
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }

  // ─── GRADES TAB ────────────────────────────────────────────────────────────
  Widget _buildGradesTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Grade Book',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Grade 8-A · Unit Test 3 · Mathematics',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 20),
          Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withOpacity(0.2))),
              child: Row(children: [
                Icon(Icons.info_outline_rounded, color: accent, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Tap any student to enter or edit their grade',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textMid)))
              ])),
          ..._grades.asMap().entries.map((e) {
            final g = e.value;
            final pct = g.total > 0 ? g.score / g.total : 0.0;
            final c = pct >= 0.9
                ? success
                : pct >= 0.7
                    ? accent
                    : danger;
            return StaggeredItem(
                index: e.key,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 18,
                        backgroundColor: primary.withOpacity(0.1),
                        child: Text(g.studentName.isNotEmpty ? g.studentName[0] : '?',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primary))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(g.studentName,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark)),
                          Text(g.assessmentName,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  color: textLight)),
                        ])),
                    GestureDetector(
                        onTap: () =>
                            _snack('Edit grade — available in the live app!'),
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${g.score.toInt()}/${g.total.toInt()}',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: c)))),
                  ]),
                ));
          }),
        ]));
  }

  // ─── HOMEWORK TAB ──────────────────────────────────────────────────────────
  Widget _buildHomeworkTab() {
    final active = _homework;
    final done = <HomeworkModel>[];
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
            child: Text('${active.length} active · ${done.length} completed',
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textLight))),
        const SizedBox(height: 16),
        // Post button
        FadeSlideIn(
            delayMs: 80,
            child: GestureDetector(
              onTap: _showPostHomeworkSheet,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: accent.withOpacity(0.25), width: 1.5)),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: accent, size: 20),
                        const SizedBox(width: 8),
                        const Text('Post New Homework',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: accent)),
                      ])),
            )),
        if (active.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Active',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark)),
          const SizedBox(height: 12),
          ...active.asMap().entries.map((e) => _hwCard(e.value, e.key)),
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Completed',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textLight)),
          const SizedBox(height: 12),
          ...done.asMap().entries.map((e) => _hwCard(e.value, e.key)),
        ],
        const SizedBox(height: 28),
      ]),
    );
  }

  Widget _hwCard(HomeworkModel hw, int idx) {
    final subs = hw.submissionCount;
    final total = _students.length;
    final pct = total > 0 ? subs / total : 0.0;
    final isDone = false;
    final color = isDone ? success : accent;
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
                          ? Icons.check_circle_outline_rounded
                          : Icons.assignment_outlined,
                      color: color,
                      size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(hw.title,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    Text(hw.className,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: textLight)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.25))),
                  child: Text('0 marks',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color))),
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
                const Spacer(),
                Text('$subs/$total submitted',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ]),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: Duration(milliseconds: 600 + idx * 80),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showPostHomeworkSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final marksCtrl = TextEditingController(text: '10');
    String selectedClassId = _classes[0].id;
    String selectedClassName = _classes[0].name;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 3,
                          decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text('Post Homework',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 20),
                  // Class picker
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClassId,
                        isExpanded: true,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textDark),
                        items: _classes
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text(c.name,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 14,
                                          color: textDark)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setModal(() {
                            selectedClassId = v;
                            selectedClassName = _classes.firstWhere(
                                (c) => c.id == v).name;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'Assignment title',
                      hintStyle: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: accent.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      hintText: 'Instructions for students...',
                      hintStyle: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: Colors.grey.shade400),
                      filled: true,
                      fillColor: bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: accent.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: marksCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: InputDecoration(
                      labelText: 'Total Marks',
                      labelStyle: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 13,
                          color: textLight),
                      prefixIcon: const Icon(Icons.star_outline_rounded,
                          size: 18, color: textLight),
                      filled: true,
                      fillColor: bg,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: accent.withOpacity(0.5), width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final hw = HomeworkModel(
                        id: '',
                        title: title,
                        description: descCtrl.text.trim().isEmpty
                            ? 'No additional instructions.'
                            : descCtrl.text.trim(),
                        subject: 'Mathematics',
                        classId: selectedClassId,
                        className: selectedClassName,
                        teacherUid: _uid,
                        teacherName: _user?.name ?? '',
                        dueDate: 'Dec 20, 2024',
                      );
                      await _api.createHomework(
                        title: hw.title,
                        classId: hw.classId,
                        description: hw.description,
                        subject: hw.subject,
                        className: hw.className,
                        dueDate: hw.dueDate,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() => _homework.insert(0, hw));
                      _snack('Homework posted to $selectedClassName!');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: accent.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4))
                          ]),
                      child: const Center(
                          child: Text('Post Homework',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                    ),
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  // ─── STORY TAB ─────────────────────────────────────────────────────────────
  Widget _buildStoryTab() {
    return Stack(children: [
      SingleChildScrollView(
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
                child: Text(
                    _classes.isNotEmpty
                        ? '${_classes.first.name} · ${_classStory.length} posts'
                        : 'No class story yet',
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 13, color: textLight))),
            const SizedBox(height: 16),
            if (_classStory.isEmpty)
              Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                      child: Column(children: [
                    Icon(Icons.auto_stories_outlined,
                        color: textLight, size: 48),
                    const SizedBox(height: 12),
                    const Text('No stories yet',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textLight)),
                    const SizedBox(height: 4),
                    const Text('Tap + to share the first class moment',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textLight)),
                  ]))),
            ..._classStory.asMap().entries.map((e) {
              final post = e.value;
              final liked = post.isLikedBy(_uid);
              final timeAgo = post.createdAt != null
                  ? _timeAgo(post.createdAt!)
                  : '';
              return StaggeredItem(
                  index: e.key,
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
                                backgroundColor: primary.withOpacity(0.1),
                                child: Text(
                                    post.authorName.isNotEmpty
                                        ? post.authorName[0]
                                        : '?',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: primary))),
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
                                          fontWeight: FontWeight.bold,
                                          color: textDark)),
                                  if (post.authorRole.isNotEmpty)
                                    Text(post.authorRole,
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
                          const SizedBox(height: 12),
                          Text(post.text,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: textMid,
                                  height: 1.5)),
                          const SizedBox(height: 12),
                          Row(children: [
                            GestureDetector(
                              onTap: () async {
                                _api.toggleStoryLike(post.id);
                                final i = _classStory.indexWhere((s) => s.id == post.id);
                                if (i == -1) return;
                                final p = _classStory[i];
                                final updatedLikes = List<String>.from(p.likedBy);
                                p.isLikedBy(_uid) ? updatedLikes.remove(_uid) : updatedLikes.add(_uid);
                                setState(() => _classStory[i] = StoryPost(
                                  id: p.id,
                                  authorUid: p.authorUid,
                                  authorName: p.authorName,
                                  authorRole: p.authorRole,
                                  classId: p.classId,
                                  className: p.className,
                                  text: p.text,
                                  mediaUrls: p.mediaUrls,
                                  mediaType: p.mediaType,
                                  likedBy: updatedLikes,
                                  commentCount: p.commentCount,
                                  createdAt: p.createdAt,
                                ));
                              },
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                        liked
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 18,
                                        color: liked ? danger : textLight),
                                    const SizedBox(width: 4),
                                    Text('${post.likeCount}',
                                        style: TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 12,
                                            color: liked ? danger : textLight,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.comment_outlined,
                                size: 16, color: textLight),
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
            const SizedBox(height: 80),
          ])),
      Positioned(
        right: 20,
        bottom: 20,
        child: GestureDetector(
          onTap: _showNewStorySheet,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ]),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    ]);
  }

  void _showNewStorySheet() {
    final textCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 3,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                const Text('New Story Post',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
                const SizedBox(height: 16),
                TextField(
                  controller: textCtrl,
                  maxLines: 4,
                  autofocus: true,
                  style: const TextStyle(
                      fontFamily: 'Raleway', fontSize: 14, color: textDark),
                  decoration: InputDecoration(
                    hintText: 'Share a class moment...',
                    hintStyle: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: bg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: primary.withOpacity(0.5), width: 1.5)),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final text = textCtrl.text.trim();
                    if (text.isEmpty) return;
                    final classId =
                        _classes.isNotEmpty ? _classes.first.id : '';
                    final className =
                        _classes.isNotEmpty ? _classes.first.name : '';
                    final newPost = StoryPost(
                      authorUid: _uid,
                      authorName: _user?.name ?? '',
                      authorRole: 'Teacher',
                      classId: classId,
                      className: className,
                      text: text,
                      createdAt: DateTime.now(),
                    );
                    _api.createStoryPost(
                      classId: newPost.classId,
                      text: newPost.text,
                      className: newPost.className,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    setState(() => _classStory.insert(0, newPost));
                    _snack('Story posted!');
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
                    child: const Center(
                        child: Text('Post',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  // ─── MESSAGES TAB ──────────────────────────────────────────────────────────
  Widget _buildMessagesTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Messages',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Communicate with parents',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 20),
          ..._parents.asMap().entries.map((e) {
            final p = e.value;
            return StaggeredItem(
                index: e.key,
                child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MessagingScreen(
                                    otherUserId: p.uid,
                                    otherUserName: p.name,
                                    otherUserRole: 'Parent · ${p.children.isNotEmpty ? p.children.first.childName : ''}',
                                    otherUserEmail: p.email,
                                    avatarColor: primary,
                                  ))),
                      child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100)),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 22,
                                backgroundColor: primary.withOpacity(0.1),
                                child: Text(p.initial,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: primary))),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textDark)),
                                  Text('Parent of ${p.children.isNotEmpty ? p.children.first.childName : ''}',
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 12,
                                          color: textLight)),
                                ])),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: primary.withOpacity(0.15))),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_outlined,
                                          color: primary, size: 13),
                                      const SizedBox(width: 4),
                                      const Text('Message',
                                          style: TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 11,
                                              color: primary,
                                              fontWeight: FontWeight.w600))
                                    ])),
                          ])),
                    )));
          }),
        ]));
  }

  // ─── PROFILE TAB ───────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          FadeSlideIn(
              child: HeroAvatar(
                  heroTag: 'teacher_avatar',
                  initial: _user?.initial ?? '?',
                  radius: 46,
                  bgColor: primary.withOpacity(0.1),
                  textColor: primary,
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
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Teacher',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w700)))),
          const SizedBox(height: 28),
          ...List.generate(4, (i) {
            final items = [
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.book_outlined, 'Subject', 'Mathematics'],
              [Icons.class_outlined, 'Classes', '${_classes.length} Active'],
              [Icons.verified_outlined, 'Status', 'Verified'],
            ];
            return StaggeredItem(
                index: i,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: RippleTap(
                      rippleColor: primary,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100)),
                        child: Row(children: [
                          Icon(items[i][0] as IconData,
                              color: primary, size: 18),
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
        ]));
  }

  Widget _statCard(String value, String label, IconData icon, Color color) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.5)),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  color: textLight,
                  fontWeight: FontWeight.w500)),
        ]),
      ));

  Widget _qaBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
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
                ]),
              )));
}
