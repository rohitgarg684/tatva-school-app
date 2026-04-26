import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../models/schedule_model.dart';
import '../../models/schedule_event.dart';
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
  List<GradeModel> _allGrades = [];
  List<Map<String, dynamic>> _testTitles = [];
  List<AnnouncementModel> _announcements = [];
  List<HomeworkModel> _homework = [];
  List<BehaviorPoint> _classBehavior = [];
  List<AttendanceRecord> _todayAttendance = [];
  List<StoryPost> _classStory = [];
  List<ActivityEvent> _activityFeed = [];
  List<UserModel> _allSchoolStudents = [];
  String _attSearchQuery = '';

  // ── SCHEDULE STATE
  List<ScheduleModel> _tSchedData = [];
  bool _tSchedLoading = false;
  bool _tSchedLoaded = false;
  int _tSchedDay = 0;
  String _tSchedSelectedGS = '';
  String _storySelectedClassId = '';

  // ── MY WEEK CALENDAR STATE
  int _schedViewMode = 0; // 0=My Week, 1=Edit Timetable
  List<Map<String, dynamic>> _calPeriods = [];
  List<Map<String, dynamic>> _calEvents = [];
  List<Map<String, dynamic>> _calCancellations = [];
  bool _calLoading = false;
  bool _calLoaded = false;
  DateTime _calWeekStart = DateTime.now();

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
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadTeacherDashboard(overrideUid: _uid, forceRefresh: true);
      _user = data.user;
      _classes = data.classes;
      _students = data.studentsInFirstClass;
      _parents = data.parentsInFirstClass;
      _grades = data.gradesInFirstClass;
      _allGrades = data.allTeacherGrades;
      _testTitles = data.testTitles;
      _announcements = data.announcements;
      _homework = data.homework;
      _classBehavior = data.classBehavior;
      _todayAttendance = data.todayAttendance;
      _classStory = data.classStory;
      _activityFeed = data.activityFeed;
      _allSchoolStudents = data.allStudents;
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

  void _showClassStudents(ClassModel cls) {
    HapticFeedback.lightImpact();
    final classStudents = _students.where((s) => cls.studentUids.contains(s.uid)).toList()
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
              width: 36, height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cls.name,
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  Text('${cls.subject} · ${classStudents.length} students',
                      style: const TextStyle(
                          fontFamily: 'Raleway', fontSize: 12, color: textLight)),
                ]),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showAddStudentOptions(cls.id, cls.studentUids);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: info.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: info.withOpacity(0.2))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_outlined, color: info, size: 16),
                    const SizedBox(width: 4),
                    const Text('Add',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: info)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (classStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline, color: textLight, size: 40),
                const SizedBox(height: 8),
                const Text('No students in this class yet',
                    style: TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textLight)),
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
                      ? s.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
                      : '?';
                  final colors = [primary, info, accent, purple, success];
                  final c = colors[i % colors.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: c)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textDark)),
                          Text(s.email,
                              style: const TextStyle(
                                  fontFamily: 'Raleway', fontSize: 11, color: textLight)),
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

  void _confirmDeleteClass(ClassModel cls) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Class',
            style: TextStyle(
                fontFamily: 'Raleway', fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${cls.name}"?\n\n'
            'This will remove ${cls.studentUids.length} student(s) and '
            '${cls.parentUids.length} parent(s) from this class. '
            'This action cannot be undone.',
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Raleway', color: textLight)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteClass(cls.id);
                _snack('"${cls.name}" deleted');
                _loadUser();
              } catch (e) {
                _snack('Failed to delete class');
                debugPrint('Delete class error: $e');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    color: danger,
                    fontWeight: FontWeight.bold)),
          ),
        ],
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
            _buildScheduleTab(),
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
        'icon': Icons.calendar_view_week_outlined,
        'active': Icons.calendar_view_week_rounded,
        'label': 'Schedule'
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
                    () => _switchTab(5)),
                const SizedBox(width: 8),
                _qaBtn('Post\nHomework', Icons.assignment_outlined, primary,
                    () => _switchTab(6)),
                const SizedBox(width: 8),
                _qaBtn('Behavior', Icons.emoji_events_outlined, info,
                    () => _switchTab(2)),
                const SizedBox(width: 8),
                _qaBtn('Messages', Icons.chat_outlined, purple,
                    () => _switchTab(8)),
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
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => _showClassStudents(c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: info.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: info.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.people_outline, color: info, size: 14),
                            const SizedBox(width: 4),
                            Text('${c.studentUids.length} Students',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: info,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => _switchTab(5),
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
                  const Spacer(),
                  GestureDetector(
                      onTap: () => _confirmDeleteClass(c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: danger.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: danger.withOpacity(0.2))),
                          child: Icon(Icons.delete_outline_rounded,
                              color: danger, size: 16))),
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
    final recentPoints = List<BehaviorPoint>.from(_classBehavior)
      ..sort((a, b) => (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000)));

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
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85),
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          radius: 20,
                          backgroundColor: primary.withOpacity(0.1),
                          child: Text(s.initial,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: primary))),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(s.name,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textDark)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: scoreColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              '${score >= 0 ? '+' : ''}$score pts',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor))),
                    ]),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        if (recentPoints.isNotEmpty) ...[
          const Text('Recent Activity',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 12),
          ...recentPoints.take(20).map((bp) {
            final cat = BehaviorCategory.fromId(bp.categoryId);
            final c = bp.isPositive ? success : danger;
            final timeAgo = bp.createdAt != null
                ? _behaviorTimeAgo(bp.createdAt!)
                : '';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.withOpacity(0.15))),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(cat.icon, color: c, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(bp.studentName,
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: c.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text(
                                '${bp.isPositive ? '+' : ''}${bp.points}',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: c)),
                          ),
                        ]),
                        Text(cat.name,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 11,
                                color: textLight)),
                        if (bp.note.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(bp.note,
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: textMid)),
                          ),
                      ]),
                ),
                if (timeAgo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(timeAgo,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: textLight)),
                  ),
                GestureDetector(
                  onTap: () => _deleteBehaviorPoint(bp),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: danger.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(6)),
                    child: Icon(Icons.delete_outline_rounded,
                        color: danger.withOpacity(0.5), size: 16),
                  ),
                ),
              ]),
            );
          }),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }

  String _behaviorTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }

  void _deleteBehaviorPoint(BehaviorPoint bp) {
    if (bp.id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete behavior point?',
            style: TextStyle(fontFamily: 'Raleway', fontSize: 16)),
        content: Text(
            '${bp.isPositive ? '+' : ''}${bp.points} ${BehaviorCategory.fromId(bp.categoryId).name} for ${bp.studentName}',
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.deleteBehaviorPoint(bp.id);
                setState(() => _classBehavior.removeWhere((b) => b.id == bp.id));
                _snack('Behavior point deleted');
              } catch (e) {
                _snack('Failed to delete');
              }
            },
            child: Text('Delete', style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
  }

  void _showBehaviorSheet(String studentUid, String studentName, String classId) {
    final categories = BehaviorCategory.defaults;
    final positive = categories.where((c) => c.isPositive).toList();
    final negative = categories.where((c) => !c.isPositive).toList();
    final noteCtrl = TextEditingController();
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              TextField(
                controller: noteCtrl,
                style: const TextStyle(
                    fontFamily: 'Raleway', fontSize: 13, color: textDark),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  hintStyle: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 13,
                      color: Colors.grey.shade400),
                  filled: true,
                  fillColor: bg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: primary.withOpacity(0.5), width: 1.5)),
                ),
              ),
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
                        studentName, classId, noteCtrl))
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
                        studentName, classId, noteCtrl))
                    .toList(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _behaviorChip(BehaviorCategory cat, bool isPositive,
      String studentUid, String studentName, String classId,
      TextEditingController noteCtrl) {
    final chipColor = isPositive ? success : danger;
    return GestureDetector(
      onTap: () async {
        final note = noteCtrl.text.trim();
        Navigator.pop(context);
        final resp = await _api.awardBehaviorPoint(
          studentUid: studentUid,
          classId: classId,
          categoryId: cat.id,
          studentName: studentName,
          points: isPositive ? 1 : -1,
          note: note,
        );
        final newId = resp['id'] as String? ?? '';
        setState(() => _classBehavior.add(BehaviorPoint(
          id: newId,
          studentUid: studentUid,
          studentName: studentName,
          classId: classId,
          categoryId: cat.id,
          points: isPositive ? 1 : -1,
          awardedBy: _uid,
          awardedByName: _user?.name ?? '',
          note: note,
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

    final allStudents = List<UserModel>.from(_allSchoolStudents);
    if (allStudents.isEmpty) {
      final seenUids = <String>{};
      for (final cls in _classes) {
        for (final uid in cls.studentUids) {
          if (seenUids.add(uid)) {
            final match = _students.where((s) => s.uid == uid);
            if (match.isNotEmpty) allStudents.add(match.first);
          }
        }
      }
      for (final s in _students) {
        if (!seenUids.contains(s.uid)) {
          seenUids.add(s.uid);
          allStudents.add(s);
        }
      }
    }
    allStudents.sort((a, b) => a.name.compareTo(b.name));

    final preMarked = <String, AttendanceStatus>{};
    for (final r in _todayAttendance) {
      preMarked[r.studentUid] = r.status;
    }

    return StatefulBuilder(builder: (ctx, setLocal) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: StatefulBuilder(builder: (ctx2, setInner) {
          final filtered = _attSearchQuery.isEmpty
              ? allStudents
              : allStudents
                  .where((s) =>
                      s.name.toLowerCase().contains(_attSearchQuery.toLowerCase()))
                  .toList();

          final presentCount =
              allStudents.where((s) => (preMarked[s.uid] ?? AttendanceStatus.present) == AttendanceStatus.present).length;
          final absentCount =
              allStudents.where((s) => preMarked[s.uid] == AttendanceStatus.absent).length;
          final tardyCount =
              allStudents.where((s) => preMarked[s.uid] == AttendanceStatus.tardy).length;

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                child: Text('$displayDate • ${allStudents.length} students in school',
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 13, color: textLight))),
            const SizedBox(height: 16),
            // Summary chips
            Row(children: [
              _attSummaryChip('Present', presentCount, success),
              const SizedBox(width: 8),
              _attSummaryChip('Absent', absentCount, danger),
              const SizedBox(width: 8),
              _attSummaryChip('Tardy', tardyCount, accent),
            ]),
            const SizedBox(height: 16),
            if (_todayAttendance.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: success.withOpacity(0.2))),
                child: Row(children: [
                  Icon(Icons.check_circle_outline, color: success, size: 14),
                  const SizedBox(width: 6),
                  const Expanded(
                      child: Text('Attendance already marked today. You can update it.',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: textMid))),
                ]),
              ),
            // Bulk actions
            Row(children: [
              _attBulkBtn('All Present', success, () {
                setInner(() {
                  for (final s in allStudents) {
                    preMarked[s.uid] = AttendanceStatus.present;
                  }
                });
              }),
              const SizedBox(width: 8),
              _attBulkBtn('All Absent', danger, () {
                setInner(() {
                  for (final s in allStudents) {
                    preMarked[s.uid] = AttendanceStatus.absent;
                  }
                });
              }),
            ]),
            const SizedBox(height: 12),
            // Search
            TextField(
              onChanged: (v) => setInner(() => _attSearchQuery = v),
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 13, color: textDark),
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18, color: Colors.grey.shade400),
                filled: true,
                fillColor: bgCard,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primary.withOpacity(0.4))),
              ),
            ),
            const SizedBox(height: 12),
            ...filtered.map((s) {
              final current = preMarked[s.uid] ?? AttendanceStatus.present;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Row(children: [
                  CircleAvatar(
                      radius: 16,
                      backgroundColor: primary.withOpacity(0.1),
                      child: Text(s.initial,
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primary))),
                  const SizedBox(width: 10),
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
                            setInner(() {
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
                for (final s in allStudents) {
                  finalStatuses[s.uid] =
                      preMarked[s.uid] ?? AttendanceStatus.present;
                  names[s.uid] = s.name;
                }
                final records = finalStatuses.entries.map((e) => {
                  'studentUid': e.key,
                  'studentName': names[e.key] ?? '',
                  'date': dateStr,
                  'status': e.value.label,
                }).toList();
                _api.markAttendanceBatch(records);
                setState(() {
                  _todayAttendance = finalStatuses.entries.map((e) =>
                    AttendanceRecord(
                      studentUid: e.key,
                      studentName: names[e.key] ?? '',
                      date: dateStr,
                      status: e.value,
                      markedBy: _uid,
                      createdAt: DateTime.now(),
                    )).toList();
                });
                _snack('Attendance saved for ${allStudents.length} students');
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
          ]);
        }),
      );
    });
  }

  Widget _attSummaryChip(String label, int count, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: c.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.withOpacity(0.2))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$count $label',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c)),
        ]),
      );

  Widget _attBulkBtn(String label, Color c, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: c))),
          ),
        ),
      );

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

  // ─── SCHEDULE TAB ──────────────────────────────────────────────────────────

  Map<String, Map<String, String>> get _schedGsMap {
    final gsMap = <String, Map<String, String>>{};
    for (final cls in _classes) {
      final parts = cls.name.split('—').map((s) => s.trim()).toList();
      if (parts.length >= 2) {
        final gradePart = parts[0].replaceAll(RegExp(r'[^0-9]'), '');
        final sectionPart = parts[1].replaceAll(RegExp(r'Section\s*', caseSensitive: false), '').trim();
        if (gradePart.isNotEmpty && sectionPart.isNotEmpty) {
          final key = 'Grade $gradePart - $sectionPart';
          if (!gsMap.containsKey(key)) {
            gsMap[key] = {'grade': gradePart, 'section': sectionPart};
          }
        }
      }
    }
    if (gsMap.isEmpty) gsMap['Default'] = {'grade': '0', 'section': 'A'};
    return gsMap;
  }

  Future<void> _loadTeacherSchedule() async {
    if (_tSchedLoading) return;
    final gsMap = _schedGsMap;
    if (_tSchedSelectedGS.isEmpty || !gsMap.containsKey(_tSchedSelectedGS)) {
      _tSchedSelectedGS = gsMap.keys.first;
    }
    final gs = gsMap[_tSchedSelectedGS]!;
    setState(() => _tSchedLoading = true);
    try {
      final raw = await _api.getSchedule(gs['grade']!, gs['section']!);
      _tSchedData = raw.map((m) => ScheduleModel.fromJson(m)).toList();
    } catch (e) {
      debugPrint('Schedule load error: $e');
      _tSchedData = [];
    }
    if (mounted) setState(() { _tSchedLoading = false; _tSchedLoaded = true; });
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  void _loadCalendar() async {
    if (_calLoading) return;
    setState(() => _calLoading = true);
    final ws = _mondayOf(_calWeekStart);
    final we = ws.add(const Duration(days: 6));
    try {
      final data = await _api.getTeacherCalendar(
          _uid, _dateStr(ws), _dateStr(we));
      _calPeriods =
          (data['periods'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _calEvents =
          (data['events'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      _calCancellations =
          (data['cancellations'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      debugPrint('Calendar load error: $e');
      _calPeriods = [];
      _calEvents = [];
      _calCancellations = [];
    }
    if (mounted) setState(() { _calLoading = false; _calLoaded = true; });
  }

  Widget _buildScheduleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        FadeSlideIn(
            child: const Text('Schedule',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    letterSpacing: -0.8))),
        const SizedBox(height: 12),
        // View mode toggle
        Container(
          decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(3),
          child: Row(children: [
            _schedModeBtn('My Week', 0),
            _schedModeBtn('Edit Timetable', 1),
          ]),
        ),
        const SizedBox(height: 16),
        if (_schedViewMode == 0)
          _buildMyWeekCalendar()
        else
          _buildTimetableEditor(),
      ]),
    );
  }

  Widget _schedModeBtn(String label, int mode) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _schedViewMode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                color: _schedViewMode == mode ? primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _schedViewMode == mode
                            ? Colors.white
                            : textLight))),
          ),
        ),
      );

  // ─── MY WEEK CALENDAR (Outlook-style) ─────────────────────────────────────

  Widget _buildMyWeekCalendar() {
    if (!_calLoaded && !_calLoading) {
      _calWeekStart = _mondayOf(DateTime.now());
      Future.microtask(_loadCalendar);
    }

    final ws = _mondayOf(_calWeekStart);
    final weekLabel =
        '${_monthName(ws.month)} ${ws.day} — ${_monthName(ws.add(const Duration(days: 4)).month)} ${ws.add(const Duration(days: 4)).day}';

    // Build time grid: 8am–4pm
    const startHour = 8;
    const endHour = 16;
    const hourHeight = 60.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Week navigation
      Row(children: [
        GestureDetector(
          onTap: () {
            _calWeekStart = ws.subtract(const Duration(days: 7));
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.chevron_left_rounded,
                  size: 20, color: textLight)),
        ),
        Expanded(
            child: Center(
                child: Text(weekLabel,
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark)))),
        GestureDetector(
          onTap: () {
            _calWeekStart = ws.add(const Duration(days: 7));
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200)),
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: textLight)),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            _calWeekStart = _mondayOf(DateTime.now());
            _calLoaded = false;
            _loadCalendar();
          },
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Today',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary))),
        ),
      ]),
      const SizedBox(height: 12),
      // Events banner
      if (_calEvents.isNotEmpty)
        ..._calEvents.map((ev) {
          final evDate = ev['date'] as String? ?? '';
          final evTitle = ev['title'] as String? ?? '';
          final evType = ev['type'] as String? ?? 'event';
          final cancels = ev['cancelsRegularSchedule'] == true;
          final c = evType == 'holiday'
              ? danger
              : evType == 'ptm'
                  ? purple
                  : accent;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Row(children: [
              Icon(
                  evType == 'holiday'
                      ? Icons.wb_sunny_outlined
                      : evType == 'ptm'
                          ? Icons.people_outline
                          : Icons.event_outlined,
                  size: 16,
                  color: c),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(evTitle,
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: c)),
                    Text(
                        '${evDate}${cancels ? ' · Regular schedule cancelled' : ''}',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 10,
                            color: textLight)),
                  ])),
              GestureDetector(
                onTap: () async {
                  final id = ev['id'] as String? ?? '';
                  if (id.isEmpty) return;
                  await _api.deleteScheduleEvent(id);
                  _calLoaded = false;
                  _loadCalendar();
                },
                child: Icon(Icons.close_rounded, size: 16, color: textLight),
              ),
            ]),
          );
        }),
      // Add event button
      GestureDetector(
        onTap: () => _showAddEventSheet(ws),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: accent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, size: 16, color: accent),
            const SizedBox(width: 4),
            Text('Add Special Event',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (_calLoading && !_calLoaded)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2)))
      else
        // Outlook-style week grid
        SizedBox(
          height: (endHour - startHour) * hourHeight + 36,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Time gutter
            SizedBox(
              width: 40,
              child: Column(children: [
                const SizedBox(height: 36),
                ...List.generate(endHour - startHour, (i) => SizedBox(
                      height: hourHeight,
                      child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                                '${(startHour + i).toString().padLeft(2, '0')}:00',
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 9,
                                    color: textLight)),
                          )),
                    )),
              ]),
            ),
            // Day columns
            ...List.generate(5, (dayIdx) {
              final day = dayIdx + 1;
              final dateOfDay = ws.add(Duration(days: dayIdx));
              final isToday = _dateStr(dateOfDay) == _dateStr(DateTime.now());

              final dayPeriods = _calPeriods
                  .where((p) => (p['dayOfWeek'] as num?)?.toInt() == day)
                  .toList();

              // Check if events cancel this day
              final dayCancelled = _calEvents.any((ev) =>
                  ev['date'] == _dateStr(dateOfDay) &&
                  ev['cancelsRegularSchedule'] == true);

              return Expanded(
                child: Column(children: [
                  // Day header
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                        color: isToday
                            ? primary.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Text(ScheduleModel.dayNames[day],
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isToday ? primary : textLight)),
                          Text('${dateOfDay.day}',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? primary : textDark)),
                        ])),
                  ),
                  // Time grid
                  Container(
                    height: (endHour - startHour) * hourHeight,
                    decoration: BoxDecoration(
                        border: Border(
                            left: BorderSide(
                                color: Colors.grey.shade100, width: 0.5))),
                    child: Stack(children: [
                      // Hour gridlines
                      ...List.generate(
                          endHour - startHour,
                          (i) => Positioned(
                                top: i * hourHeight,
                                left: 0,
                                right: 0,
                                child: Container(
                                    height: 0.5,
                                    color: Colors.grey.shade100),
                              )),
                      if (dayCancelled)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                                color: danger.withOpacity(0.03)),
                            child: Center(
                                child: Text('Cancelled',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 10,
                                        color: danger.withOpacity(0.3)))),
                          ),
                        )
                      else
                        // Period blocks
                        ...dayPeriods.map((p) {
                          final st = p['startTime'] as String? ?? '08:00';
                          final et = p['endTime'] as String? ?? '08:45';
                          final subj = p['subject'] as String? ?? '';
                          final grade = p['grade'] as String? ?? '';
                          final section = p['section'] as String? ?? '';

                          final stParts = st.split(':');
                          final etParts = et.split(':');
                          final stMin = (int.tryParse(stParts[0]) ?? startHour) * 60 +
                              (stParts.length > 1
                                  ? int.tryParse(stParts[1]) ?? 0
                                  : 0);
                          final etMin = (int.tryParse(etParts[0]) ?? startHour) * 60 +
                              (etParts.length > 1
                                  ? int.tryParse(etParts[1]) ?? 0
                                  : 0);
                          final top =
                              (stMin - startHour * 60) * hourHeight / 60;
                          final height =
                              (etMin - stMin) * hourHeight / 60;

                          final colors = [
                            primary, info, accent, purple, success
                          ];
                          final c =
                              colors[subj.hashCode.abs() % colors.length];

                          final dateStr = _dateStr(dateOfDay);
                          final isCancelled = _calCancellations.any((cn) =>
                              cn['grade'] == grade &&
                              cn['section'] == section &&
                              cn['date'] == dateStr &&
                              cn['startTime'] == st);
                          final cancelId = isCancelled
                              ? (_calCancellations.firstWhere((cn) =>
                                  cn['grade'] == grade &&
                                  cn['section'] == section &&
                                  cn['date'] == dateStr &&
                                  cn['startTime'] == st)['id'] as String? ?? '')
                              : '';

                          final gsKey = _schedGsMap.keys.cast<String?>().firstWhere(
                              (k) {
                                final m = _schedGsMap[k];
                                return m != null &&
                                    m['grade'] == grade &&
                                    m['section'] == section;
                              },
                              orElse: () => null);
                          return Positioned(
                            top: top.clamp(0, double.infinity),
                            left: 1,
                            right: 1,
                            height: height.clamp(20, double.infinity),
                            child: GestureDetector(
                              onTap: () {
                                if (isCancelled) {
                                  _showUndoCancelSheet(cancelId, subj, grade, section, dateStr);
                                } else {
                                  _showPeriodCancelSheet(p, dateOfDay, gsKey);
                                }
                              },
                              child: Opacity(
                                opacity: isCancelled ? 0.45 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1, vertical: 0.5),
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                      color: isCancelled
                                          ? Colors.grey.shade200
                                          : c.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: isCancelled
                                              ? Colors.grey.shade300
                                              : c.withOpacity(0.3))),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            isCancelled ? '$subj ✕' : subj,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isCancelled ? Colors.grey : c,
                                                decoration: isCancelled
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none)),
                                        if (height > 28)
                                          Text(isCancelled ? 'Cancelled' : '$grade-$section',
                                              style: TextStyle(
                                                  fontFamily: 'Raleway',
                                                  fontSize: 8,
                                                  color: isCancelled
                                                      ? danger.withOpacity(0.7)
                                                      : c.withOpacity(0.7))),
                                      ]),
                                ),
                              ),
                            ),
                          );
                        }),
                      // Event blocks
                      ..._calEvents
                          .where((ev) =>
                              ev['date'] == _dateStr(dateOfDay) &&
                              (ev['startTime'] as String? ?? '').isNotEmpty)
                          .map((ev) {
                        final st = ev['startTime'] as String? ?? '09:00';
                        final et = ev['endTime'] as String? ?? '10:00';
                        final stParts = st.split(':');
                        final etParts = et.split(':');
                        final stMin = (int.tryParse(stParts[0]) ?? 9) * 60 +
                            (stParts.length > 1
                                ? int.tryParse(stParts[1]) ?? 0
                                : 0);
                        final etMin = (int.tryParse(etParts[0]) ?? 10) * 60 +
                            (etParts.length > 1
                                ? int.tryParse(etParts[1]) ?? 0
                                : 0);
                        final top =
                            (stMin - startHour * 60) * hourHeight / 60;
                        final height = (etMin - stMin) * hourHeight / 60;
                        return Positioned(
                          top: top.clamp(0, double.infinity),
                          left: 1,
                          right: 1,
                          height: height.clamp(20, double.infinity),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 1, vertical: 0.5),
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                color: accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: accent.withOpacity(0.4),
                                    width: 1.5)),
                            child: Text(
                                ev['title'] as String? ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: accent)),
                          ),
                        );
                      }),
                    ]),
                  ),
                ]),
              );
            }),
          ]),
        ),
      const SizedBox(height: 24),
    ]);
  }

  // ─── PERIOD CANCEL / UNDO SHEETS ────────────────────────────────────────────

  void _showPeriodCancelSheet(Map<String, dynamic> period, DateTime dateOfDay, String? gsKey) {
    final subj = period['subject'] as String? ?? '';
    final grade = period['grade'] as String? ?? '';
    final section = period['section'] as String? ?? '';
    final st = period['startTime'] as String? ?? '';
    final classId = period['classId'] as String? ?? '';
    final dateStr = _dateStr(dateOfDay);
    final dayName = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateOfDay.weekday];
    final reasonCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Text('$subj · $grade-$section',
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          Text('$st · $dayName, ${_monthName(dateOfDay.month)} ${dateOfDay.day}',
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 13, color: textLight)),
          const SizedBox(height: 16),
          TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              hintText: 'Reason (optional)',
              hintStyle: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: textLight.withOpacity(0.5)),
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            style: const TextStyle(
                fontFamily: 'Raleway', fontSize: 13, color: textDark),
          ),
          const SizedBox(height: 16),
          Row(children: [
            if (gsKey != null)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _schedViewMode = 1;
                      _tSchedSelectedGS = gsKey;
                      _tSchedDay = dateOfDay.weekday;
                      _tSchedLoaded = false;
                      _loadTeacherSchedule();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: const Center(
                        child: Text('Edit Timetable',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textDark))),
                  ),
                ),
              ),
            if (gsKey != null) const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _api.cancelPeriod(
                      grade: grade,
                      section: section,
                      date: dateStr,
                      startTime: st,
                      classId: classId,
                      reason: reasonCtrl.text.trim(),
                    );
                    _calLoaded = false;
                    _loadCalendar();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: danger.withOpacity(0.3))),
                  child: Center(
                      child: Text(
                          'Cancel for $dayName, ${_monthName(dateOfDay.month)} ${dateOfDay.day}',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: danger))),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showUndoCancelSheet(String cancelId, String subj, String grade, String section, String dateStr) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Icon(Icons.cancel_outlined, size: 36, color: danger),
          const SizedBox(height: 10),
          Text('$subj · $grade-$section',
              style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark)),
          const SizedBox(height: 4),
          Text('This period is cancelled for $dateStr',
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 13, color: textLight)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              Navigator.pop(ctx);
              if (cancelId.isEmpty) return;
              try {
                await _api.undoCancelPeriod(cancelId);
                _calLoaded = false;
                _loadCalendar();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $e')));
                }
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                  color: success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: success.withOpacity(0.3))),
              child: Center(
                  child: Text('Restore This Period',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: success))),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── TIMETABLE EDITOR (existing) ──────────────────────────────────────────

  Widget _buildTimetableEditor() {
    if (!_calLoaded && !_calLoading) {
      _calWeekStart = _mondayOf(DateTime.now());
      Future.microtask(_loadCalendar);
    }
    final gsMap = _schedGsMap;

    // All periods for this day across all grades
    final dayCalPeriods = _calPeriods
        .where((p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay)
        .toList();
    // Sort by start time
    dayCalPeriods.sort((a, b) =>
        (a['startTime'] as String? ?? '').compareTo(b['startTime'] as String? ?? ''));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your classes',
          style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textLight)),
      const SizedBox(height: 8),
      // Show all assigned classes as chips
      if (_classes.isEmpty)
        Text('No classes assigned',
            style: TextStyle(
                fontFamily: 'Raleway', fontSize: 12, color: Colors.grey.shade400))
      else
        Wrap(spacing: 6, runSpacing: 6, children: _classes.map((cls) {
          final colors = [primary, info, accent, purple, success];
          final c = colors[cls.subject.hashCode.abs() % colors.length];
          final parts = cls.name.split('—').map((s) => s.trim()).toList();
          final gradeLabel = parts.isNotEmpty ? parts[0] : cls.name;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(cls.subject,
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: c)),
              const SizedBox(width: 4),
              Text(gradeLabel,
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 10,
                      color: c.withOpacity(0.6))),
            ]),
          );
        }).toList()),
      const SizedBox(height: 16),
      // Day selector
      Row(
        children: List.generate(5, (i) {
          final day = i + 1;
          final isActive = day == _tSchedDay;
          final dayCount = _calPeriods
              .where((p) => (p['dayOfWeek'] as num?)?.toInt() == day)
              .length;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tSchedDay = day),
              child: Container(
                margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: isActive ? primary : bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isActive ? primary : Colors.grey.shade200)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(ScheduleModel.dayNames[day],
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : textLight)),
                  if (dayCount > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: isActive ? Colors.white.withOpacity(0.2) : primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('$dayCount',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.white : primary)),
                    ),
                ]),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 16),
      // Day schedule — all periods across all grades
      Row(children: [
        Text(ScheduleModel.dayNamesFull[_tSchedDay],
            style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textDark)),
        const Spacer(),
        Text('${dayCalPeriods.length} period${dayCalPeriods.length == 1 ? '' : 's'}',
            style: const TextStyle(
                fontFamily: 'Raleway', fontSize: 12, color: textLight)),
      ]),
      const SizedBox(height: 12),
      if (_calLoading && !_calLoaded)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2)))
      else if (dayCalPeriods.isEmpty)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28),
          child: Center(
            child: Column(children: [
              Icon(Icons.event_available_rounded, size: 32, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('No classes on ${ScheduleModel.dayNamesFull[_tSchedDay]}',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: Colors.grey.shade400)),
              const SizedBox(height: 4),
              Text('Tap + to add a class',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 11, color: Colors.grey.shade300)),
            ]),
          ),
        )
      else
        ...dayCalPeriods.map((p) {
          final subj = p['subject'] as String? ?? '';
          final grade = p['grade'] as String? ?? '';
          final section = p['section'] as String? ?? '';
          final st = p['startTime'] as String? ?? '';
          final et = p['endTime'] as String? ?? '';
          final classId = p['classId'] as String? ?? '';
          final teacherName = p['teacherName'] as String? ?? '';
          final colors = [primary, info, accent, purple, success];
          final c = colors[subj.hashCode.abs() % colors.length];

          final edWs = _mondayOf(_calWeekStart);
          final edDayDate = edWs.add(Duration(days: _tSchedDay - 1));
          final edDateStr = _dateStr(edDayDate);
          final edCancelled = _calCancellations.any((cn) =>
              cn['grade'] == grade &&
              cn['section'] == section &&
              cn['date'] == edDateStr &&
              cn['startTime'] == st);

          // Find which gsKey and period index this maps to for editing
          final gsKey = gsMap.keys.cast<String?>().firstWhere((k) {
            final m = gsMap[k];
            return m != null && m['grade'] == grade && m['section'] == section;
          }, orElse: () => null);

          return GestureDetector(
            onTap: gsKey != null ? () {
              _tSchedSelectedGS = gsKey;
              _tSchedLoaded = false;
              Future.microtask(() async {
                await _loadTeacherSchedule();
                if (!mounted) return;
                final daySchedule = _tSchedData
                    .where((s) => s.dayOfWeek == _tSchedDay)
                    .toList();
                final periods = daySchedule.isNotEmpty
                    ? daySchedule.first.periods
                    : <PeriodSlot>[];
                final idx = periods.indexWhere(
                    (ps) => ps.startTime == st && ps.classId == classId);
                if (idx >= 0) {
                  _editPeriodSlot(periods[idx], idx, _tSchedDay,
                      gsKey, gsMap, periods);
                }
              });
            } : null,
            child: Opacity(
              opacity: edCancelled ? 0.5 : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: edCancelled ? Colors.grey.shade50 : bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: edCancelled ? Colors.grey.shade200 : c.withOpacity(0.15))),
                child: Row(children: [
                  Container(
                    width: 4, height: 42,
                    decoration: BoxDecoration(
                        color: edCancelled ? Colors.grey.shade300 : c,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$st - $et',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textLight,
                                decoration: edCancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                      ]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(
                              child: Text(subj,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: edCancelled ? Colors.grey : c,
                                      decoration: edCancelled ? TextDecoration.lineThrough : TextDecoration.none)),
                            ),
                            if (edCancelled) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                    color: danger.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text('Cancelled',
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: danger)),
                              ),
                            ],
                          ]),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: c.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('$grade-$section',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: c.withOpacity(0.7))),
                            ),
                            if (teacherName.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(teacherName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 10,
                                        color: textLight)),
                              ),
                            ],
                          ]),
                        ]),
                  ),
                  Icon(Icons.edit_rounded, size: 16, color: Colors.grey.shade300),
                ]),
              ),
            ),
          );
        }),
      const SizedBox(height: 12),
      // Add period — pick grade, class, time
      GestureDetector(
        onTap: () => _showAddPeriodSheet(gsMap),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primary.withOpacity(0.15))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.add_rounded, color: primary, size: 18),
            const SizedBox(width: 6),
            Text('Add Period',
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary)),
          ]),
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }

  void _showAddPeriodSheet(Map<String, Map<String, String>> gsMap) {
    String selectedClassId = '';
    String selectedSubject = '';
    String selectedTeacher = '';
    String selectedGSKey = gsMap.keys.isNotEmpty ? gsMap.keys.first : '';
    final startCtrl = TextEditingController(
        text: _defaultStartTime(_calPeriods.where(
            (p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay).length));
    final endCtrl = TextEditingController(
        text: _defaultEndTime(_calPeriods.where(
            (p) => (p['dayOfWeek'] as num?)?.toInt() == _tSchedDay).length));

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                    width: 36, height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Add Period — ${ScheduleModel.dayNamesFull[_tSchedDay]}',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
                const SizedBox(height: 4),
                const Text('Select a class and time for this period',
                    style: TextStyle(
                        fontFamily: 'Raleway', fontSize: 12, color: textLight)),
                const SizedBox(height: 20),
                // Class selection as tappable cards
                const Text('Select Class',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
                const SizedBox(height: 8),
                ..._classes.map((cls) {
                  final isSelected = cls.id == selectedClassId;
                  final colors = [primary, info, accent, purple, success];
                  final c = colors[cls.subject.hashCode.abs() % colors.length];
                  final parts = cls.name.split('—').map((s) => s.trim()).toList();
                  final gradeLabel = parts.isNotEmpty ? parts[0] : cls.name;
                  // Auto-detect the grade/section for this class
                  final clsGSKey = gsMap.keys.cast<String?>().firstWhere((k) {
                    final m = gsMap[k];
                    if (m == null) return false;
                    return cls.name.contains(m['grade']!) &&
                        cls.name.toLowerCase().contains('section ${m['section']!.toLowerCase()}');
                  }, orElse: () => null);
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      selectedClassId = cls.id;
                      selectedSubject = cls.subject;
                      selectedTeacher = cls.teacherName;
                      if (clsGSKey != null) selectedGSKey = clsGSKey;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSelected ? c.withOpacity(0.08) : bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? c : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: isSelected ? c : Colors.grey.shade300,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.subject,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? c : textDark)),
                              Text('$gradeLabel  ·  ${cls.teacherName}',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 11,
                                      color: isSelected ? c.withOpacity(0.6) : textLight)),
                            ])),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: c, size: 18),
                      ]),
                    ),
                  );
                }),
                if (gsMap.length > 1 && selectedClassId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('For Grade',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textLight)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: DropdownButton<String>(
                      value: gsMap.containsKey(selectedGSKey) ? selectedGSKey : gsMap.keys.first,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                          fontFamily: 'Raleway', fontSize: 14, color: textDark),
                      items: gsMap.keys
                          .map((gs) => DropdownMenuItem(
                              value: gs,
                              child: Text(gs,
                                  style: const TextStyle(
                                      fontFamily: 'Raleway', fontSize: 14, color: textDark))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setSheet(() => selectedGSKey = v);
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Time',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(
                    controller: startCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _scheduleFieldDecor('Start', '08:00'),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to',
                        style: TextStyle(
                            fontFamily: 'Raleway', fontSize: 13, color: textLight)),
                  ),
                  Expanded(child: TextField(
                    controller: endCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _scheduleFieldDecor('End', '08:45'),
                  )),
                ]),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: selectedClassId.isEmpty ? null : () async {
                    final gs = gsMap[selectedGSKey];
                    if (gs == null) return;
                    // Load current periods for this grade/section/day
                    try {
                      final raw = await _api.getSchedule(gs['grade']!, gs['section']!);
                      final schedules = raw.map((m) => ScheduleModel.fromJson(m)).toList();
                      final daySchedule = schedules
                          .where((s) => s.dayOfWeek == _tSchedDay)
                          .toList();
                      final existingPeriods = daySchedule.isNotEmpty
                          ? daySchedule.first.periods
                          : <PeriodSlot>[];
                      final newSlot = PeriodSlot(
                        period: existingPeriods.length + 1,
                        startTime: startCtrl.text.trim(),
                        endTime: endCtrl.text.trim(),
                        classId: selectedClassId,
                        subject: selectedSubject,
                        teacherName: selectedTeacher,
                      );
                      final updated = [...existingPeriods, newSlot];
                      await _api.upsertSchedule(
                        grade: gs['grade']!,
                        section: gs['section']!,
                        dayOfWeek: _tSchedDay,
                        periods: updated.map((p) => p.toMap()).toList(),
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _calLoaded = false;
                      _loadCalendar();
                      _snack('Period added!');
                    } catch (e) {
                      debugPrint('Add period error: $e');
                      _snack('Failed to add period');
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                        color: selectedClassId.isEmpty
                            ? Colors.grey.shade300
                            : primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: selectedClassId.isEmpty ? [] : [
                          BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Center(
                        child: Text('Add Period',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                  ),
                ),
              ],
            )),
          ),
        );
      }),
    );
  }

  void _showAddEventSheet(DateTime weekStart) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String startTime = '09:00';
    String endTime = '10:00';
    String eventType = 'event';
    bool cancels = false;

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
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  const Text('Add Special Event',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 16),
                  // Event type
                  const Text('Type',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textLight)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _eventTypeChip('event', 'Special Event', Icons.event_outlined,
                        accent, eventType, (v) => setModal(() => eventType = v)),
                    _eventTypeChip('ptm', 'PTM', Icons.people_outline,
                        purple, eventType, (v) => setModal(() => eventType = v)),
                    _eventTypeChip('holiday', 'Holiday', Icons.wb_sunny_outlined,
                        danger, eventType, (v) => setModal(() => eventType = v)),
                    _eventTypeChip('override', 'Override', Icons.swap_horiz_rounded,
                        info, eventType, (v) => setModal(() => eventType = v)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _hwFieldDecor('Event title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _hwFieldDecor('Description (optional)'),
                  ),
                  const SizedBox(height: 10),
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx2, child) => Theme(
                          data: Theme.of(ctx2).copyWith(
                              colorScheme:
                                  ColorScheme.light(primary: accent)),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModal(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: textLight),
                        const SizedBox(width: 8),
                        Text(_dateStr(selectedDate),
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                color: textDark)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Time range
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: int.tryParse(startTime.split(':')[0]) ?? 9,
                                minute: int.tryParse(startTime.split(':')[1]) ?? 0),
                          );
                          if (t != null) {
                            setModal(() => startTime =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade200)),
                          child: Row(children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: textLight),
                            const SizedBox(width: 6),
                            Text(startTime,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    color: textDark)),
                          ]),
                        ),
                      ),
                    ),
                    const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('—',
                            style: TextStyle(color: textLight))),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: int.tryParse(endTime.split(':')[0]) ?? 10,
                                minute: int.tryParse(endTime.split(':')[1]) ?? 0),
                          );
                          if (t != null) {
                            setModal(() => endTime =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                              color: bg,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade200)),
                          child: Row(children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: textLight),
                            const SizedBox(width: 6),
                            Text(endTime,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    color: textDark)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Cancels regular schedule toggle
                  GestureDetector(
                    onTap: () => setModal(() => cancels = !cancels),
                    child: Row(children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            color: cancels
                                ? danger
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: cancels
                                    ? danger
                                    : Colors.grey.shade300)),
                        child: cancels
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text(
                              'Cancels regular classes for the day',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: textDark))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      await _api.createScheduleEvent(
                        title: title,
                        date: _dateStr(selectedDate),
                        description: descCtrl.text.trim(),
                        startTime: startTime,
                        endTime: endTime,
                        type: eventType,
                        cancelsRegularSchedule: cancels,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _calLoaded = false;
                      _loadCalendar();
                      _snack('Event added!');
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
                          child: Text('Add Event',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventTypeChip(String type, String label, IconData icon, Color c,
      String current, ValueChanged<String> onTap) {
    final active = type == current;
    return GestureDetector(
      onTap: () => onTap(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: active ? c.withOpacity(0.12) : bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: active ? c : Colors.grey.shade200, width: active ? 1.5 : 1)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? c : textLight),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? c : textLight)),
        ]),
      ),
    );
  }


  void _editPeriodSlot(
      PeriodSlot slot, int index, int dayOfWeek, String selectedGS,
      Map<String, Map<String, String>> gsMap, List<PeriodSlot> allPeriods) {
    final startCtrl = TextEditingController(text: slot.startTime);
    final endCtrl = TextEditingController(text: slot.endTime);
    String selectedClassId = slot.classId;
    String selectedSubject = slot.subject;
    String selectedTeacher = slot.teacherName;

    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        final gs = gsMap[selectedGS];
        final gradeLabel = gs != null ? 'Grade ${gs['grade']}-${gs['section']}' : selectedGS;
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: const BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                    width: 36, height: 3,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Edit Period — $gradeLabel',
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
                const SizedBox(height: 4),
                Text('${ScheduleModel.dayNamesFull[dayOfWeek]}, ${slot.startTime} – ${slot.endTime}',
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 12, color: textLight)),
                const SizedBox(height: 20),
                const Text('Class',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
                const SizedBox(height: 8),
                ..._classes.map((cls) {
                  final isSelected = cls.id == selectedClassId;
                  final colors = [primary, info, accent, purple, success];
                  final c = colors[cls.subject.hashCode.abs() % colors.length];
                  final parts = cls.name.split('—').map((s) => s.trim()).toList();
                  final clsGrade = parts.isNotEmpty ? parts[0] : cls.name;
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      selectedClassId = cls.id;
                      selectedSubject = cls.subject;
                      selectedTeacher = cls.teacherName;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: isSelected ? c.withOpacity(0.08) : bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? c : Colors.grey.shade200,
                              width: isSelected ? 1.5 : 1)),
                      child: Row(children: [
                        Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                                color: isSelected ? c : Colors.grey.shade300,
                                shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cls.subject,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? c : textDark)),
                              Text('$clsGrade  ·  ${cls.teacherName}',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 11,
                                      color: isSelected ? c.withOpacity(0.6) : textLight)),
                            ])),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: c, size: 18),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                const Text('Time',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textLight)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: TextField(
                    controller: startCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _scheduleFieldDecor('Start', '08:00'),
                  )),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to',
                        style: TextStyle(
                            fontFamily: 'Raleway', fontSize: 13, color: textLight)),
                  ),
                  Expanded(child: TextField(
                    controller: endCtrl,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _scheduleFieldDecor('End', '08:45'),
                  )),
                ]),
                const SizedBox(height: 16),
                // Cancel for specific date
                Builder(builder: (_) {
                  final gsData = gsMap[selectedGS];
                  final pGrade = gsData?['grade'] ?? '';
                  final pSection = gsData?['section'] ?? '';
                  final ws = _mondayOf(_calWeekStart);
                  final dayDate = ws.add(Duration(days: dayOfWeek - 1));
                  final dayName = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dayDate.weekday];
                  final dateStr = _dateStr(dayDate);
                  final alreadyCancelled = _calCancellations.any((cn) =>
                      cn['grade'] == pGrade &&
                      cn['section'] == pSection &&
                      cn['date'] == dateStr &&
                      cn['startTime'] == slot.startTime);
                  if (alreadyCancelled) {
                    final cId = _calCancellations.firstWhere((cn) =>
                        cn['grade'] == pGrade &&
                        cn['section'] == pSection &&
                        cn['date'] == dateStr &&
                        cn['startTime'] == slot.startTime)['id'] as String? ?? '';
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        if (cId.isEmpty) return;
                        try {
                          await _api.undoCancelPeriod(cId);
                          _calLoaded = false;
                          _loadCalendar();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')));
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                            color: success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: success.withOpacity(0.25))),
                        child: Center(
                            child: Text('Restore — Cancelled for $dayName, ${_monthName(dayDate.month)} ${dayDate.day}',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: success))),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await _api.cancelPeriod(
                          grade: pGrade,
                          section: pSection,
                          date: dateStr,
                          startTime: slot.startTime,
                          classId: slot.classId,
                        );
                        _calLoaded = false;
                        _loadCalendar();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: danger.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: danger.withOpacity(0.2))),
                      child: Center(
                          child: Text('Cancel for $dayName, ${_monthName(dayDate.month)} ${dayDate.day}',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: danger))),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(children: [
                  // Remove button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<PeriodSlot>.from(allPeriods);
                        if (index < updated.length) updated.removeAt(index);
                        for (var i = 0; i < updated.length; i++) {
                          updated[i] = PeriodSlot(
                            period: i + 1,
                            startTime: updated[i].startTime,
                            endTime: updated[i].endTime,
                            classId: updated[i].classId,
                            subject: updated[i].subject,
                            teacherName: updated[i].teacherName,
                          );
                        }
                        Navigator.pop(context);
                        _saveScheduleDay(
                            gsMap[selectedGS]!, dayOfWeek, updated);
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                            color: danger.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: danger.withOpacity(0.2))),
                        child: Center(
                            child: Text('Remove',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: danger))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Save button
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        final updated = List<PeriodSlot>.from(allPeriods);
                        final newSlot = PeriodSlot(
                          period: slot.period,
                          startTime: startCtrl.text.trim(),
                          endTime: endCtrl.text.trim(),
                          classId: selectedClassId,
                          subject: selectedSubject,
                          teacherName: selectedTeacher,
                        );
                        if (index < updated.length) {
                          updated[index] = newSlot;
                        } else {
                          updated.add(newSlot);
                        }
                        Navigator.pop(context);
                        _saveScheduleDay(
                            gsMap[selectedGS]!, dayOfWeek, updated);
                      },
                      child: Container(
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
                            child: Text('Save',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                      ),
                    ),
                  ),
                ]),
              ],
            )),
          ),
        );
      }),
    );
  }

  InputDecoration _scheduleFieldDecor(String label, String hint) =>
      InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            fontFamily: 'Raleway', fontSize: 12, color: textLight),
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Raleway', fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      );

  void _saveScheduleDay(
      Map<String, String> gs, int dayOfWeek, List<PeriodSlot> periods) async {
    try {
      await _api.upsertSchedule(
        grade: gs['grade']!,
        section: gs['section']!,
        dayOfWeek: dayOfWeek,
        periods: periods.map((p) => p.toMap()).toList(),
      );
      _calLoaded = false;
      _loadCalendar();
      _snack('Schedule saved');
    } catch (e) {
      debugPrint('Save schedule error: $e');
      _snack('Failed to save schedule');
    }
  }

  String _defaultStartTime(int index) {
    final hour = 8 + (index * 50) ~/ 60;
    final minute = (index * 50) % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _defaultEndTime(int index) {
    final startMinutes = 8 * 60 + index * 50;
    final endMinutes = startMinutes + 45;
    final hour = endMinutes ~/ 60;
    final minute = endMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // ─── GRADES TAB ────────────────────────────────────────────────────────────
  String _gradeSelectedClassId = '';
  String _gradeSearch = '';

  Widget _buildGradesTab() {
    // Selected class
    final selClass = _classes.firstWhere(
        (c) => c.id == _gradeSelectedClassId,
        orElse: () => _classes.isNotEmpty ? _classes.first : ClassModel.empty());
    if (_gradeSelectedClassId.isEmpty && _classes.isNotEmpty) {
      _gradeSelectedClassId = selClass.id;
    }

    // Filtered grades for selected class
    final classGrades = _allGrades
        .where((g) => g.classId == _gradeSelectedClassId)
        .toList();
    final query = _gradeSearch.toLowerCase();
    final filteredGrades = query.isEmpty
        ? classGrades
        : classGrades.where((g) =>
            g.studentName.toLowerCase().contains(query) ||
            g.assessmentName.toLowerCase().contains(query)).toList();
    filteredGrades.sort((a, b) => (b.createdAt ?? DateTime(2000))
        .compareTo(a.createdAt ?? DateTime(2000)));

    // Students in selected class
    final classStudentUids =
        (selClass.studentUids);
    final classStudents = _allSchoolStudents
        .where((s) => classStudentUids.contains(s.uid))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

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
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 60,
              child: Text(selClass.name.isNotEmpty
                  ? '${selClass.name} · ${selClass.subject}'
                  : 'Select a class',
                  style: const TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 16),
          // Class selector chips
          if (_classes.length > 1)
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _classes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cls = _classes[i];
                  final isActive = cls.id == _gradeSelectedClassId;
                  final colors = [primary, info, accent, purple, success];
                  final c = colors[cls.subject.hashCode.abs() % colors.length];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _gradeSelectedClassId = cls.id;
                      _gradeSearch = '';
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: isActive ? c.withOpacity(0.12) : bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isActive ? c : Colors.grey.shade200,
                              width: isActive ? 1.5 : 1)),
                      child: Center(
                          child: Text(cls.subject,
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? c : textLight))),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(children: [
              Icon(Icons.search_rounded, size: 18, color: textLight),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _gradeSearch = v),
                  style: const TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textDark),
                  decoration: InputDecoration(
                    hintText: 'Search student or test...',
                    hintStyle: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: textLight.withOpacity(0.5)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          // Stats row
          Row(children: [
            _gradeStatChip('${classGrades.length}', 'Grades', primary),
            const SizedBox(width: 8),
            _gradeStatChip('${classStudents.length}', 'Students', info),
            const SizedBox(width: 8),
            if (classGrades.isNotEmpty)
              _gradeStatChip(
                  '${(classGrades.fold<double>(0, (s, g) => s + g.percentage) / classGrades.length).round()}%',
                  'Avg',
                  classGrades.fold<double>(0, (s, g) => s + g.percentage) / classGrades.length >= 70
                      ? success
                      : accent),
            const Spacer(),
            // Test Titles manager
            GestureDetector(
              onTap: () => _showTestTitlesManager(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: purple.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: purple.withOpacity(0.15))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.list_alt_rounded, size: 14, color: purple),
                  const SizedBox(width: 4),
                  Text('Tests',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: purple)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Add Grade button
          GestureDetector(
            onTap: () => _showGradeEntrySheet(
              classId: _gradeSelectedClassId,
              subject: selClass.subject,
              students: classStudents,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withOpacity(0.15))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.add_rounded, color: primary, size: 18),
                const SizedBox(width: 6),
                Text('Add Grade',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: primary)),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          // Grade list
          if (filteredGrades.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.grade_outlined,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Text('No grades yet',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 14,
                          color: Colors.grey.shade400)),
                  const SizedBox(height: 4),
                  Text('Tap + to add grades for students',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: Colors.grey.shade300)),
                ]),
              ),
            )
          else
            ...filteredGrades.asMap().entries.map((e) {
              final g = e.value;
              final pct = g.total > 0 ? g.score / g.total : 0.0;
              final c = pct >= 0.9
                  ? success
                  : pct >= 0.7
                      ? accent
                      : danger;
              return StaggeredItem(
                  index: e.key,
                  child: GestureDetector(
                    onTap: () => _showGradeEntrySheet(
                      classId: _gradeSelectedClassId,
                      subject: selClass.subject,
                      students: classStudents,
                      existingGrade: g,
                    ),
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
                            child: Text(
                                g.studentName.isNotEmpty
                                    ? g.studentName[0]
                                    : '?',
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
                        Container(
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
                                    color: c))),
                      ]),
                    ),
                  ));
            }),
        ]));
  }

  Widget _gradeStatChip(String value, String label, Color c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: c.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: c)),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 10,
                color: c.withOpacity(0.7))),
      ]),
    );
  }

  void _showGradeEntrySheet({
    required String classId,
    required String subject,
    required List<UserModel> students,
    GradeModel? existingGrade,
  }) {
    final isEdit = existingGrade != null;
    String selectedStudentUid = existingGrade?.studentUid ?? '';
    String selectedStudentName = existingGrade?.studentName ?? '';
    final scoreCtrl = TextEditingController(
        text: isEdit ? existingGrade.score.toInt().toString() : '');
    final totalCtrl = TextEditingController(
        text: isEdit ? existingGrade.total.toInt().toString() : '100');
    final assessCtrl = TextEditingController(
        text: existingGrade?.assessmentName ?? '');
    String assessQuery = existingGrade?.assessmentName ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        // Autocomplete suggestions from test titles
        final suggestions = assessQuery.isEmpty
            ? <Map<String, dynamic>>[]
            : _testTitles.where((t) {
                final title = (t['title'] as String? ?? '').toLowerCase();
                return title.contains(assessQuery.toLowerCase()) &&
                    title != assessQuery.toLowerCase();
              }).toList();

        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            decoration: const BoxDecoration(
                color: bgCard,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
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
                    Text(isEdit ? 'Edit Grade' : 'Add Grade',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    const SizedBox(height: 4),
                    Text(subject,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textLight)),
                    const SizedBox(height: 20),

                    // Student selector
                    const Text('Student',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textLight)),
                    const SizedBox(height: 6),
                    if (isEdit)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(selectedStudentName,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                color: textDark)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedStudentUid.isEmpty
                                ? null
                                : selectedStudentUid,
                            hint: Text('Select student',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: textLight.withOpacity(0.5))),
                            isExpanded: true,
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                color: textDark),
                            items: students
                                .map((s) => DropdownMenuItem(
                                    value: s.uid,
                                    child: Text(s.name)))
                                .toList(),
                            onChanged: (v) => setSheet(() {
                              selectedStudentUid = v ?? '';
                              selectedStudentName = students
                                  .firstWhere((s) => s.uid == v,
                                      orElse: () => students.first)
                                  .name;
                            }),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Assessment name with auto-complete
                    const Text('Test / Assessment',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textLight)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: assessCtrl,
                      onChanged: (v) =>
                          setSheet(() => assessQuery = v),
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 14,
                          color: textDark),
                      decoration: InputDecoration(
                        hintText: 'e.g. Unit Test 1, Mid-Term',
                        hintStyle: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 13,
                            color: textLight.withOpacity(0.5)),
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                    ),
                    // Auto-complete dropdown
                    if (suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: suggestions.take(5).map((t) {
                              final title = t['title'] as String? ?? '';
                              final ttTotal = (t['total'] as num?)?.toDouble() ?? 100;
                              return GestureDetector(
                                onTap: () => setSheet(() {
                                  assessCtrl.text = title;
                                  assessQuery = title;
                                  totalCtrl.text = ttTotal.toInt().toString();
                                }),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: Colors.grey.shade100,
                                              width: 0.5))),
                                  child: Row(children: [
                                    Icon(Icons.history_rounded,
                                        size: 14, color: textLight),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(title,
                                            style: const TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 13,
                                                color: textDark))),
                                    Text('/${ ttTotal.toInt()}',
                                        style: const TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 11,
                                            color: textLight)),
                                  ]),
                                ),
                              );
                            }).toList()),
                      ),
                    // Quick-pick chips from test titles
                    if (assessQuery.isEmpty && _testTitles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _testTitles.take(8).map((t) {
                            final title = t['title'] as String? ?? '';
                            final ttTotal = (t['total'] as num?)?.toDouble() ?? 100;
                            return GestureDetector(
                              onTap: () => setSheet(() {
                                assessCtrl.text = title;
                                assessQuery = title;
                                totalCtrl.text = ttTotal.toInt().toString();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                    color: info.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: info.withOpacity(0.15))),
                                child: Text(title,
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: info)),
                              ),
                            );
                          }).toList()),
                    ],
                    const SizedBox(height: 16),

                    // Score & Total row
                    Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Score',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textLight)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: scoreCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                      color: textLight.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: bg,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                            ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 22),
                        child: Text(' / ',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textLight)),
                      ),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textLight)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: totalCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textDark),
                                decoration: InputDecoration(
                                  hintText: '100',
                                  hintStyle: TextStyle(
                                      color: textLight.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: bg,
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                ),
                              ),
                            ]),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(children: [
                      if (isEdit)
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              Navigator.pop(ctx);
                              try {
                                await _api.deleteGrade(existingGrade.id);
                                _allGrades.removeWhere(
                                    (g) => g.id == existingGrade.id);
                                setState(() {});
                                _snack('Grade deleted');
                              } catch (e) {
                                _snack('Failed to delete');
                              }
                            },
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  color: danger.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: danger.withOpacity(0.2))),
                              child: Center(
                                  child: Text('Delete',
                                      style: TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: danger))),
                            ),
                          ),
                        ),
                      if (isEdit) const SizedBox(width: 12),
                      Expanded(
                        flex: isEdit ? 2 : 1,
                        child: GestureDetector(
                          onTap: () async {
                            if (selectedStudentUid.isEmpty) {
                              _snack('Select a student');
                              return;
                            }
                            if (assessCtrl.text.trim().isEmpty) {
                              _snack('Enter a test name');
                              return;
                            }
                            Navigator.pop(ctx);
                            try {
                              final assessName = assessCtrl.text.trim();
                              final score = double.tryParse(
                                      scoreCtrl.text.trim()) ??
                                  0;
                              final total = double.tryParse(
                                      totalCtrl.text.trim()) ??
                                  100;
                              await _api.enterGrade(
                                studentUid: selectedStudentUid,
                                classId: classId,
                                subject: subject,
                                assessmentName: assessName,
                                studentName: selectedStudentName,
                                score: score,
                                total: total,
                              );
                              // Auto-add to test titles master list
                              if (!_testTitles.any((t) =>
                                  (t['title'] as String? ?? '')
                                      .toLowerCase() ==
                                  assessName.toLowerCase())) {
                                await _api.addTestTitle(
                                    title: assessName,
                                    subject: subject,
                                    total: total);
                              }
                              await _loadUser();
                              _snack(isEdit
                                  ? 'Grade updated'
                                  : 'Grade saved');
                            } catch (e) {
                              _snack('Failed: $e');
                            }
                          },
                          child: Container(
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
                            child: Center(
                                child: Text(
                                    isEdit ? 'Update' : 'Save',
                                    style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                          ),
                        ),
                      ),
                    ]),
                  ]),
            ),
          ),
        );
      }),
    );
  }

  void _showTestTitlesManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheet) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          decoration: const BoxDecoration(
              color: bgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
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
                const Text('Saved Test Titles',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark)),
                const SizedBox(height: 4),
                const Text(
                    'These appear as suggestions when entering grades',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: textLight)),
                const SizedBox(height: 16),
                if (_testTitles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                        child: Text('No saved test titles yet',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: Colors.grey.shade400))),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _testTitles.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final t = _testTitles[i];
                        final title = t['title'] as String? ?? '';
                        final ttSubject = t['subject'] as String? ?? '';
                        final ttTotal =
                            (t['total'] as num?)?.toInt() ?? 100;
                        final ttId = t['id'] as String? ?? '';
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(children: [
                            Icon(Icons.description_outlined,
                                size: 16, color: purple),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(title,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: textDark)),
                                  if (ttSubject.isNotEmpty)
                                    Text(
                                        '$ttSubject · /$ttTotal',
                                        style: const TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 11,
                                            color: textLight)),
                                ])),
                            GestureDetector(
                              onTap: () async {
                                if (ttId.isEmpty) return;
                                try {
                                  await _api.deleteTestTitle(ttId);
                                  setSheet(() {
                                    _testTitles.removeWhere((tt) =>
                                        tt['id'] == ttId);
                                  });
                                  setState(() {});
                                  _snack('"$title" removed');
                                } catch (e) {
                                  _snack('Failed to delete');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: danger.withOpacity(0.06),
                                    shape: BoxShape.circle),
                                child: Icon(Icons.close_rounded,
                                    size: 14, color: danger),
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
              ]),
        );
      }),
    );
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
    final color = accent;
    return StaggeredItem(
      index: idx,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
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
                  child: Icon(Icons.assignment_outlined,
                      color: color, size: 18)),
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
                    Text('${hw.className} · ${hw.subject}',
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 11,
                            color: textLight)),
                  ])),
              GestureDetector(
                onTap: () => _deleteHomework(hw),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: danger.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.delete_outline_rounded,
                      color: danger.withOpacity(0.5), size: 16),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (hw.description.isNotEmpty)
                Text(hw.description,
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: textMid,
                        height: 1.5)),
              if (hw.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: hw.attachments.map((a) {
                  IconData icon;
                  Color c;
                  switch (a.type) {
                    case 'pdf':
                      icon = Icons.picture_as_pdf_rounded;
                      c = danger;
                    case 'image':
                      icon = Icons.image_rounded;
                      c = info;
                    default:
                      icon = Icons.link_rounded;
                      c = primary;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: c.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.withOpacity(0.15))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 14, color: c),
                      const SizedBox(width: 4),
                      Text(a.name.isNotEmpty ? a.name : 'Attachment',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: c)),
                    ]),
                  );
                }).toList()),
              ],
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
              if (subs > 0) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _showSubmissions(hw),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                        color: info.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: info.withOpacity(0.15))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.visibility_rounded,
                              size: 14, color: info),
                          const SizedBox(width: 6),
                          Text('View $subs Submission${subs > 1 ? 's' : ''}',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: info)),
                        ]),
                  ),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  void _showSubmissions(HomeworkModel hw) async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _api.getHomeworkSubmissions(hw.id),
          builder: (ctx, snap) {
            final subs = snap.data ?? [];
            return Column(
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
                  const SizedBox(height: 16),
                  Text('Submissions — ${hw.title}',
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                  const SizedBox(height: 4),
                  Text('${subs.length} student${subs.length != 1 ? 's' : ''} submitted',
                      style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: textLight)),
                  const SizedBox(height: 16),
                  if (snap.connectionState == ConnectionState.waiting)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (subs.isEmpty)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No submissions yet',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    color: textLight))))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: subs.length,
                        itemBuilder: (_, i) {
                          final s = subs[i];
                          final files =
                              (s['files'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                          final name = s['studentName'] as String? ?? 'Student';
                          final note = s['note'] as String? ?? '';
                          final at = s['submittedAt'] as String?;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade100)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(
                                        radius: 14,
                                        backgroundColor:
                                            info.withOpacity(0.1),
                                        child: Text(
                                            name.isNotEmpty
                                                ? name[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: info))),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(name,
                                            style: const TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: textDark))),
                                    if (at != null)
                                      Text(
                                          _submissionTimeLabel(at),
                                          style: const TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 10,
                                              color: textLight)),
                                  ]),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(note,
                                        style: const TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 12,
                                            color: textMid)),
                                  ],
                                  if (files.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: files.map((f) {
                                          final fType =
                                              f['type'] as String? ?? 'document';
                                          final fName =
                                              f['name'] as String? ?? 'File';
                                          final ic = fType == 'pdf'
                                              ? Icons.picture_as_pdf_rounded
                                              : fType == 'image'
                                                  ? Icons.image_rounded
                                                  : Icons.insert_drive_file_rounded;
                                          final fc = fType == 'pdf'
                                              ? danger
                                              : fType == 'image'
                                                  ? info
                                                  : accent;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: fc.withOpacity(0.06),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color:
                                                        fc.withOpacity(0.15))),
                                            child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Icon(ic,
                                                      size: 13, color: fc),
                                                  const SizedBox(width: 4),
                                                  Text(fName,
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'Raleway',
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: fc)),
                                                ]),
                                          );
                                        }).toList()),
                                  ],
                                ]),
                          );
                        },
                      ),
                    ),
                ]);
          },
        ),
      ),
    );
  }

  String _submissionTimeLabel(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  void _deleteHomework(HomeworkModel hw) {
    if (hw.id.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete homework?',
            style: TextStyle(fontFamily: 'Raleway', fontSize: 16)),
        content: Text(hw.title,
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.deleteHomework(hw.id);
                setState(() => _homework.removeWhere((h) => h.id == hw.id));
                _snack('Homework deleted');
              } catch (_) {
                _snack('Failed to delete');
              }
            },
            child: Text('Delete', style: TextStyle(color: danger)),
          ),
        ],
      ),
    );
  }

  void _showPostHomeworkSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedClassId = _classes[0].id;
    String selectedClassName = _classes[0].name;
    String selectedSubject = _classes[0].subject;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    final attachments = <HomeworkAttachment>[];
    final pickedFiles = <MapEntry<String, Uint8List>>[];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: SingleChildScrollView(
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
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textDark),
                        items: _classes
                            .map((c) => DropdownMenuItem<String>(
                                  value: c.id,
                                  child: Text('${c.subject} — ${c.name}',
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 14,
                                          color: textDark)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          final cls = _classes.firstWhere((c) => c.id == v);
                          setModal(() {
                            selectedClassId = v;
                            selectedClassName = cls.name;
                            selectedSubject = cls.subject;
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
                    decoration: _hwFieldDecor('Assignment title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 14, color: textDark),
                    decoration: _hwFieldDecor('Instructions for students...'),
                  ),
                  const SizedBox(height: 12),
                  // Due date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (ctx2, child) => Theme(
                          data: Theme.of(ctx2).copyWith(
                              colorScheme: ColorScheme.light(primary: accent)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setModal(() => dueDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200)),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 16, color: textLight),
                        const SizedBox(width: 8),
                        Text(
                            'Due: ${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                color: textDark)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Attachments
                  const Text('Attachments',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textLight)),
                  const SizedBox(height: 8),
                  ...attachments.asMap().entries.map((e) {
                    final a = e.value;
                    final i = e.key;
                    IconData icon;
                    Color c;
                    switch (a.type) {
                      case 'pdf':
                        icon = Icons.picture_as_pdf_rounded;
                        c = danger;
                      case 'image':
                        icon = Icons.image_rounded;
                        c = info;
                      default:
                        icon = Icons.link_rounded;
                        c = primary;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: c.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.withOpacity(0.15))),
                      child: Row(children: [
                        Icon(icon, size: 16, color: c),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.name.isNotEmpty ? a.name : a.url,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: c)),
                                if (a.name.isNotEmpty)
                                  Text(a.url,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 10,
                                          color: textLight)),
                              ]),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setModal(() => attachments.removeAt(i)),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: textLight),
                        ),
                      ]),
                    );
                  }),
                  // Picked files preview
                  ...pickedFiles.asMap().entries.map((e) {
                    final f = e.value;
                    final ext = f.key.split('.').last.toLowerCase();
                    final isImg = ['jpg', 'jpeg', 'png', 'gif', 'webp']
                        .contains(ext);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: (isImg ? info : danger).withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: (isImg ? info : danger)
                                  .withOpacity(0.15))),
                      child: Row(children: [
                        Icon(
                            isImg
                                ? Icons.image_rounded
                                : Icons.picture_as_pdf_rounded,
                            size: 16,
                            color: isImg ? info : danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isImg ? info : danger)),
                        ),
                        Text(
                            '${(f.value.length / 1024).toStringAsFixed(0)} KB',
                            style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 10,
                                color: textLight)),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () =>
                              setModal(() => pickedFiles.removeAt(e.key)),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: textLight),
                        ),
                      ]),
                    );
                  }),
                  Row(children: [
                    _attachBtn('Upload\nFiles', Icons.upload_file_rounded,
                        accent, () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                        type: FileType.custom,
                        allowedExtensions: [
                          'pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp',
                          'docx', 'xlsx', 'pptx'
                        ],
                        withData: true,
                      );
                      if (result == null) return;
                      setModal(() {
                        for (final f in result.files) {
                          if (f.bytes != null) {
                            pickedFiles.add(
                                MapEntry(f.name, f.bytes!));
                          }
                        }
                      });
                    }),
                    const SizedBox(width: 8),
                    _attachBtn('Add\nLink', Icons.link_rounded, primary,
                        () => _addAttachment(setModal, attachments, 'link')),
                  ]),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty) return;
                            setModal(() => isSubmitting = true);
                            final dueDateStr =
                                '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
                            final resp = await _api.createHomework(
                              title: title,
                              classId: selectedClassId,
                              description: descCtrl.text.trim(),
                              subject: selectedSubject,
                              className: selectedClassName,
                              dueDate: dueDateStr,
                              attachments:
                                  attachments.map((a) => a.toMap()).toList(),
                            );
                            final newId = resp['id'] as String? ?? '';

                            List<HomeworkAttachment> uploadedAtts = [
                              ...attachments
                            ];
                            if (pickedFiles.isNotEmpty && newId.isNotEmpty) {
                              final uploaded =
                                  await _api.uploadHomeworkFiles(
                                      newId, pickedFiles);
                              for (final u in uploaded) {
                                uploadedAtts.add(HomeworkAttachment(
                                  url: u['url'] as String? ?? '',
                                  name: u['name'] as String? ?? '',
                                  type: u['type'] as String? ?? 'document',
                                ));
                              }
                            }

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            setState(() => _homework.insert(
                                0,
                                HomeworkModel(
                                  id: newId,
                                  title: title,
                                  description: descCtrl.text.trim(),
                                  subject: selectedSubject,
                                  classId: selectedClassId,
                                  className: selectedClassName,
                                  teacherUid: _uid,
                                  teacherName: _user?.name ?? '',
                                  dueDate: dueDateStr,
                                  attachments: uploadedAtts,
                                  createdAt: DateTime.now(),
                                )));
                            _snack('Homework posted!');
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
                      child: Center(
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white))
                              : const Text('Post Homework',
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
      ),
    );
  }

  InputDecoration _hwFieldDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Raleway', fontSize: 13, color: Colors.grey.shade400),
        filled: true,
        fillColor: bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: accent.withOpacity(0.5), width: 1.5)),
      );

  Widget _attachBtn(
          String label, IconData icon, Color c, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
                color: c.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.withOpacity(0.2))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c)),
            ]),
          ),
        ),
      );

  void _addAttachment(StateSetter setModal,
      List<HomeworkAttachment> attachments, String type) {
    final urlCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            'Add ${type == 'pdf' ? 'PDF' : type == 'image' ? 'Image' : 'Link'}',
            style:
                const TextStyle(fontFamily: 'Raleway', fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: urlCtrl,
            autofocus: true,
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14),
            decoration: InputDecoration(
              hintText: type == 'link'
                  ? 'https://...'
                  : type == 'pdf'
                      ? 'PDF URL'
                      : 'Image URL',
              hintStyle: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameCtrl,
            style: const TextStyle(fontFamily: 'Raleway', fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Display name (optional)',
              hintStyle: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  color: Colors.grey.shade400),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isEmpty) return;
              Navigator.pop(ctx);
              setModal(() => attachments.add(HomeworkAttachment(
                    url: url,
                    name: nameCtrl.text.trim(),
                    type: type,
                  )));
            },
            child: const Text('Add'),
          ),
        ],
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
                if (_classes.length > 1)
                  StatefulBuilder(builder: (ctx2, setSheet) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textLight)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200)),
                            child: DropdownButton<String>(
                              value: _storySelectedClassId.isNotEmpty &&
                                      _classes.any((c) => c.id == _storySelectedClassId)
                                  ? _storySelectedClassId
                                  : (_classes.isNotEmpty ? _classes.first.id : null),
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                  fontFamily: 'Raleway', fontSize: 14, color: Color(0xFF1A2E22)),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B8F76)),
                              items: _classes
                                  .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text('${c.subject} — ${c.name}',
                                          style: const TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 14,
                                              color: Color(0xFF1A2E22)))))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setSheet(() => _storySelectedClassId = v);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ]);
                  }),
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
                    final selId = _storySelectedClassId.isNotEmpty
                        ? _storySelectedClassId
                        : (_classes.isNotEmpty ? _classes.first.id : '');
                    final selCls = _classes.cast<ClassModel?>().firstWhere(
                        (c) => c!.id == selId,
                        orElse: () => _classes.isNotEmpty ? _classes.first : null);
                    final classId = selCls?.id ?? '';
                    final className = selCls?.name ?? '';
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
