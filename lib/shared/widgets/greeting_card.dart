import 'package:flutter/material.dart';
import '../animations/animations.dart';
import '../theme/colors.dart';
import '../utils/greeting.dart';

class GreetingCard extends StatelessWidget {
  final List<Color> gradientColors;
  final String heroTag;
  final String userName;
  final String subtitle;
  final String photoUrl;
  final Widget? bottomWidget;
  final VoidCallback? onTap;

  const GreetingCard({
    super.key,
    required this.gradientColors,
    required this.heroTag,
    required this.userName,
    required this.subtitle,
    this.photoUrl = '',
    this.bottomWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: gradientColors,
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
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
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
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
                                  fontWeight: FontWeight.w500)),
                        ]),
                        const SizedBox(height: 6),
                        TypewriterText(
                          text: userName,
                          delayMs: 400,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  HeroAvatar(
                    heroTag: heroTag,
                    initial: userName.isNotEmpty ? userName[0] : '?',
                    radius: 26,
                    bgColor: Colors.white.withOpacity(0.15),
                    textColor: Colors.white,
                    borderColor: Colors.white.withOpacity(0.3),
                    photoUrl: photoUrl,
                  ),
                ]),
                if (bottomWidget != null) ...[
                  const SizedBox(height: 16),
                  bottomWidget!,
                ],
              ],
            ),
          ),
        ]),
      ),
    ));
  }
}
