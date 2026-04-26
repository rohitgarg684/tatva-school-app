import 'package:flutter/material.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../models/user_model.dart';
import '../../../models/child_info.dart';

class ParentProfileTab extends StatelessWidget {
  final UserModel? user;
  final ChildDashboardData? currentChild;
  final VoidCallback onShowTeacherProfile;
  final VoidCallback onGenerateReport;
  final VoidCallback onLogout;

  const ParentProfileTab({
    super.key,
    required this.user,
    required this.currentChild,
    required this.onShowTeacherProfile,
    required this.onGenerateReport,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final child = currentChild;
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          FadeSlideIn(
              child: HeroAvatar(
                  heroTag: 'parent_avatar',
                  initial: user?.initial ?? '?',
                  radius: 46,
                  bgColor: TatvaColors.purple.withOpacity(0.1),
                  textColor: TatvaColors.purple,
                  borderColor: TatvaColors.accent)),
          const SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 80,
              child: Text(user?.name ?? '',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.5))),
          const SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 100,
              child: Text(user?.email ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 10),
          FadeSlideIn(
              delayMs: 120,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                      color: TatvaColors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('Parent',
                      style: TextStyle(
                          fontSize: 12,
                          color: TatvaColors.purple,
                          fontWeight: FontWeight.w700)))),
          const SizedBox(height: 28),
          FadeSlideIn(
              delayMs: 130,
              child: GestureDetector(
                onTap: onShowTeacherProfile,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: TatvaColors.primary.withOpacity(0.15))),
                  child: Row(children: [
                    CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            TatvaColors.primary.withOpacity(0.1),
                        child: Text(
                            (child?.info.teacherName ?? '').isNotEmpty
                                ? child!.info.teacherName[0]
                                : '?',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: TatvaColors.primary))),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(child?.info.teacherName ?? '',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.neutral900)),
                          Text(
                              "${child?.info.childName ?? ''}'s Teacher · ${child?.info.subject ?? ''}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: TatvaColors.neutral400)),
                          const SizedBox(height: 3),
                          Row(children: [
                            const Icon(Icons.email_outlined,
                                size: 11, color: TatvaColors.info),
                            const SizedBox(width: 4),
                            Text(child?.info.teacherEmail ?? '',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: TatvaColors.info)),
                          ]),
                        ])),
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: TatvaColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: TatvaColors.primary)),
                  ]),
                ),
              )),
          ...List.generate(4, (i) {
            final items = [
              [
                Icons.child_care_outlined,
                'Child',
                child?.info.childName ?? ''
              ],
              [Icons.school_outlined, 'School', 'Tatva Academy'],
              [Icons.class_outlined, 'Class', child?.info.className ?? ''],
              [Icons.verified_outlined, 'Status', 'Verified'],
            ];
            return StaggeredItem(
                index: i,
                child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: RippleTap(
                        rippleColor: TatvaColors.purple,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgCard,
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: Colors.grey.shade100)),
                          child: Row(children: [
                            Icon(items[i][0] as IconData,
                                color: TatvaColors.purple, size: 18),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(items[i][1] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: TatvaColors.neutral400))),
                            Text(items[i][2] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: TatvaColors.neutral900,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ))));
          }),
          const SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 180,
              child: BouncyTap(
                  onTap: onGenerateReport,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.info.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TatvaColors.info.withOpacity(0.15))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assessment_outlined,
                              color: TatvaColors.info, size: 18),
                          const SizedBox(width: 8),
                          const Text('Weekly Report',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.info)),
                        ]),
                  ))),
          const SizedBox(height: 12),
          FadeSlideIn(
              delayMs: 200,
              child: BouncyTap(
                  onTap: onLogout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.error.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TatvaColors.error.withOpacity(0.15))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: TatvaColors.error, size: 18),
                          const SizedBox(width: 8),
                          const Text('Sign Out',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.error)),
                        ]),
                  ))),
          const SizedBox(height: 16),
          const Text('v1.0.0 · Tatva Academy',
              style:
                  TextStyle(fontSize: 11, color: TatvaColors.neutral400)),
          const SizedBox(height: 24),
        ]));
  }
}
