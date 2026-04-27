import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/mixins/dashboard_mixin.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../models/announcement_model.dart';
import '../../models/content_item.dart';
import '../../models/vote_model.dart';
import '../../shared/utils/announcement_helpers.dart';
import '../../shared/theme/colors.dart';
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
    with TickerProviderStateMixin, DashboardMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Homework'),
    TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Grades'),
    TabItem(icon: Icons.lightbulb_outline_rounded, activeIcon: Icons.lightbulb_rounded, label: 'Learn'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  StudentDashboardData? _data;
  List<AnnouncementModel> _announcements = [];
  List<VoteModel> _activeVotes = [];
  final Set<String> _completedIds = {};
  final Map<String, Map<String, dynamic>> _mySubmissions = {};

  @override
  void initState() {
    super.initState();
    initDashboardAnimations();
    _loadUser();
  }

  @override
  void dispose() {
    disposeDashboardAnimations();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadStudentDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _announcements = List.of(data.announcements);
      _activeVotes = List.of(data.activeVotes);
      _completedIds.clear();
      _mySubmissions.clear();
      for (final hw in data.homework) {
        if (hw.isSubmittedBy(_uid)) _completedIds.add(hw.id);
      }
      await _fetchMySubmissions();
    } catch (e) {
      debugPrint('StudentDashboard._loadData error: $e');
    }
    onDataLoaded();
  }

  String get _motivationalText {
    final h = DateTime.now().hour;
    if (h < 12) return 'Start strong today! 💪';
    if (h < 17) return 'Keep pushing forward! 🚀';
    return 'Great work today! 🌟';
  }

  Future<void> _fetchMySubmissions() async {
    for (final hwId in Set<String>.from(_completedIds)) {
      try {
        final sub = await _api.getMyHomeworkSubmission(hwId);
        if (sub != null) {
          _mySubmissions[hwId] = sub;
          if (sub['status'] == 'returned') _completedIds.remove(hwId);
        }
      } catch (_) {}
    }
  }

  void _handleMarkDone(String hwId, [Map<String, dynamic>? submission]) {
    setState(() {
      _completedIds.add(hwId);
      if (submission != null) _mySubmissions[hwId] = submission;
    });
    _api.submitHomework(hwId);
  }

  void _handleMarkIncomplete(String hwId) {
    setState(() => _completedIds.remove(hwId));
  }

  void _handleToggleAnnouncementLike(AnnouncementModel ann) {
    setState(() => _announcements = toggleAnnouncementLike(_announcements, ann.id, _uid));
    _api.toggleAnnouncementLike(ann.id);
  }

  void _castVote(int index, String option) async {
    if (_activeVotes[index].hasVoted(_uid)) return;
    final voteId = _activeVotes[index].id;
    final old = _activeVotes[index];
    final updatedVotes = Map<String, int>.from(old.votes);
    updatedVotes[option] = (updatedVotes[option] ?? 0) + 1;
    setState(() {
      _activeVotes[index] = old.copyWith(
        votes: updatedVotes,
        voters: [...old.voters, _uid],
      );
    });
    _api.castVote(voteId, option);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Vote submitted!'),
      backgroundColor: TatvaColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _handleMarkCompleted(ContentItem item) {
    setState(() {
      final idx = (_data?.contentItems ?? []).indexOf(item);
      if (idx >= 0) {
        _data = StudentDashboardData(
          user: _data!.user,
          primaryClass: _data!.primaryClass,
          grades: _data!.grades,
          announcements: _data!.announcements,
          homework: _data!.homework,
          activeVotes: _data!.activeVotes,
          behaviorPoints: _data!.behaviorPoints,
          behaviorScore: _data!.behaviorScore,
          attendance: _data!.attendance,
          activityFeed: _data!.activityFeed,
          contentItems: List.of(_data!.contentItems)
            ..[idx] = item.copyWith(completedBy: [...item.completedBy, _uid]),
        );
      }
    });
    _api.markContentCompleted(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return buildDashboardScaffold(
      tabs: _tabs,
      bodyBuilder: () => IndexedStack(index: currentTab, children: [
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
          activeVotes: _activeVotes,
          motivationalText: _motivationalText,
          greetingFade: greetingFade,
          greetingSlide: greetingSlide,
          greetingScale: greetingScale,
          onSwitchToHomework: () => switchTab(2),
          onRefresh: _loadUser,
          uid: _uid,
          onCastVote: _castVote,
          api: _api,
          grade: _data?.primaryClass?.grade,
          onToggleAnnouncementLike: _handleToggleAnnouncementLike,
        ),
        StudentScheduleTab(
          primaryClass: _data?.primaryClass,
          api: _api,
        ),
        StudentHomeworkTab(
          homework: _data?.homework ?? [],
          completedIds: _completedIds,
          mySubmissions: _mySubmissions,
          uid: _uid,
          api: _api,
          onMarkDone: _handleMarkDone,
          onMarkIncomplete: _handleMarkIncomplete,
          onRefresh: _loadUser,
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
          onLogout: logout,
          onPhotoUpdated: (url) => setState(() {
            _data = _data?.copyWithPhotoUrl(url);
          }),
        ),
      ]),
    );
  }
}
