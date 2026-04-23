import 'package:flutter/material.dart';
import '../animations/animations.dart';
import '../theme/colors.dart';

class GreetingCardStat {
  final String value;
  final String label;

  const GreetingCardStat({required this.value, required this.label});
}

class GreetingCard extends StatelessWidget {
  final String userName;
  final String roleLabel;
  final String heroTag;
  final Color accentColor;
  final List<Color> gradientColors;
  final List<GreetingCardStat> stats;

  const GreetingCard({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.heroTag,
    required this.accentColor,
    required this.gradientColors,
    this.stats = const [],
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '🌤️';
    if (h < 17) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: WaveCard(
        gradientColors: gradientColors,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 48,
            offset: const Offset(0, 20),
          ),
        ],
        child: Stack(
          children: [
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(_greetingEmoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  _greeting,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TypewriterText(
                              text: userName,
                              delayMs: 400,
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tatva Academy · $roleLabel',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
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
                      ),
                    ],
                  ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                        height: 1, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (int i = 0; i < stats.length; i++) ...[
                          if (i > 0)
                            Container(
                              width: 1,
                              height: 28,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  stats[i].value,
                                  style: const TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stats[i].label,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.55),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
