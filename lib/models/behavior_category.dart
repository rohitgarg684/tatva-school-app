import 'package:flutter/material.dart';

class BehaviorCategory {
  final String id;
  final String name;
  final IconData icon;
  final bool isPositive;

  const BehaviorCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.isPositive = true,
  });

  static const List<BehaviorCategory> defaults = [
    BehaviorCategory(id: 'teamwork', name: 'Teamwork', icon: Icons.group),
    BehaviorCategory(id: 'helping', name: 'Helping Others', icon: Icons.volunteer_activism),
    BehaviorCategory(id: 'respect', name: 'Being Respectful', icon: Icons.handshake),
    BehaviorCategory(id: 'participation', name: 'Participation', icon: Icons.record_voice_over),
    BehaviorCategory(id: 'hard_work', name: 'Hard Work', icon: Icons.workspace_premium),
    BehaviorCategory(id: 'creativity', name: 'Creativity', icon: Icons.palette),
    BehaviorCategory(id: 'leadership', name: 'Leadership', icon: Icons.emoji_events),
    BehaviorCategory(id: 'kindness', name: 'Kindness', icon: Icons.favorite),
    BehaviorCategory(
        id: 'off_task', name: 'Off Task', icon: Icons.phone_android, isPositive: false),
    BehaviorCategory(
        id: 'disruptive', name: 'Disruptive', icon: Icons.volume_up, isPositive: false),
    BehaviorCategory(
        id: 'disrespectful', name: 'Disrespectful', icon: Icons.do_not_disturb, isPositive: false),
    BehaviorCategory(
        id: 'unprepared', name: 'Unprepared', icon: Icons.backpack, isPositive: false),
  ];

  static BehaviorCategory fromId(String id) {
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => BehaviorCategory(id: id, name: id, icon: Icons.star),
    );
  }
}
