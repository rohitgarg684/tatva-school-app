import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/announcement_model.dart';
import '../../models/class_model.dart';
import '../../models/grade_model.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../models/vote_model.dart';
import '../../repositories/announcement_repository.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/class_repository.dart';
import '../../repositories/grade_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/vote_repository.dart';
import '../../services/class_service.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/add_student_sheet.dart';
import '../../shared/widgets/logout_sheet.dart';
import '../../shared/animations/animations.dart';
import '../../core/router/app_router.dart';
import '../auth/welcome_screen.dart';
import '../messaging/messaging_screen.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({super.key});

  @override
  _PrincipalDashboardState createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  String userName = '';
  String userEmail = '';
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

  final ClassService _classService = ClassService();
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

  List<Map<String, dynamic>> gradesTrend = [];

  List<Map<String, dynamic>> teacherWorkload = [];

  List<Map<String, dynamic>> assignmentCompletion = [];

  List<Map<String, dynamic>> attendanceTrend = [];

  List<Map<String, dynamic>> subjectGrades = [];

  List<Map<String, dynamic>> parents = [];
  List<Map<String, dynamic>> demoVotes = [];

  int _teacherCount = 0;
  int _studentCount = 0;
  int _classCount = 0;
  List<AnnouncementModel> _announcementModels = [];

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
      final uid = AuthRepository().currentUid ?? 'principal_anjali';

      final user = await UserRepository().getUser(uid);
      if (user != null) {
        userName = user.name;
        userEmail = user.email;
      }

      _teacherCount = await UserRepository().countByRole(UserRole.teacher);
      _studentCount = await UserRepository().countByRole(UserRole.student);
      final allClasses = await ClassRepository().getAllClasses();
      _classCount = allClasses.length;

      final teacherModels =
          await UserRepository().getAllByRole(UserRole.teacher);
      final _colors = [success, info, accent, purple, danger, primary];
      teacherWorkload = teacherModels.asMap().entries.map((entry) {
        final t = entry.value;
        final teacherClasses =
            allClasses.where((c) => c.teacherUid == t.uid).toList();
        final studentCount = teacherClasses.fold<int>(
            0, (sum, c) => sum + c.studentUids.length);
        return {
          'name': t.name,
          'subject': teacherClasses.isNotEmpty
              ? teacherClasses.first.subject
              : 'N/A',
          'classes': teacherClasses.length,
          'students': studentCount,
          'submitted': 0,
          'graded': 0,
          'avatar': t.name.isNotEmpty ? t.name[0] : '?',
          'color': _colors[entry.key % _colors.length],
        };
      }).toList();

      final parentModels =
          await UserRepository().getAllByRole(UserRole.parent);
      parents = parentModels.asMap().entries.map((entry) {
        final p = entry.value;
        return {
          'name': p.name,
          'email': p.email,
          'child': p.children.isNotEmpty
              ? p.children.first['childName'] ?? ''
              : '',
          'class': p.children.isNotEmpty
              ? p.children.first['className'] ?? ''
              : '',
          'avatar': p.name.isNotEmpty ? p.name[0] : '?',
          'color': _colors[entry.key % _colors.length],
          'uid': p.uid,
        };
      }).toList();

      final allGrades = await GradeRepository().fetchAll();
      final subjectMap = <String, List<double>>{};
      for (final g in allGrades) {
        subjectMap.putIfAbsent(g.subject, () => []).add(g.percentage);
      }
      int colorIdx = 0;
      subjectGrades = subjectMap.entries.map((e) {
        final c = _colors[colorIdx % _colors.length];
        colorIdx++;
        return {
          'subject': e.key,
          'avg': e.value.isEmpty
              ? 0.0
              : e.value.reduce((a, b) => a + b) / e.value.length,
          'color': c,
        };
      }).toList();

      final annModels = await AnnouncementRepository().fetchAll();
      _announcementModels = annModels;

      final voteModels = await VoteRepository().fetchActive();
      demoVotes = voteModels.map((v) {
        return {
          'id': v.id,
          'question': v.question,
          'type': v.type,
          'votes': {
            'school': v.votes.school,
            'no_school': v.votes.noSchool,
            'undecided': v.votes.undecided,
          },
          'total': v.votes.total,
          'voters': v.voters,
          'active': v.active,
        };
      }).toList();
    } catch (_) {}
    if (!mounted) return;
    setState(() => isLoading = false);
    _greetingController.forward();
    _tabController.forward();
  }

  Future<void> _loadStudents() async {
    setState(() => _studentsLoading = true);
    final all = await _classService.getAllStudentRecords();
    if (!mounted) return;
    setState(() {
      _students = all;
      _filterStudents(_studentSearchCtrl.text);
      _studentsLoading = false;
    });
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

  Future<void> _logout() async {
    LogoutSheet.show(context, onConfirm: () async {
      await AuthRepository().signOut();
      if (context.mounted) {
        AppRouter.toWelcomeAndClearStack(context);
      }
    });
  }

  void _showCreateVote() {
    final questionController = TextEditingController();
    String selectedType = 'Weather Day';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                SizedBox(height: 20),
                Row(children: [
                  Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.how_to_vote_outlined,
                          color: purple, size: 18)),
                  SizedBox(width: 10),
                  Text('Create Parent Vote',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                ]),
                SizedBox(height: 4),
                Text('Parents will see this in their Announcements tab',
                    style: TextStyle(
                        fontFamily: 'Raleway', fontSize: 13, color: textLight)),
                SizedBox(height: 20),
                Text('Vote Type',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children:
                      ['Weather Day', 'Event', 'Policy', 'Other'].map((type) {
                    bool isSel = selectedType == type;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedType = type),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: isSel ? purple : bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: isSel ? purple : Colors.grey.shade200)),
                        child: Text(type,
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: isSel ? Colors.white : textLight,
                                fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Question',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                SizedBox(height: 8),
                TextField(
                  controller: questionController,
                  maxLines: 2,
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 14, color: textDark),
                  decoration: InputDecoration(
                    hintText:
                        'e.g. Should we cancel school tomorrow due to weather?',
                    hintStyle: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 12,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: bg,
                    contentPadding: EdgeInsets.all(14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: purple.withOpacity(0.5), width: 1.5)),
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: purple.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: purple.withOpacity(0.15))),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: purple, size: 15),
                    SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            'Parents vote: School · No School · Undecided. Results are live.',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 12,
                                color: textMid))),
                  ]),
                ),
                SizedBox(height: 20),
                BouncyTap(
                  onTap: () async {
                    if (questionController.text.trim().isEmpty) return;
                    final uid =
                        AuthRepository().currentUid ?? 'principal_anjali';
                    await VoteRepository().create(VoteModel(
                      id: '',
                      question: questionController.text.trim(),
                      type: selectedType.toLowerCase().replaceAll(' ', '_'),
                      createdBy: uid,
                      createdByName: userName,
                      createdByRole: 'Principal',
                    ));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadUser();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Vote sent to all parents!',
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
                        color: purple,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: purple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ]),
                    child: Center(
                        child: Text('Send Vote to All Parents',
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
    );
  }

  void _showNewAnnouncement() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String selectedAudience = 'Everyone';
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Container(
            decoration: BoxDecoration(
                color: bgCard,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                SizedBox(height: 20),
                Row(children: [
                  Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.campaign_outlined,
                          color: primary, size: 18)),
                  SizedBox(width: 10),
                  Text('New Announcement',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textDark)),
                ]),
                SizedBox(height: 20),
                Text('Send To',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                SizedBox(height: 8),
                Row(
                  children: ['Everyone', 'Parents Only', 'Teachers Only']
                      .map((audience) {
                    bool isSel = selectedAudience == audience;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setModalState(() => selectedAudience = audience),
                        child: Container(
                          margin: EdgeInsets.only(
                              right: audience != 'Teachers Only' ? 8 : 0),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                              color: isSel ? primary : bg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      isSel ? primary : Colors.grey.shade200)),
                          child: Center(
                              child: Text(audience,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 11,
                                      color: isSel ? Colors.white : textLight,
                                      fontWeight: FontWeight.w600))),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),
                Text('Title',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 14, color: textDark),
                  decoration: InputDecoration(
                    hintText: 'e.g. School Closure Notice',
                    hintStyle: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: bg,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                SizedBox(height: 14),
                Text('Message',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textDark)),
                SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 14, color: textDark),
                  decoration: InputDecoration(
                    hintText: 'Write your announcement here...',
                    hintStyle: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: Colors.grey.shade400),
                    filled: true,
                    fillColor: bg,
                    contentPadding: EdgeInsets.all(16),
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
                SizedBox(height: 20),
                BouncyTap(
                  onTap: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final uid =
                        AuthRepository().currentUid ?? 'principal_anjali';
                    await AnnouncementRepository().post(AnnouncementModel(
                      id: '',
                      title: titleController.text.trim(),
                      body: bodyController.text.trim(),
                      audience: selectedAudience,
                      createdBy: uid,
                      createdByName: userName,
                      createdByRole: 'Principal',
                    ));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _loadUser();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Announcement sent to $selectedAudience!',
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
                        color: primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ]),
                    child: Center(
                        child: Text('Send Announcement',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
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
            _buildOverviewTab(),
            _buildGradeTrendsTab(),
            _buildTeacherWorkloadTab(),
            _buildStudentsTab(),
            _buildCommunicateTab(),
            _buildProfileTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {
        'icon': Icons.dashboard_outlined,
        'activeIcon': Icons.dashboard_rounded,
        'label': 'Overview'
      },
      {
        'icon': Icons.show_chart_outlined,
        'activeIcon': Icons.show_chart_rounded,
        'label': 'Grades'
      },
      {
        'icon': Icons.people_outline,
        'activeIcon': Icons.people_rounded,
        'label': 'Teachers'
      },
      {
        'icon': Icons.school_outlined,
        'activeIcon': Icons.school_rounded,
        'label': 'Students'
      },
      {
        'icon': Icons.campaign_outlined,
        'activeIcon': Icons.campaign_rounded,
        'label': 'Communicate'
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
              offset: Offset(0, -6))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = _currentTab == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchTab(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? purple.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 200),
                          child: Icon(
                              isActive
                                  ? item['activeIcon'] as IconData
                                  : item['icon'] as IconData,
                              key: ValueKey(isActive),
                              color: isActive ? purple : textLight,
                              size: 20),
                        ),
                        SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: Duration(milliseconds: 250),
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 9,
                              color: isActive ? purple : textLight,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500),
                          child: Text(item['label'] as String),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ─── OVERVIEW TAB ────────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    final schoolAvg = subjectGrades.isNotEmpty
        ? subjectGrades.map((s) => s['avg'] as double).reduce((a, b) => a + b) /
            subjectGrades.length
        : 0.0;
    return RefreshIndicator(
      color: purple,
      onRefresh: _loadUser,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeTransition(
              opacity: _greetingFade,
              child: SlideTransition(
                position: _greetingSlide,
                child: ScaleTransition(
                    scale: _greetingScale, child: _buildGreetingCard()),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: FlipCard(
                        delayMs: 0,
                        child: _statCard(
                            '$_teacherCount', 'Teachers', Icons.people_outline, primary))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 100,
                        child: _statCard(
                            '$_studentCount', 'Students', Icons.school_outlined, info))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 200,
                        child: _statCard('${schoolAvg.toStringAsFixed(1)}%',
                            'Avg', Icons.bar_chart_rounded, success))),
              ]),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                    child: FlipCard(
                        delayMs: 300,
                        child: _statCard('—', 'Attendance',
                            Icons.check_circle_outline, accent))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 400,
                        child: _statCard(
                            '$_classCount', 'Classes', Icons.class_outlined, purple))),
                SizedBox(width: 10),
                Expanded(
                    child: FlipCard(
                        delayMs: 500,
                        child: _statCard(
                            '—', 'Tasks', Icons.assignment_outlined, danger))),
              ]),
            ),
            SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('School Grade Trend',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3)),
            ),
            SizedBox(height: 12),
            FadeSlideIn(
              delayMs: 200,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(children: [
                  _buildMiniLineChart(gradesTrend, 'avg', primary),
                  SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: gradesTrend
                          .map((d) => Text(d['month'],
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  color: textLight)))
                          .toList()),
                ]),
              ),
            ),
            SizedBox(height: 28),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('School-Wide Subject Grades',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3)),
            ),
            SizedBox(height: 12),
            ...List.generate(subjectGrades.length, (index) {
              final s = subjectGrades[index];
              return StaggeredItem(
                index: index,
                child: Container(
                  margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: RippleTap(
                    rippleColor: s['color'] as Color,
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade100)),
                      child: Column(children: [
                        Row(children: [
                          Container(
                              width: 4,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: s['color'] as Color,
                                  borderRadius: BorderRadius.circular(2))),
                          SizedBox(width: 12),
                          Expanded(
                              child: Text(s['subject'],
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textDark))),
                          SlotNumber(
                              value: s['avg'] as double,
                              decimals: 1,
                              suffix: '%',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: s['color'] as Color)),
                        ]),
                        SizedBox(height: 10),
                        AnimatedProgressBar(
                            value: (s['avg'] as double) / 100,
                            color: s['color'] as Color,
                            height: 5,
                            delayMs: 300 + (index * 80)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── GRADE TRENDS TAB ────────────────────────────────────────────────────────
  Widget _buildGradeTrendsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Grade Trends',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text('School-wide academic performance over time',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 100,
            child: WaveCard(
              gradientColors: [Color(0xFF1E5C3A), primary, Color(0xFF3D8B6B)],
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: Offset(0, 10))
              ],
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Average',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7))),
                      SizedBox(height: 4),
                      Row(children: [
                        SlotNumber(
                            value: 87.5,
                            decimals: 1,
                            suffix: '%',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        SizedBox(width: 12),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            Icon(Icons.trending_up_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('+9.5% this term',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                      SizedBox(height: 20),
                      _buildLineChart(gradesTrend, 'avg', Colors.white),
                      SizedBox(height: 8),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: gradesTrend
                              .map((d) => Text(d['month'],
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.6))))
                              .toList()),
                    ]),
              ),
            ),
          ),
          SizedBox(height: 28),
          FadeSlideIn(
              delayMs: 150,
              child: Text('Assignment Completion by Class',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3))),
          SizedBox(height: 16),
          ...List.generate(assignmentCompletion.length, (index) {
            final a = assignmentCompletion[index];
            double pct = (a['completed'] as int) / (a['total'] as int);
            Color c = a['color'] as Color;
            return StaggeredItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100)),
                child: Column(children: [
                  Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration:
                            BoxDecoration(color: c, shape: BoxShape.circle)),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(a['class'],
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark))),
                    SlotNumber(
                        value: (pct * 100).toDouble(),
                        decimals: 0,
                        suffix: '%',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: c),
                        delayMs: 200 + index * 80),
                  ]),
                  SizedBox(height: 10),
                  AnimatedProgressBar(
                      value: pct,
                      color: c,
                      height: 7,
                      delayMs: 300 + index * 80),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── TEACHER WORKLOAD TAB ─────────────────────────────────────────────────────
  Widget _buildTeacherWorkloadTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Teacher Workload',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text('Grading backlog and staff capacity',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          SizedBox(height: 20),
          FadeSlideIn(
            delayMs: 100,
            child: Row(children: [
              Expanded(child: _miniStatCard('$_teacherCount', 'Teachers', primary)),
              SizedBox(width: 10),
              Expanded(child: _miniStatCard('$_classCount', 'Classes', info)),
              SizedBox(width: 10),
              Expanded(child: _miniStatCard('—', 'Submissions', accent)),
            ]),
          ),
          SizedBox(height: 24),
          FadeSlideIn(
              delayMs: 120,
              child: Text('Staff Overview',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3))),
          SizedBox(height: 16),
          ...List.generate(teacherWorkload.length, (index) {
            final t = teacherWorkload[index];
            int submitted = t['submitted'] as int;
            int graded = t['graded'] as int;
            int ungraded = submitted - graded;
            double workloadPct =
                submitted > 0 ? (ungraded / submitted).clamp(0.0, 1.0) : 0.0;
            Color workloadColor = workloadPct >= 0.8
                ? danger
                : workloadPct >= 0.5
                    ? accent
                    : success;
            return StaggeredItem(
              index: index,
              child: FlipCard(
                delayMs: index * 80,
                child: Container(
                  margin: EdgeInsets.only(bottom: 14),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: workloadPct >= 0.8
                              ? danger.withOpacity(0.2)
                              : Colors.grey.shade100)),
                  child: Column(children: [
                    Row(children: [
                      CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              (t['color'] as Color).withOpacity(0.12),
                          child: Text(t['avatar'],
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: t['color'] as Color))),
                      SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(t['name'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    letterSpacing: -0.2)),
                            Text(t['subject'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                          ])),
                      if (workloadPct >= 0.8)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: danger.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.warning_amber_rounded,
                                color: danger, size: 12),
                            SizedBox(width: 4),
                            Text('Overloaded',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 10,
                                    color: danger,
                                    fontWeight: FontWeight.bold)),
                          ]),
                        ),
                    ]),
                    SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: _workloadStat('${t['classes']}', 'Classes',
                              t['color'] as Color)),
                      Expanded(
                          child: _workloadStat('${t['students']}', 'Students',
                              t['color'] as Color)),
                      Expanded(
                          child: _workloadStat(
                              '$submitted', 'Submitted', t['color'] as Color)),
                      Expanded(
                          child: _workloadStat(
                              '$graded', 'Graded', t['color'] as Color)),
                    ]),
                    SizedBox(height: 12),
                    Row(children: [
                      Text('Grading Backlog',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: textLight)),
                      Spacer(),
                      Text('$ungraded of $submitted ungraded',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 11,
                              color: workloadColor,
                              fontWeight: FontWeight.bold)),
                    ]),
                    SizedBox(height: 6),
                    AnimatedProgressBar(
                        value: workloadPct,
                        color: workloadColor,
                        height: 6,
                        delayMs: 300 + index * 100),
                    if (workloadPct >= 0.8) ...[
                      SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.warning_amber_rounded,
                            color: danger, size: 13),
                        SizedBox(width: 4),
                        Text('High backlog — needs attention',
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 11,
                                color: danger)),
                      ]),
                    ],
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── STUDENTS TAB ────────────────────────────────────────────────────────────
  Widget _buildStudentsTab() {
    if (_students.isEmpty && !_studentsLoading) {
      _loadStudents();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: FadeSlideIn(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student Directory',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.8)),
                      SizedBox(height: 4),
                      Text(
                          _studentsLoading
                              ? 'Loading...'
                              : '${_students.length} students enrolled',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              color: textLight)),
                    ],
                  ),
                ),
                BouncyTap(
                  onTap: () => AddStudentSheet.show(context,
                      onStudentAdded: _loadStudents),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_add_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Add Student',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: FadeSlideIn(
            delayMs: 60,
            child: TextField(
              controller: _studentSearchCtrl,
              onChanged: _filterStudents,
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 14, color: textDark),
              decoration: InputDecoration(
                hintText: 'Search by name, roll number or grade...',
                hintStyle: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 13,
                    color: Colors.grey.shade400),
                prefixIcon:
                    Icon(Icons.search, color: textLight, size: 20),
                filled: true,
                fillColor: bgCard,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: primary.withOpacity(0.5), width: 1.5)),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),
        Expanded(
          child: _studentsLoading
              ? Center(
                  child: CircularProgressIndicator(color: primary))
              : _filteredStudents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined,
                                color: textLight, size: 48),
                            SizedBox(height: 12),
                            Text(
                              _studentSearchCtrl.text.isNotEmpty
                                  ? 'No students match your search'
                                  : 'No students enrolled yet',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  color: textLight),
                            ),
                            SizedBox(height: 6),
                            Text('Tap "Add Student" to enroll one',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: primary,
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredStudents.length,
                        itemBuilder: (_, index) =>
                            _studentCard(_filteredStudents[index], index),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _studentCard(StudentModel student, int index) {
    final colors = [primary, info, accent, purple, success, danger];
    final cardColor = colors[index % colors.length];

    return StaggeredItem(
      index: index,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: cardColor.withOpacity(0.12),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cardColor),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        letterSpacing: -0.2)),
                SizedBox(height: 2),
                Row(children: [
                  if (student.rollNumber.isNotEmpty) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(student.rollNumber,
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cardColor)),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (student.displayGradeSection.isNotEmpty)
                    Text(student.displayGradeSection,
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 12,
                            color: textLight)),
                ]),
                if (student.parentName.isNotEmpty) ...[
                  SizedBox(height: 2),
                  Text('Parent: ${student.parentName}',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 11,
                          color: textLight)),
                ],
              ],
            ),
          ),
          if (student.classIds.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: info.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${student.classIds.length} class${student.classIds.length > 1 ? 'es' : ''}',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: info)),
            ),
        ]),
      ),
    );
  }

  // ─── COMMUNICATE TAB ──────────────────────────────────────────────────────────
  Widget _buildCommunicateTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          FadeSlideIn(
              child: Text('Communicate',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: Text('Announcements, votes and parent messages',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          SizedBox(height: 24),

          // Quick action cards row
          FadeSlideIn(
            delayMs: 80,
            child: Row(children: [
              Expanded(
                child: BouncyTap(
                  onTap: _showNewAnnouncement,
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [primary.withOpacity(0.9), primary]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.campaign_outlined,
                                  color: Colors.white, size: 20)),
                          SizedBox(height: 12),
                          Text('Announce',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Send to everyone,\nparents or teachers',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.4)),
                        ]),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: BouncyTap(
                  onTap: _showCreateVote,
                  child: Container(
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [purple.withOpacity(0.9), purple]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: purple.withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 4))
                      ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.how_to_vote_outlined,
                                  color: Colors.white, size: 20)),
                          SizedBox(height: 12),
                          Text('Create Vote',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          SizedBox(height: 2),
                          Text('Weather days, events\nor policy decisions',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.4)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),

          SizedBox(height: 28),

          // Active votes (hardcoded demo)
          FadeSlideIn(
            delayMs: 100,
            child: Builder(
              builder: (context) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Active Votes',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                              letterSpacing: -0.3)),
                      SizedBox(width: 8),
                      if (demoVotes.isNotEmpty)
                        PulseBadge(count: demoVotes.length, color: purple),
                    ]),
                    SizedBox(height: 12),
                    if (demoVotes.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: bgCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100)),
                        child: Column(children: [
                          Icon(Icons.how_to_vote_outlined,
                              color: textLight, size: 28),
                          SizedBox(height: 8),
                          Text('No active votes',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: textLight)),
                          SizedBox(height: 4),
                          Text('Tap "Create Vote" above to start one',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  color: textLight)),
                        ]),
                      )
                    else
                      ...demoVotes.map((vote) {
                        final voteData =
                            vote['votes'] as Map<String, dynamic>? ?? {};
                        final total = (voteData['school'] ?? 0) +
                            (voteData['no_school'] ?? 0) +
                            (voteData['undecided'] ?? 0);
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: purple.withOpacity(0.2))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: purple.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(vote['type'] as String,
                                          style: TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 10,
                                              color: purple,
                                              fontWeight: FontWeight.w700))),
                                  Spacer(),
                                  Icon(Icons.people_outline,
                                      color: textLight, size: 13),
                                  SizedBox(width: 4),
                                  Text('$total voted',
                                      style: TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 11,
                                          color: textLight)),
                                  SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Vote closed',
                                                  style: TextStyle(
                                                      fontFamily: 'Raleway')),
                                              backgroundColor: textMid,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10))));
                                    },
                                    child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: danger.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text('Close',
                                            style: TextStyle(
                                                fontFamily: 'Raleway',
                                                fontSize: 10,
                                                color: danger,
                                                fontWeight: FontWeight.w700))),
                                  ),
                                ]),
                                SizedBox(height: 10),
                                Text(vote['question'] as String,
                                    style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textDark,
                                        height: 1.3)),
                                if (total > 0) ...[
                                  SizedBox(height: 12),
                                  _voteResultBar('School',
                                      voteData['school'] ?? 0, total, success),
                                  SizedBox(height: 5),
                                  _voteResultBar(
                                      'No School',
                                      voteData['no_school'] ?? 0,
                                      total,
                                      danger),
                                  SizedBox(height: 5),
                                  _voteResultBar(
                                      'Undecided',
                                      voteData['undecided'] ?? 0,
                                      total,
                                      accent),
                                ],
                              ]),
                        );
                      }).toList(),
                  ],
                );
              },
            ),
          ),

          SizedBox(height: 28),

          // Message parents section
          FadeSlideIn(
            delayMs: 120,
            child: Row(children: [
              Text('Message a Parent',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.3)),
            ]),
          ),
          SizedBox(height: 12),

          ...List.generate(parents.length, (index) {
            final p = parents[index];
            return StaggeredItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                child: BouncyTap(
                  onTap: () => Navigator.push(
                    context,
                    TatvaPageRoute.slideRight(
                      MessagingScreen(
                        otherUserId: p['uid'],
                        otherUserName: p['name'],
                        otherUserRole: 'Parent of ${p['child']}',
                        otherUserEmail: p['email'],
                        avatarColor: p['color'] as Color,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100)),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            (p['color'] as Color).withOpacity(0.12),
                        child: Text(p['avatar'],
                            style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: p['color'] as Color)),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(p['name'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                    letterSpacing: -0.2)),
                            Text('Parent of ${p['child']}',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 12,
                                    color: textLight)),
                            Text(p['class'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 11,
                                    color: textLight)),
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: purple.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: purple.withOpacity(0.15))),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_outlined,
                                        color: purple, size: 13),
                                    SizedBox(width: 4),
                                    Text('Message',
                                        style: TextStyle(
                                            fontFamily: 'Raleway',
                                            fontSize: 11,
                                            color: purple,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                            ),
                            SizedBox(height: 4),
                            Text(p['email'],
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 9,
                                    color: textLight)),
                          ]),
                    ]),
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _voteResultBar(String label, int count, int total, Color color) {
    double pct = total > 0 ? count / total : 0;
    return Row(children: [
      SizedBox(
          width: 80,
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 11, color: textLight))),
      Expanded(
          child: AnimatedProgressBar(
              value: pct, color: color, height: 5, delayMs: 0)),
      SizedBox(width: 8),
      Text('$count',
          style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold)),
    ]);
  }

  // ─── PROFILE TAB ──────────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 16),
          FadeSlideIn(
            child: HeroAvatar(
              heroTag: 'principal_avatar',
              initial: userName.isNotEmpty ? userName[0] : 'P',
              radius: 46,
              bgColor: purple.withOpacity(0.1),
              textColor: purple,
              borderColor: accent,
            ),
          ),
          SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 80,
              child: Text(userName,
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                      letterSpacing: -0.5))),
          SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 100,
              child: Text(userEmail,
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 13, color: textLight))),
          SizedBox(height: 10),
          FadeSlideIn(
            delayMs: 120,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Principal',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 12,
                      color: purple,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: 32),
          ...List.generate(4, (index) {
            final items = [
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.people_outline, 'Staff', '$_teacherCount Teachers'],
              [
                Icons.email_outlined,
                'Email',
                userEmail.length > 24
                    ? userEmail.substring(0, 24) + '...'
                    : userEmail
              ],
              [Icons.verified_outlined, 'Status', 'Verified'],
            ];
            return StaggeredItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                child: RippleTap(
                  rippleColor: purple,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100)),
                    child: Row(children: [
                      Icon(items[index][0] as IconData,
                          color: purple, size: 18),
                      SizedBox(width: 14),
                      Expanded(
                          child: Text(items[index][1] as String,
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: textLight))),
                      Text(items[index][2] as String,
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              color: textDark,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: 24),
          FadeSlideIn(
            delayMs: 200,
            child: BouncyTap(
              onTap: _logout,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: danger.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: danger.withOpacity(0.15))),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: danger, size: 18),
                  SizedBox(width: 8),
                  Text('Sign Out',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: danger)),
                ]),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('v1.0.0 · Tatva Academy',
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 11, color: textLight)),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── GREETING CARD ────────────────────────────────────────────────────────────
  Widget _buildGreetingCard() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: [
          Color(0xFF4A148C),
          Color(0xFF7B1FA2),
          Color(0xFF9C27B0)
        ],
        boxShadow: [
          BoxShadow(
              color: purple.withOpacity(0.35),
              blurRadius: 24,
              offset: Offset(0, 10)),
          BoxShadow(
              color: purple.withOpacity(0.15),
              blurRadius: 48,
              offset: Offset(0, 20)),
        ],
        child: Stack(
          children: [
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
              padding: EdgeInsets.all(24),
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
                                  style: TextStyle(fontSize: 16)),
                              SizedBox(width: 6),
                              Text(_greeting,
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500)),
                            ]),
                            SizedBox(height: 6),
                            TypewriterText(
                                text: userName,
                                delayMs: 400,
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            SizedBox(height: 6),
                            Text('Tatva Academy · Principal',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6))),
                          ]),
                    ),
                    HeroAvatar(
                        heroTag: 'principal_avatar',
                        initial: userName.isNotEmpty ? userName[0] : 'P',
                        radius: 26,
                        bgColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.white,
                        borderColor: Colors.white.withOpacity(0.3)),
                  ]),
                  SizedBox(height: 20),
                  Container(height: 1, color: Colors.white.withOpacity(0.1)),
                  SizedBox(height: 16),
                  Row(children: [
                    _greetingStatItem('$_teacherCount', 'Teachers'),
                    _greetingDivider(),
                    _greetingStatItem('$_studentCount', 'Students'),
                    _greetingDivider(),
                    _greetingStatItem('$_classCount', 'Classes'),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _greetingStatItem(String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.55)),
              textAlign: TextAlign.center),
        ]),
      );

  Widget _greetingDivider() =>
      Container(width: 1, height: 28, color: Colors.white.withOpacity(0.1));

  Widget _statCard(String value, String label, IconData icon, Color color) =>
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16)),
          SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: -0.5)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 10,
                  color: textLight,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _miniStatCard(String value, String label, Color color) {
    final numValue = double.tryParse(value);
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15))),
      child: Column(children: [
        numValue != null
            ? SlotNumber(
                value: numValue,
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color))
            : Text(value,
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 11,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _workloadStat(String value, String label, Color color) =>
      Column(children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Raleway',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style: TextStyle(
                fontFamily: 'Raleway', fontSize: 11, color: textLight)),
      ]);

  Widget _buildLineChart(
      List<Map<String, dynamic>> data, String key, Color color) {
    return SizedBox(
        height: 80,
        child: CustomPaint(
            painter: _LineChartPainter(data, key, color), size: Size.infinite));
  }

  Widget _buildMiniLineChart(
      List<Map<String, dynamic>> data, String key, Color color) {
    return SizedBox(
        height: 60,
        child: CustomPaint(
            painter: _LineChartPainter(data, key, color), size: Size.infinite));
  }
}

class _LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String key;
  final Color color;

  _LineChartPainter(this.data, this.key, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final values = data.map((d) => (d[key] as num).toDouble()).toList();
    final minVal = values.reduce(min) - 2;
    final maxVal = values.reduce(max) + 2;
    final range = maxVal - minVal;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((values[i] - minVal) / range * size.height);
      points.add(Offset(x, y));
    }

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final controlX = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(controlX, prev.dy, controlX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
      canvas.drawCircle(p, 5, dotBorder);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => true;
}
