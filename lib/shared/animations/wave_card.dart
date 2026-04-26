import 'dart:math';
import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final double animValue;
  final Color color;

  WavePainter(this.animValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.65);

    for (double x = 0; x <= size.width; x++) {
      final y = sin((x / size.width * 2 * pi) + (animValue * 2 * pi)) * 12 +
          size.height * 0.65;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);

    for (double x = 0; x <= size.width; x++) {
      final y =
          sin((x / size.width * 2 * pi) + (animValue * 2 * pi) + pi / 2) * 10 +
              size.height * 0.75;
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(WavePainter old) => true;
}

class WaveCard extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const WaveCard({
    super.key,
    required this.child,
    required this.gradientColors,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  _WaveCardState createState() => _WaveCardState();
}

class _WaveCardState extends State<WaveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(vsync: this, duration: Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        boxShadow: widget.boxShadow,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveCtrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: WavePainter(_waveCtrl.value, Colors.white),
                  );
                },
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}
