import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../../shared/widgets/greeting_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/quick_action_button.dart';
import '../../../shared/utils/activity_helpers.dart' as activity_helpers;
import '../../parent/parent_helpers.dart';
import '../../../shared/utils/greeting.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/announcement_model.dart';
import '../../../models/homework_model.dart';
import '../../../models/activity_event.dart';
import '../../../services/api_service.dart';
import '../../../shared/screens/announcements_list_screen.dart';
import '../../../shared/screens/activity_list_screen.dart';

class TeacherHomeTab extends StatelessWidget {
  final UserModel? user;
  final List<ClassModel> classes;
  final List<HomeworkModel> homework;
  final List<AnnouncementModel> announcements;
  final String uid;
  final List<ActivityEvent> activityFeed;
  final Animation<double> greetingFade;
  final Animation<Offset> greetingSlide;
  final Animation<double> greetingScale;
  final Future<void> Function() onRefresh;
  final ValueChanged<int> onSwitchTab;
  final void Function(ClassModel) onViewClassStudents;
  final void Function(ClassModel) onDeleteClass;
  final VoidCallback onNewAnnouncement;
  final void Function(AnnouncementModel) onToggleAnnouncementLike;
  final void Function(AnnouncementModel) onEditAnnouncement;
  final ApiService api;
  final String? firstClassId;
  final void Function(AnnouncementModel) onDeleteAnnouncement;

  const TeacherHomeTab({
    super.key,
    required this.user,
    required this.classes,
    required this.homework,
    required this.announcements,
    required this.uid,
    required this.activityFeed,
    required this.greetingFade,
    required this.greetingSlide,
    required this.greetingScale,
    required this.onRefresh,
    required this.onSwitchTab,
    required this.onViewClassStudents,
    required this.onDeleteClass,
    required this.onNewAnnouncement,
    required this.onToggleAnnouncementLike,
    required this.onEditAnnouncement,
    required this.onDeleteAnnouncement,
    required this.api,
    this.firstClassId,
  });

  @override
  Widget build(BuildContext context) {
    final totalStudents =
        classes.fold(0, (sum, c) => sum + c.studentUids.length);
    final activeHw = homework.length;
    return RefreshIndicator(
      color: TatvaColors.primary,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FadeTransition(
              opacity: greetingFade,
              child: SlideTransition(
                  position: greetingSlide,
                  child: ScaleTransition(
                      scale: greetingScale, child: _buildGreetingCard()))),
          const SizedBox(height: 20),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: StatCard(value: '${classes.length}', label: 'Classes',
                    icon: Icons.class_outlined, color: TatvaColors.primary)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(value: '$totalStudents', label: 'Students',
                    icon: Icons.people_outline, color: TatvaColors.info)),
                const SizedBox(width: 10),
                Expanded(child: StatCard(value: '$activeHw', label: 'Homework',
                    icon: Icons.assignment_outlined, color: TatvaColors.accent)),
              ])),
          const SizedBox(height: 24),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('Quick Actions',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900))),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: QuickActionButton(label: 'Enter\nGrades', icon: Icons.edit_note_outlined,
                    color: TatvaColors.accent, onTap: () => onSwitchTab(5))),
                const SizedBox(width: 8),
                Expanded(child: QuickActionButton(label: 'Post\nHomework', icon: Icons.assignment_outlined,
                    color: TatvaColors.primary, onTap: () => onSwitchTab(6))),
                const SizedBox(width: 8),
                Expanded(child: QuickActionButton(label: 'Behavior', icon: Icons.emoji_events_outlined,
                    color: TatvaColors.info, onTap: () => onSwitchTab(2))),
                const SizedBox(width: 8),
                Expanded(child: QuickActionButton(label: 'Messages', icon: Icons.chat_outlined, color: TatvaColors.purple,
                    onTap: () => onSwitchTab(8))),
              ])),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Expanded(
                child: Text('Announcements',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900)),
              ),
              if (announcements.length > 3)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AnnouncementsListScreen(
                            api: api, currentUid: uid, currentRole: 'Teacher'))),
                    child: const Text('See All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                  ),
                ),
              GestureDetector(
                onTap: onNewAnnouncement,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TatvaColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, size: 14, color: TatvaColors.primary),
                    const SizedBox(width: 4),
                    Text('New',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: TatvaColors.primary)),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          if (announcements.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('No announcements yet',
                  style: TextStyle(fontSize: 13, color: TatvaColors.neutral400)),
            )
          else
            ...announcements.take(3).toList().asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnnouncementCard(
                    announcement: e.value,
                    currentUid: uid,
                    currentRole: 'Teacher',
                    isFirst: e.key == 0,
                    onLike: () => onToggleAnnouncementLike(e.value),
                    onEdit: () => onEditAnnouncement(e.value),
                    onDelete: () => onDeleteAnnouncement(e.value),
                  ),
                )),
          if (activityFeed.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  const Expanded(child: Text('Recent Activity',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: TatvaColors.neutral900))),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ActivityListScreen(
                            api: api, classId: firstClassId, title: 'Activity'))),
                    child: const Text('See All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TatvaColors.info)),
                  ),
                ])),
            const SizedBox(height: 12),
            ...activityFeed.take(5).map((event) {
              final icon = activity_helpers.activityIcon(event.type);
              final ago = event.createdAt != null
                  ? activity_helpers.formatTimeAgo(event.createdAt!)
                  : '';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(children: [
                  Icon(icon, size: 20, color: TatvaColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: TatvaColors.neutral900)),
                          if (event.body.isNotEmpty)
                            Text(event.body,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.neutral400)),
                          if (event.actorName.isNotEmpty)
                            Text('by ${event.actorName}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: TatvaColors.neutral400)),
                        ]),
                  ),
                  if (ago.isNotEmpty)
                    Text(ago,
                        style: const TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400)),
                ]),
              );
            }),
          ],
          const SizedBox(height: 28),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Text('My Classes',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900))),
          const SizedBox(height: 12),
          ...classes.asMap().entries.map((e) => _classCard(e.value, e.key)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return GreetingCard(
      gradientColors: const [Color(0xFF1E5C3A), Color(0xFF2E6B4F), Color(0xFF3D8B6B)],
      heroTag: 'teacher_avatar',
      userName: user?.name ?? '',
      subtitle: 'Tatva Academy · Teacher',
      photoUrl: user?.photoUrl ?? '',
      bottomWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: TatvaColors.accent, size: 16),
          const SizedBox(width: 8),
          const Text('Inspiring minds every day! ✨',
              style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  Widget _classCard(ClassModel c, int index) {
    final studentCount = c.studentUids.length;
    return StaggeredItem(
        index: index,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 14),
          decoration: BoxDecoration(
              color: TatvaColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100)),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    TatvaColors.primary.withOpacity(0.12),
                    TatvaColors.primary.withOpacity(0.04)
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.neutral900)),
                      Text(c.subject,
                          style: const TextStyle(
                              fontSize: 12, color: TatvaColors.neutral400)),
                    ])),
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: TatvaColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: TatvaColors.accent.withOpacity(0.3))),
                    child: Text(c.classCode,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: TatvaColors.accent,
                            letterSpacing: 2))),
              ]),
            ),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Icon(Icons.people_outline,
                      color: TatvaColors.neutral400, size: 16),
                  const SizedBox(width: 4),
                  Text('$studentCount students',
                      style: const TextStyle(
                          fontSize: 12, color: TatvaColors.neutral400)),
                ])),
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(children: [
                  GestureDetector(
                      onTap: () => onViewClassStudents(c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.info.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: TatvaColors.info.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.people_outline,
                                color: TatvaColors.info, size: 14),
                            const SizedBox(width: 4),
                            Text('${c.studentUids.length} Students',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.info,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap: () => onSwitchTab(5),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color:
                                      TatvaColors.primary.withOpacity(0.2))),
                          child: Row(children: [
                            Icon(Icons.edit_outlined,
                                color: TatvaColors.primary, size: 14),
                            const SizedBox(width: 4),
                            const Text('Grades',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: TatvaColors.primary,
                                    fontWeight: FontWeight.w600))
                          ]))),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => onDeleteClass(c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: TatvaColors.error.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: TatvaColors.error.withOpacity(0.2))),
                          child: Icon(Icons.delete_outline_rounded,
                              color: TatvaColors.error, size: 16))),
                ])),
          ]),
        ));
  }

}
