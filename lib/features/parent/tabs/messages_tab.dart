import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/animations/animations.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../models/user_model.dart';
import '../../messaging/messaging_screen.dart';

class ParentMessagesTab extends StatefulWidget {
  final List<ChildDashboardData> currentChildEntries;
  final ApiService api;

  const ParentMessagesTab({
    super.key,
    required this.currentChildEntries,
    required this.api,
  });

  @override
  State<ParentMessagesTab> createState() => _ParentMessagesTabState();
}

class _ParentMessagesTabState extends State<ParentMessagesTab> {
  List<UserModel> _principals = [];
  bool _principalsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrincipals();
  }

  Future<void> _loadPrincipals() async {
    try {
      final raw = await widget.api.getUsersByRole('Principal');
      if (mounted) {
        setState(() {
          _principals = raw.map((m) => UserModel.fromJson(m)).toList();
          _principalsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _principalsLoaded = true);
    }
  }

  List<_ContactInfo> get _contacts {
    final seen = <String>{};
    final list = <_ContactInfo>[];

    for (final e in widget.currentChildEntries) {
      final uid = e.info.teacherUid;
      if (uid.isEmpty || seen.contains(uid)) continue;
      seen.add(uid);
      list.add(_ContactInfo(
        uid: uid,
        name: e.info.teacherName,
        email: e.info.teacherEmail,
        role: 'Teacher',
        subtitle: '${e.info.subject} · ${e.info.className}',
        color: TatvaColors.primary,
      ));
    }

    for (final p in _principals) {
      if (seen.contains(p.uid)) continue;
      seen.add(p.uid);
      list.add(_ContactInfo(
        uid: p.uid,
        name: p.name,
        email: p.email,
        role: 'Principal',
        subtitle: 'School Principal',
        photoUrl: p.photoUrl,
        color: TatvaColors.purple,
      ));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts;

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
            child: const Text('Connect with teachers & principal',
                style: TextStyle(fontSize: 13, color: TatvaColors.neutral400))),
        const SizedBox(height: 20),
        if (!_principalsLoaded)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator()))
        else if (contacts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.chat_outlined, color: TatvaColors.neutral400, size: 48),
                const SizedBox(height: 12),
                const Text('No contacts available',
                    style: TextStyle(fontSize: 15, color: TatvaColors.neutral400)),
              ]),
            ),
          )
        else
          ...contacts.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return StaggeredItem(
              index: i,
              child: GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => MessagingScreen(
                              otherUserId: c.uid,
                              otherUserName: c.name,
                              otherUserRole: c.role,
                              otherUserEmail: c.email,
                              otherPhotoUrl: c.photoUrl,
                              avatarColor: c.color,
                            ))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: TatvaColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100)),
                  child: Row(children: [
                    UserAvatar(
                        name: c.name,
                        radius: 22,
                        bgColor: c.color.withOpacity(0.1),
                        textColor: c.color,
                        photoUrl: c.photoUrl),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(c.name,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: TatvaColors.neutral900)),
                          Text(c.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: TatvaColors.neutral400)),
                        ])),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                            color: c.color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: c.color.withOpacity(0.15))),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.chat_outlined, color: c.color, size: 13),
                          const SizedBox(width: 4),
                          Text('Chat',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: c.color,
                                  fontWeight: FontWeight.w600)),
                        ])),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }
}

class _ContactInfo {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String subtitle;
  final String photoUrl;
  final Color color;

  const _ContactInfo({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.subtitle,
    this.photoUrl = '',
    required this.color,
  });
}
