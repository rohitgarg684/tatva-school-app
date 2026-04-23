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

  // ── FAKE DATA ──────────────────────────────────────────────────────────────
  final String userName = 'Mrs. Priya Sharma';
  final String userEmail = 'priya.sharma@tatva.edu';

  final List<Map<String, dynamic>> _classes = [
    {
      'classId': 'c1',
      'name': 'Grade 8 — Section A',
      'subject': 'Mathematics',
      'classCode': 'MATH312',
      'studentUids': ['s1', 's2', 's3', 's4', 's5'],
      'parentUids': ['p1', 'p2', 'p3', 'p4'],
    },
    {
      'classId': 'c2',
      'name': 'Grade 8 — Section B',
      'subject': 'Mathematics',
      'classCode': 'MATH498',
      'studentUids': ['s6', 's7', 's8', 's9', 's10', 's11'],
      'parentUids': ['p5', 'p6', 'p7'],
    },
    {
      'classId': 'c3',
      'name': 'Grade 7 — Section A',
      'subject': 'Mathematics',
      'classCode': 'MATH201',
      'studentUids': ['s12', 's13', 's14', 's15'],
      'parentUids': ['p8', 'p9'],
    },
  ];

  final List<Map<String, dynamic>> _students = [
    {
      'uid': 's1',
      'name': 'Arjun Mehta',
      'email': 'arjun@tatva.edu',
      'classId': 'c1'
    },
    {
      'uid': 's2',
      'name': 'Sneha Agarwal',
      'email': 'sneha@tatva.edu',
      'classId': 'c1'
    },
    {
      'uid': 's3',
      'name': 'Ravi Kumar',
      'email': 'ravi@tatva.edu',
      'classId': 'c1'
    },
    {
      'uid': 's4',
      'name': 'Divya Pillai',
      'email': 'divya@tatva.edu',
      'classId': 'c1'
    },
    {
      'uid': 's5',
      'name': 'Karan Singh',
      'email': 'karan@tatva.edu',
      'classId': 'c1'
    },
  ];

  final List<Map<String, dynamic>> _grades = [
    {
      'studentUid': 's1',
      'studentName': 'Arjun Mehta',
      'assessmentName': 'Unit Test 3',
      'subject': 'Mathematics',
      'score': 46.0,
      'total': 50.0,
      'classId': 'c1'
    },
    {
      'studentUid': 's2',
      'studentName': 'Sneha Agarwal',
      'assessmentName': 'Unit Test 3',
      'subject': 'Mathematics',
      'score': 42.0,
      'total': 50.0,
      'classId': 'c1'
    },
    {
      'studentUid': 's3',
      'studentName': 'Ravi Kumar',
      'assessmentName': 'Unit Test 3',
      'subject': 'Mathematics',
      'score': 34.0,
      'total': 50.0,
      'classId': 'c1'
    },
    {
      'studentUid': 's4',
      'studentName': 'Divya Pillai',
      'assessmentName': 'Unit Test 3',
      'subject': 'Mathematics',
      'score': 45.0,
      'total': 50.0,
      'classId': 'c1'
    },
    {
      'studentUid': 's5',
      'studentName': 'Karan Singh',
      'assessmentName': 'Unit Test 3',
      'subject': 'Mathematics',
      'score': 37.0,
      'total': 50.0,
      'classId': 'c1'
    },
  ];

  final List<Map<String, dynamic>> _announcements = [
    {
      'title': 'Term 2 Exam Timetable',
      'body':
          'Final exams begin December 10. Please ensure students are prepared.',
      'audience': 'Students',
      'createdByName': 'Mrs. Priya Sharma'
    },
    {
      'title': 'PTM — December 5',
      'body':
          'Parent-Teacher Meeting scheduled 10 AM – 1 PM. Confirm slots via the app.',
      'audience': 'Parents',
      'createdByName': 'Mrs. Priya Sharma'
    },
    {
      'title': 'Holiday Homework Uploaded',
      'body': 'Winter break assignments are now live on the class board.',
      'audience': 'Everyone',
      'createdByName': 'Mrs. Priya Sharma'
    },
  ];

  final List<Map<String, dynamic>> _parents = [
    {
      'uid': 'p1',
      'name': 'Mr. Suresh Mehta',
      'email': 'suresh@gmail.com',
      'childName': 'Arjun Mehta',
      'role': 'Parent'
    },
    {
      'uid': 'p2',
      'name': 'Mrs. Lata Agarwal',
      'email': 'lata@gmail.com',
      'childName': 'Sneha Agarwal',
      'role': 'Parent'
    },
    {
      'uid': 'p3',
      'name': 'Mr. Vijay Kumar',
      'email': 'vijay@gmail.com',
      'childName': 'Ravi Kumar',
      'role': 'Parent'
    },
    {
      'uid': 'p4',
      'name': 'Mrs. Asha Pillai',
      'email': 'asha@gmail.com',
      'childName': 'Divya Pillai',
      'role': 'Parent'
    },
  ];

  // ── HOMEWORK DATA ──────────────────────────────────────────────────────────
  late List<Map<String, dynamic>> _homework;

  @override
  void initState() {
    super.initState();
    _homework = [
      {
        'id': 'hw1',
        'title': 'Algebra Practice — Chapter 6',
        'description':
            'Complete exercises 6.1 to 6.5 from the textbook. Show all working clearly.',
        'classId': 'c1',
        'className': 'Grade 8 — Section A',
        'dueDate': 'Dec 12, 2024',
        'totalMarks': 20,
        'subject': 'Mathematics',
        'submissions': ['s1', 's3'],
        'totalStudents': 5,
        'status': 'active',
      },
      {
        'id': 'hw2',
        'title': 'Geometry Worksheet — Triangles',
        'description':
            'Solve all problems on the printed worksheet and bring it to class.',
        'classId': 'c1',
        'className': 'Grade 8 — Section A',
        'dueDate': 'Dec 9, 2024',
        'totalMarks': 15,
        'subject': 'Mathematics',
        'submissions': ['s1', 's2', 's4', 's5'],
        'totalStudents': 5,
        'status': 'active',
      },
      {
        'id': 'hw3',
        'title': 'Fractions — Mixed Numbers',
        'description':
            'Practice adding and subtracting mixed fractions. Pages 44–46.',
        'classId': 'c2',
        'className': 'Grade 8 — Section B',
        'dueDate': 'Dec 10, 2024',
        'totalMarks': 10,
        'subject': 'Mathematics',
        'submissions': ['s6', 's7', 's8', 's9'],
        'totalStudents': 6,
        'status': 'active',
      },
      {
        'id': 'hw4',
        'title': 'Unit Test 2 Revision',
        'description':
            'Revise chapters 4 and 5. Focus on word problems and graphs.',
        'classId': 'c3',
        'className': 'Grade 7 — Section A',
        'dueDate': 'Dec 8, 2024',
        'totalMarks': 25,
        'subject': 'Mathematics',
        'submissions': ['s12', 's13', 's14', 's15'],
        'totalStudents': 4,
        'status': 'completed',
      },
    ];

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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => isLoading = false);
    _greetingController.forward();
    _cardsController.forward();
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

  void _showAddStudentOptions(String classId, List existingStudentUids) {
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
                    excludeStudentIds: existingStudentUids.cast<String>(),
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
                            final result = await ClassService().createClass(
                              name: nameCtrl.text.trim(),
                              subject: subjectCtrl.text.trim(),
                            );
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (result != null) {
                              _snack('Class "${result.name}" created! Code: ${result.classCode}');
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
            _buildGradesTab(),
            _buildHomeworkTab(),
            _buildAnnouncementsTab(),
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
        'icon': Icons.campaign_outlined,
        'active': Icons.campaign_rounded,
        'label': 'Posts'
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
        _classes.fold(0, (sum, c) => sum + (c['studentUids'] as List).length);
    final activeHw = _homework.where((h) => h['status'] == 'active').length;
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
                    () => _switchTab(2)),
                const SizedBox(width: 8),
                _qaBtn('Post\nHomework', Icons.assignment_outlined, primary,
                    () => _switchTab(3)),
                const SizedBox(width: 8),
                _qaBtn('Announce', Icons.campaign_outlined, info,
                    () => _switchTab(4)),
                const SizedBox(width: 8),
                _qaBtn('Messages', Icons.chat_outlined, purple,
                    () => _switchTab(5)),
              ])),
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
                                text: userName,
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
                          initial: userName[0],
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

  Widget _classCard(Map<String, dynamic> c, int index) {
    final studentCount = (c['studentUids'] as List).length;
    final parentCount = (c['parentUids'] as List).length;
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
                      Text(c['name'],
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                      Text(c['subject'],
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
                    child: Text(c['classCode'],
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
                      onTap: () => _showAddStudentOptions(c['classId'], c['studentUids'] as List),
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
                      onTap: () => _switchTab(2),
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
            final pct = (g['score'] as double) / (g['total'] as double);
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
                        child: Text((g['studentName'] as String)[0],
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
                          Text(g['studentName'],
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: textDark)),
                          Text(g['assessmentName'],
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
                                '${(g['score'] as double).toInt()}/${(g['total'] as double).toInt()}',
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
    final active = _homework.where((h) => h['status'] == 'active').toList();
    final done = _homework.where((h) => h['status'] == 'completed').toList();
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

  Widget _hwCard(Map<String, dynamic> hw, int idx) {
    final subs = (hw['submissions'] as List).length;
    final total = hw['totalStudents'] as int;
    final pct = total > 0 ? subs / total : 0.0;
    final isDone = hw['status'] == 'completed';
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
                    Text(hw['title'],
                        style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textDark)),
                    Text(hw['className'],
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
                  child: Text('${hw['totalMarks']} marks',
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
              Text(hw['description'],
                  style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: textMid,
                      height: 1.5)),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: textLight),
                const SizedBox(width: 4),
                Text('Due ${hw['dueDate']}',
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
    String selectedClassId = _classes[0]['classId'] as String;
    String selectedClassName = _classes[0]['name'] as String;
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
                                  value: c['classId'] as String,
                                  child: Text(c['name'] as String,
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
                                (c) => c['classId'] == v)['name'] as String;
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
                    onTap: () {
                      final title = titleCtrl.text.trim();
                      if (title.isEmpty) return;
                      final marks = int.tryParse(marksCtrl.text.trim()) ?? 10;
                      final classStudents = (_classes.firstWhere((c) =>
                              c['classId'] ==
                              selectedClassId)['studentUids'] as List)
                          .length;
                      setState(() {
                        _homework.insert(0, {
                          'id': 'hw${DateTime.now().millisecondsSinceEpoch}',
                          'title': title,
                          'description': descCtrl.text.trim().isEmpty
                              ? 'No additional instructions.'
                              : descCtrl.text.trim(),
                          'classId': selectedClassId,
                          'className': selectedClassName,
                          'dueDate': 'Dec 20, 2024',
                          'totalMarks': marks,
                          'subject': 'Mathematics',
                          'submissions': [],
                          'totalStudents': classStudents,
                          'status': 'active',
                        });
                      });
                      Navigator.pop(context);
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

  // ─── ANNOUNCEMENTS TAB ─────────────────────────────────────────────────────
  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Announcements',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Posts visible to students and parents',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          const SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 80,
              child: GestureDetector(
                onTap: () =>
                    _snack('Post announcement — available in the live app!'),
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: info.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: info.withOpacity(0.2))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_rounded, color: info, size: 20),
                          const SizedBox(width: 8),
                          const Text('New Announcement',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: info))
                        ])),
              )),
          const SizedBox(height: 16),
          ..._announcements.asMap().entries.map((e) => StaggeredItem(
              index: e.key,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(e.value['audience'],
                              style: const TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: primary,
                                  fontWeight: FontWeight.w700))),
                      const SizedBox(height: 8),
                      Text(e.value['title'],
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textDark)),
                      const SizedBox(height: 4),
                      Text(e.value['body'],
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: textMid,
                              height: 1.5)),
                      const SizedBox(height: 6),
                      Text('By ${e.value['createdByName']}',
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              color: textLight)),
                    ]),
              ))),
        ]));
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
                                    otherUserId: p['uid'],
                                    otherUserName: p['name'],
                                    otherUserRole: 'Parent · ${p['childName']}',
                                    otherUserEmail: p['email'],
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
                                child: Text((p['name'] as String)[0],
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
                                  Text(p['name'],
                                      style: const TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textDark)),
                                  Text('Parent of ${p['childName']}',
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
                  initial: userName[0],
                  radius: 46,
                  bgColor: primary.withOpacity(0.1),
                  textColor: primary,
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
