import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';

class ProfileTab extends StatelessWidget {
  final UserModel? user;
  final int teacherCount;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.user,
    required this.teacherCount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 16),
          FadeSlideIn(
            child: HeroAvatar(
              heroTag: 'principal_avatar',
              initial: user?.initial ?? 'P',
              radius: 46,
              bgColor: TatvaColors.purple.withOpacity(0.1),
              textColor: TatvaColors.purple,
              borderColor: TatvaColors.accent,
            ),
          ),
          SizedBox(height: 16),
          FadeSlideIn(
              delayMs: 80,
              child: Text(user?.name ?? '',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.5))),
          SizedBox(height: 4),
          FadeSlideIn(
              delayMs: 100,
              child: Text(user?.email ?? '',
                  style: TextStyle(
                      fontSize: 13,
                      color: TatvaColors.neutral400))),
          SizedBox(height: 10),
          FadeSlideIn(
            delayMs: 120,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                  color: TatvaColors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('Principal',
                  style: TextStyle(
                      fontSize: 12,
                      color: TatvaColors.purple,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(height: 32),
          ...List.generate(4, (index) {
            final items = [
              [
                Icons.school_outlined,
                'School',
                'Tatva Academy'
              ],
              [
                Icons.people_outline,
                'Staff',
                '$teacherCount Teachers'
              ],
              [
                Icons.email_outlined,
                'Email',
                (user?.email ?? '').length > 24
                    ? (user?.email ?? '').substring(0, 24) +
                        '...'
                    : (user?.email ?? '')
              ],
              [
                Icons.verified_outlined,
                'Status',
                'Verified'
              ],
            ];
            return StaggeredItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: 10),
                child: RippleTap(
                  rippleColor: TatvaColors.purple,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: TatvaColors.bgCard,
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.grey.shade100)),
                    child: Row(children: [
                      Icon(items[index][0] as IconData,
                          color: TatvaColors.purple,
                          size: 18),
                      SizedBox(width: 14),
                      Expanded(
                          child: Text(
                              items[index][1] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: TatvaColors
                                      .neutral400))),
                      Text(items[index][2] as String,
                          style: TextStyle(
                              fontSize: 13,
                              color: TatvaColors.neutral900,
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
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: TatvaColors.error.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TatvaColors.error
                            .withOpacity(0.15))),
                child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: TatvaColors.error, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: TatvaColors.error)),
                    ]),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text('v1.0.0 · Tatva Academy',
              style: TextStyle(
                  fontSize: 11,
                  color: TatvaColors.neutral400)),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
