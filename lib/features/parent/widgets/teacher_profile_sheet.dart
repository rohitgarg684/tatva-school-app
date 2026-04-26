import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../messaging/messaging_screen.dart';
import '../../../shared/theme/colors.dart';

class TeacherProfileSheet {
  static void show(
    BuildContext context, {
    required String teacherName,
    required String teacherEmail,
    required String teacherUid,
    required String subject,
    required String className,
    required String classCode,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
            color: TatvaColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
              child: Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          CircleAvatar(
              radius: 36,
              backgroundColor: TatvaColors.primary.withOpacity(0.1),
              child: Text(teacherName.isNotEmpty ? teacherName[0] : '?',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.primary))),
          const SizedBox(height: 14),
          Text(teacherName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TatvaColors.neutral900)),
          const SizedBox(height: 4),
          Text('$subject Teacher · $className',
              style: const TextStyle(
                  fontSize: 13, color: TatvaColors.neutral400)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TatvaColors.info.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TatvaColors.info.withOpacity(0.15))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: TatvaColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.email_outlined,
                      color: TatvaColors.info, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('School Email',
                        style: TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400)),
                    const SizedBox(height: 2),
                    Text(teacherEmail,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TatvaColors.neutral900)),
                  ])),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: TatvaColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: TatvaColors.primary.withOpacity(0.1))),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: TatvaColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.class_outlined,
                      color: TatvaColors.primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Class Code',
                        style: TextStyle(
                            fontSize: 11, color: TatvaColors.neutral400)),
                    const SizedBox(height: 2),
                    Text(classCode,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: TatvaColors.primary,
                            letterSpacing: 3)),
                  ])),
            ]),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MessagingScreen(
                            otherUserId: teacherUid,
                            otherUserName: teacherName,
                            otherUserRole: 'Teacher',
                            otherUserEmail: teacherEmail,
                            avatarColor: TatvaColors.primary,
                          )));
            },
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                  color: TatvaColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: TatvaColors.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.chat_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('Send a Message',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
