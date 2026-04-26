import 'package:flutter/material.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/announcement_card.dart';
import '../../parent/parent_helpers.dart';
import '../../../shared/utils/greeting.dart';
import '../../../models/user_model.dart';
import '../../../models/class_model.dart';
import '../../../models/announcement_model.dart';
import '../../../models/homework_model.dart';
import '../../../models/activity_event.dart';

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
                _statCard('${classes.length}', 'Classes',
                    Icons.class_outlined, TatvaColors.primary),
                const SizedBox(width: 10),
                _statCard('$totalStudents', 'Students',
                    Icons.people_outline, TatvaColors.info),
                const SizedBox(width: 10),
                _statCard('$activeHw', 'Homework',
                    Icons.assignment_outlined, TatvaColors.accent),
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
                _qaBtn('Enter\nGrades', Icons.edit_note_outlined,
                    TatvaColors.accent, () => onSwitchTab(5)),
                const SizedBox(width: 8),
                _qaBtn('Post\nHomework', Icons.assignment_outlined,
                    TatvaColors.primary, () => onSwitchTab(6)),
                const SizedBox(width: 8),
                _qaBtn('Behavior', Icons.emoji_events_outlined,
                    TatvaColors.info, () => onSwitchTab(2)),
                const SizedBox(width: 8),
                _qaBtn('Messages', Icons.chat_outlined, TatvaColors.purple,
                    () => onSwitchTab(8)),
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
                    isFirst: e.key == 0,
                    onLike: () => onToggleAnnouncementLike(e.value),
                  ),
                )),
          if (activityFeed.isNotEmpty) ...[
            const SizedBox(height: 28),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text('Recent Activity',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: TatvaColors.neutral900))),
            const SizedBox(height: 12),
            ...activityFeed.take(5).map((event) {
              final icon = switch (event.type.name) {
                'behaviorPoint' => Icons.star,
                'attendance' => Icons.check_circle,
                'homeworkAssigned' => Icons.assignment,
                'gradeEntered' => Icons.grade,
                'announcement' => Icons.campaign,
                'storyPost' => Icons.photo_camera,
                _ => Icons.circle,
              };
              final ago =
                  event.createdAt != null ? formatTimeAgo(event.createdAt!) : '';
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
              color: TatvaColors.primary.withOpacity(0.35),
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
                              Text(Greeting.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(Greeting.text,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w500))
                            ]),
                            const SizedBox(height: 6),
                            TypewriterText(
                                text: user?.name ?? '',
                                delayMs: 400,
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1)),
                            const SizedBox(height: 4),
                            Text('Tatva Academy · Teacher',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.6))),
                          ])),
                      HeroAvatar(
                          heroTag: 'teacher_avatar',
                          initial: user?.initial ?? '?',
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
                              color: TatvaColors.accent, size: 16),
                          const SizedBox(width: 8),
                          const Text('Inspiring minds every day! ✨',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500))
                        ])),
                  ])),
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

  Widget _statCard(
          String value, String label, IconData icon, Color color) =>
      Expanded(
          child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: TatvaColors.bgCard,
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900,
                  letterSpacing: -0.5)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: TatvaColors.neutral400,
                  fontWeight: FontWeight.w500)),
        ]),
      ));

  Widget _qaBtn(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      Expanded(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                decoration: BoxDecoration(
                    color: TatvaColors.bgCard,
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
                          fontSize: 10,
                          color: TatvaColors.neutral600,
                          fontWeight: FontWeight.w600,
                          height: 1.3)),
                ]),
              )));

}
