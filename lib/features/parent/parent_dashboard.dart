import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/mixins/dashboard_mixin.dart';
import '../../repositories/auth_repository.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../models/announcement_model.dart';
import '../../models/vote_model.dart';
import '../../models/weekly_report.dart';
import '../../shared/utils/announcement_helpers.dart';
import 'widgets/teacher_profile_sheet.dart';
import 'widgets/weekly_report_sheet.dart';
import 'tabs/home_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/progress_tab.dart';
import 'tabs/behavior_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/vote_tab.dart';
import 'tabs/profile_tab.dart';
import '../student/tabs/homework_tab.dart';
class ParentDashboard extends StatefulWidget {
  final int initialChildIndex;
  const ParentDashboard({super.key, this.initialChildIndex = 0});

  @override
  _ParentDashboardState createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard>
    with TickerProviderStateMixin, DashboardMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Homework'),
    TabItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Progress'),
    TabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Behavior'),
    TabItem(icon: Icons.lightbulb_outline, activeIcon: Icons.lightbulb_rounded, label: 'Learn'),
    TabItem(icon: Icons.how_to_vote_outlined, activeIcon: Icons.how_to_vote_rounded, label: 'Vote'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  ParentDashboardData? _data;
  late int _selectedChildIndex = widget.initialChildIndex;
  List<AnnouncementModel> _announcements = [];
  List<VoteModel> _activeVotes = [];
  Set<String> _completedIds = {};
  Map<String, Map<String, dynamic>> _mySubmissions = {};

  @override
  void initState() {
    super.initState();
    initDashboardAnimations();
    _loadData();
  }

  @override
  void dispose() {
    disposeDashboardAnimations();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      _uid = AuthRepository().currentUid ?? '';
      final data = await _dashSvc.loadParentDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _activeVotes = List.of(data.activeVotes);
      _announcements = List.of(data.announcements);
      if (_selectedChildIndex >= data.childrenData.length) {
        _selectedChildIndex = 0;
      }
      _rebuildHomeworkState();
    } catch (e) {
      debugPrint('ParentDashboard._loadData error: $e');
    }
    onDataLoaded();
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

  void _toggleAnnouncementLike(AnnouncementModel ann) {
    setState(() => _announcements = toggleAnnouncementLike(_announcements, ann.id, _uid));
    _api.toggleAnnouncementLike(ann.id);
  }

  void _rebuildHomeworkState() {
    final child = _currentChild;
    if (child == null) return;
    _completedIds = {};
    _mySubmissions = Map.of(child.submissions);
    for (final hw in child.homework) {
      if (hw.isSubmittedBy(child.childUid)) {
        final sub = _mySubmissions[hw.id];
        if (sub != null && sub['status'] == 'returned') continue;
        _completedIds.add(hw.id);
      }
    }
  }

  void _handleMarkDone(String hwId, [Map<String, dynamic>? submission]) {
    final childUid = _currentChild?.childUid ?? '';
    setState(() {
      _completedIds.add(hwId);
      if (submission != null) _mySubmissions[hwId] = submission;
    });
    _api.submitHomework(hwId, studentUid: childUid);
  }

  void _handleMarkIncomplete(String hwId) {
    setState(() => _completedIds.remove(hwId));
  }

  void _logout() => logout();

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
              setState(() {
                _selectedChildIndex = i;
                _rebuildHomeworkState();
              });
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
    return buildDashboardScaffold(
      tabs: _tabs,
      bodyBuilder: () => IndexedStack(index: currentTab, children: [
            ParentHomeTab(
              user: _data?.user,
              currentChild: _currentChild,
              childrenData: _data?.childrenData ?? [],
              selectedChildIndex: _selectedChildIndex,
              announcements: _announcements,
              activityFeed: _data?.activityFeed ?? [],
              greetingFade: greetingFade,
              greetingSlide: greetingSlide,
              greetingScale: greetingScale,
              onShowTeacherProfile: _showTeacherProfile,
              onSwitchTab: switchTab,
              onRefresh: _loadData,
              childSwitcher: _childSwitcher(),
              uid: _uid,
              api: _api,
              grade: _currentChild?.childClass?.grade,
              childUid: _currentChild?.childUid,
              onToggleAnnouncementLike: _toggleAnnouncementLike,
            ),
            ParentScheduleTab(
              childrenData: _data?.childrenData ?? [],
              selectedChildIndex: _selectedChildIndex,
              api: _api,
            ),
            StudentHomeworkTab(
              homework: _currentChild?.homework ?? [],
              completedIds: _completedIds,
              mySubmissions: _mySubmissions,
              uid: _uid,
              api: _api,
              studentUid: _currentChild?.childUid,
              onMarkDone: _handleMarkDone,
              onMarkIncomplete: _handleMarkIncomplete,
              onRefresh: _loadData,
            ),
            ParentProgressTab(currentChild: _currentChild),
            ParentBehaviorTab(currentChild: _currentChild),
            ParentLearnTab(
              currentChild: _currentChild,
              contentItems: _data?.contentItems ?? [],
              childSwitcher: _childSwitcher(),
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
              childrenData: _data?.childrenData ?? [],
              selectedChildIndex: _selectedChildIndex,
              onChildSelected: (i) => setState(() {
                _selectedChildIndex = i;
                _rebuildHomeworkState();
              }),
            ),
          ]),
    );
  }
}
