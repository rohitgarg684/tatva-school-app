import 'package:flutter/material.dart';
import '../../messaging/messaging_screen.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/theme/colors.dart';
import '../../../models/user_model.dart';

class TeacherMessagesTab extends StatelessWidget {
  final List<UserModel> parents;

  const TeacherMessagesTab({super.key, required this.parents});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),
          FadeSlideIn(
              child: const Text('Messages',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900,
                      letterSpacing: -0.8))),
          FadeSlideIn(
              delayMs: 60,
              child: const Text('Communicate with parents',
                  style: TextStyle(
                      fontSize: 13, color: TatvaColors.neutral400))),
          const SizedBox(height: 20),
          ...parents.asMap().entries.map((e) {
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
                                    otherUserRole:
                                        'Parent · ${p.children.isNotEmpty ? p.children.first.childName : ''}',
                                    otherUserEmail: p.email,
                                    avatarColor: TatvaColors.primary,
                                  ))),
                      child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: TatvaColors.bgCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100)),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    TatvaColors.primary.withOpacity(0.1),
                                child: Text(p.initial,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: TatvaColors.primary))),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: TatvaColors.neutral900)),
                                  Text(
                                      'Parent of ${p.children.isNotEmpty ? p.children.first.childName : ''}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: TatvaColors.neutral400)),
                                ])),
                            Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color:
                                        TatvaColors.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: TatvaColors.primary
                                            .withOpacity(0.15))),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_outlined,
                                          color: TatvaColors.primary,
                                          size: 13),
                                      const SizedBox(width: 4),
                                      const Text('Message',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: TatvaColors.primary,
                                              fontWeight: FontWeight.w600))
                                    ])),
                          ])),
                    )));
          }),
        ]));
  }
}
