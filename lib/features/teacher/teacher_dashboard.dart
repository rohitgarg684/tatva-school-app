import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/tatva_snackbar.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/mixins/dashboard_mixin.dart';
import '../../services/dashboard_service.dart';
import '../../services/api_service.dart';
import '../../repositories/auth_repository.dart';
import '../../models/class_model.dart';
import '../../models/announcement_model.dart';
import '../../shared/utils/announcement_helpers.dart';
import '../../models/attachment.dart';
import '../../models/audience.dart';
import '../../models/homework_model.dart';
import '../../models/behavior_point.dart';
import '../../models/attendance_record.dart';
import '../../models/content_item.dart';
import '../../models/vote_model.dart';
import '../principal/widgets/new_announcement_sheet.dart';
import '../../shared/widgets/announcement_card.dart';
import 'tabs/home_tab.dart';
import 'tabs/classes_tab.dart';
import 'tabs/behavior_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/schedule_tab.dart';
import 'tabs/grades_tab.dart';
import 'tabs/homework_tab.dart';
import 'tabs/learn_tab.dart';
import 'tabs/votes_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/profile_tab.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  _TeacherDashboardState createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard>
    with TickerProviderStateMixin, DashboardMixin {
  static const List<TabItem> _tabs = [
    TabItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
    TabItem(icon: Icons.class_outlined, activeIcon: Icons.class_rounded, label: 'Classes'),
    TabItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events_rounded, label: 'Behavior'),
    TabItem(icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, label: 'Attend'),
    TabItem(icon: Icons.calendar_view_week_outlined, activeIcon: Icons.calendar_view_week_rounded, label: 'Schedule'),
    TabItem(icon: Icons.grade_outlined, activeIcon: Icons.grade_rounded, label: 'Grades'),
    TabItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Homework'),
    TabItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Learn'),
    TabItem(icon: Icons.how_to_vote_outlined, activeIcon: Icons.how_to_vote_rounded, label: 'Votes'),
    TabItem(icon: Icons.chat_outlined, activeIcon: Icons.chat_rounded, label: 'Messages'),
    TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Profile'),
  ];

  final _dashSvc = DashboardService();
  final _api = ApiService();
  String _uid = '';

  TeacherDashboardData? _data;
  List<HomeworkModel> _homework = [];
  List<AnnouncementModel> _announcements = [];
  List<BehaviorPoint> _classBehavior = [];
  List<AttendanceRecord> _todayAttendance = [];
  List<ContentItem> _contentItems = [];
  List<VoteModel> _voteModels = [];

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
      final data = await _dashSvc.loadTeacherDashboard(overrideUid: _uid, forceRefresh: true);
      _data = data;
      _homework = List.of(data.homework);
      _announcements = List.of(data.announcements);
      _classBehavior = List.of(data.classBehavior);
      _todayAttendance = List.of(data.todayAttendance);
      _contentItems = List.of(data.contentItems);
      _voteModels = List.of(data.activeVotes);
    } catch (e) {
      debugPrint('TeacherDashboard._loadData error: $e');
    }
    onDataLoaded();
  }

  @override
  Widget build(BuildContext context) {
    return buildDashboardScaffold(
      tabs: _tabs,
      bodyBuilder: () => IndexedStack(index: currentTab, children: [
            TeacherHomeTab(
              user: _data?.user,
              classes: _data?.classes ?? [],
              homework: _homework,
              announcements: _announcements,
              uid: _uid,
              activityFeed: _data?.activityFeed ?? [],
              greetingFade: greetingFade,
              greetingSlide: greetingSlide,
              greetingScale: greetingScale,
              onRefresh: _loadUser,
              onSwitchTab: switchTab,
              onViewClassStudents: (cls) => _showClassStudents(cls),
              onDeleteClass: (cls) => _confirmDeleteClass(cls),
              onNewAnnouncement: _showNewAnnouncement,
              onToggleAnnouncementLike: _toggleAnnouncementLike,
              onEditAnnouncement: _editAnnouncement,
              onDeleteAnnouncement: _deleteAnnouncement,
              api: _api,
              firstClassId: (_data?.classes ?? []).isNotEmpty ? _data!.classes.first.id : null,
            ),
            TeacherClassesTab(
              classes: _data?.classes ?? [],
              students: _data?.studentsInFirstClass ?? [],
              onRefresh: _loadUser,
              onSwitchTab: switchTab,
            ),
            TeacherBehaviorTab(
              classBehavior: _classBehavior,
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              uid: _uid,
              user: _data?.user,
              onBehaviorAdded: (bp) => setState(() => _classBehavior.add(bp)),
              onBehaviorDeleted: (id) =>
                  setState(() => _classBehavior.removeWhere((b) => b.id == id)),
            ),
            TeacherAttendanceTab(
              allSchoolStudents: _data?.allStudents ?? [],
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              todayAttendance: _todayAttendance,
              uid: _uid,
              onAttendanceSaved: (records) =>
                  setState(() => _todayAttendance = records),
            ),
            TeacherScheduleTab(
              classes: _data?.classes ?? [],
              uid: _uid,
              onRefresh: _loadUser,
            ),
            TeacherGradesTab(
              classes: _data?.classes ?? [],
              allGrades: _data?.allTeacherGrades ?? [],
              allSchoolStudents: _data?.allStudents ?? [],
              testTitles: _data?.testTitles ?? [],
              onRefresh: _loadUser,
            ),
            TeacherHomeworkTab(
              homework: _homework,
              students: _data?.studentsInFirstClass ?? [],
              classes: _data?.classes ?? [],
              uid: _uid,
              user: _data?.user,
              onHomeworkAdded: (hw) =>
                  setState(() => _homework.insert(0, hw)),
              onHomeworkDeleted: (id) =>
                  setState(() => _homework.removeWhere((h) => h.id == id)),
            ),
            TeacherLearnTab(
              contentItems: _contentItems,
              classes: _data?.classes ?? [],
              allStudents: _data?.allStudents ?? [],
              uid: _uid,
              onContentAdded: (ci) =>
                  setState(() => _contentItems.insert(0, ci)),
              onContentDeleted: (id) =>
                  setState(() => _contentItems.removeWhere((c) => c.id == id)),
              onContentUpdated: (ci) => setState(() {
                final idx = _contentItems.indexWhere((c) => c.id == ci.id);
                if (idx >= 0) _contentItems[idx] = ci;
              }),
            ),
            TeacherVotesTab(
              votes: _voteModels,
              uid: _uid,
              api: _api,
              onVoteCreated: (vote) => setState(() => _voteModels.insert(0, vote)),
              onVoteUpdated: (vote) => setState(() {
                final idx = _voteModels.indexWhere((v) => v.id == vote.id);
                if (idx >= 0) _voteModels[idx] = vote;
              }),
              onVoteDeleted: (id) => setState(() => _voteModels.removeWhere((v) => v.id == id)),
              onVoteClosed: (vote) => setState(() {
                final idx = _voteModels.indexWhere((v) => v.id == vote.id);
                if (idx >= 0) _voteModels[idx] = _voteModels[idx].copyWith(active: false);
              }),
            ),
            TeacherMessagesTab(parents: _data?.parentsInFirstClass ?? []),
            TeacherProfileTab(
              user: _data?.user,
              classCount: _data?.classes.length ?? 0,
              onLogout: logout,
              onPhotoUpdated: (url) => setState(() {
                _data = _data?.copyWithPhotoUrl(url);
              }),
            ),
          ]),
    );
  }

  List<String> get _availableGrades {
    return (_data?.classes ?? [])
        .map((c) => c.grade)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  void _showNewAnnouncement() {
    final grades = _availableGrades;
    NewAnnouncementSheet.show(
      context,
      api: _api,
      uid: _uid,
      userName: _data?.user?.name ?? '',
      userRole: 'Teacher',
      availableGrades: grades,
      onAnnouncementCreated: (ann) =>
          setState(() => _announcements.insert(0, ann)),
    );
  }

  void _toggleAnnouncementLike(AnnouncementModel ann) {
    setState(() => _announcements = toggleAnnouncementLike(_announcements, ann.id, _uid));
    _api.toggleAnnouncementLike(ann.id);
  }

  void _editAnnouncement(AnnouncementModel ann) {
    EditAnnouncementSheet.show(
      context,
      announcement: ann,
      availableGrades: _availableGrades,
      api: _api,
      onSave: (title, body, newGrades, attachments) async {
        await _api.updateAnnouncement(ann.id, title: title, body: body, grades: newGrades, attachments: attachments);
        setState(() {
          final idx = _announcements.indexWhere((a) => a.id == ann.id);
          if (idx >= 0) {
            _announcements[idx] = _announcements[idx].copyWith(
              title: title,
              body: body,
              grades: newGrades,
              audience: newGrades.isEmpty ? Audience.everyone : Audience.grades,
              attachments: attachments.map((a) => Attachment.fromJson(a)).toList(),
            );
          }
        });
      },
    );
  }

  void _deleteAnnouncement(AnnouncementModel ann) {
    if (ann.id.isEmpty) return;
    _api.deleteAnnouncement(ann.id);
    setState(() => _announcements.removeWhere((a) => a.id == ann.id));
  }

  // ─── SHARED SHEETS (used by HomeTab callbacks) ────────────────────────────

  void _showClassStudents(ClassModel cls) {
    HapticFeedback.lightImpact();
    final classStudents = (_data?.studentsInFirstClass ?? [])
        .where((s) => cls.studentUids.contains(s.uid))
        .toList()
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
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cls.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text('${cls.subject} · ${classStudents.length} students',
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (classStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.people_outline,
                    color: TatvaColors.neutral400, size: 40),
                const SizedBox(height: 8),
                const Text('No students in this class yet',
                    style: TextStyle(
                        fontSize: 14, color: TatvaColors.neutral400)),
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
                      ? s.name
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                      : '?';
                  final colors = [
                    TatvaColors.primary,
                    TatvaColors.info,
                    TatvaColors.accent,
                    TatvaColors.purple,
                    TatvaColors.success
                  ];
                  final c = colors[i % colors.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: c)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: TatvaColors.neutral900)),
                              Text(s.email,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: TatvaColors.neutral400)),
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

  void _confirmDeleteClass(ClassModel cls) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Class',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${cls.name}"?\n\n'
            'This will remove ${cls.studentUids.length} student(s) and '
            '${cls.parentUids.length} parent(s) from this class. '
            'This action cannot be undone.',
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: TatvaColors.neutral400)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().deleteClass(cls.id);
                TatvaSnackbar.show(context, '"${cls.name}" deleted');
                _loadUser();
              } catch (e) {
                TatvaSnackbar.show(context, 'Failed to delete class');
                debugPrint('Delete class error: $e');
              }
            },
            child: const Text('Delete',
                style: TextStyle(
                    color: TatvaColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
