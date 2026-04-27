import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color bgColor;
  final Color textColor;
  final String photoUrl;
  final bool useDoubleInitials;

  const UserAvatar({
    super.key,
    required this.name,
    required this.radius,
    required this.bgColor,
    required this.textColor,
    this.photoUrl = '',
    this.useDoubleInitials = false,
  });

  String get _initials {
    if (name.isEmpty) return '?';
    if (!useDoubleInitials) return name[0].toUpperCase();
    return name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      onBackgroundImageError:
          photoUrl.isNotEmpty ? (_, __) {} : null,
      child: photoUrl.isNotEmpty
          ? null
          : Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
    );
  }
}
