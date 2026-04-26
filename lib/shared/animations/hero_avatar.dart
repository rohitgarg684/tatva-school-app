import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HeroAvatar extends StatelessWidget {
  final String initial;
  final double radius;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final String heroTag;

  const HeroAvatar({
    super.key,
    required this.initial,
    required this.radius,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            PageRouteBuilder(
              opaque: false,
              barrierColor: Colors.black54,
              barrierDismissible: true,
              pageBuilder: (_, __, ___) => _AvatarZoomScreen(
                heroTag: heroTag,
                initial: initial,
                bgColor: bgColor,
                textColor: textColor,
              ),
              transitionDuration: Duration(milliseconds: 350),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ));
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          padding: borderColor != null ? EdgeInsets.all(2) : EdgeInsets.zero,
          decoration: borderColor != null
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [borderColor!, bgColor]))
              : null,
          child: CircleAvatar(
            radius: radius,
            backgroundColor: bgColor,
            child: Text(
              initial.toUpperCase(),
              style: TextStyle(
                  fontSize: radius * 0.75,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarZoomScreen extends StatelessWidget {
  final String heroTag;
  final String initial;
  final Color bgColor;
  final Color textColor;

  const _AvatarZoomScreen(
      {required this.heroTag,
      required this.initial,
      required this.bgColor,
      required this.textColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Hero(
            tag: heroTag,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: bgColor,
              child: Text(
                initial.toUpperCase(),
                style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
