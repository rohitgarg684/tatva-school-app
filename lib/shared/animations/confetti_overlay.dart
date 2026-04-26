import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConfettiOverlay extends StatefulWidget {
  final Widget child;
  final bool trigger;

  const ConfettiOverlay({super.key, required this.child, this.trigger = false});

  @override
  _ConfettiOverlayState createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_ConfettiPiece> pieces;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2500));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showing = false);
      }
    });
    _generatePieces();
  }

  void _generatePieces() {
    final rng = Random();
    pieces = List.generate(60, (_) => _ConfettiPiece(rng));
  }

  @override
  void didUpdateWidget(ConfettiOverlay old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger) {
      _generatePieces();
      setState(() => _showing = true);
      _ctrl.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showing)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(pieces, _ctrl.value),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPiece {
  double x, speed, size, angle, rotSpeed, drift;
  Color color;

  _ConfettiPiece(Random rng)
      : x = rng.nextDouble(),
        speed = rng.nextDouble() * 0.4 + 0.2,
        size = rng.nextDouble() * 8 + 4,
        angle = rng.nextDouble() * pi * 2,
        rotSpeed = (rng.nextDouble() - 0.5) * 8,
        drift = (rng.nextDouble() - 0.5) * 0.3,
        color = [
          Color(0xFFE8A020),
          Color(0xFF2E6B4F),
          Color(0xFF4CAF7D),
          Color(0xFFF0BC50),
          Color(0xFF1E88E5),
          Color(0xFF43A047),
          Color(0xFFFFFFFF),
        ][rng.nextInt(7)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter(this.pieces, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final y = progress * p.speed * size.height * 2;
      if (y > size.height + 20) continue;
      final x = p.x * size.width + sin(progress * 3 + p.drift * 10) * 30;
      final opacity =
          progress > 0.7 ? (1 - (progress - 0.7) / 0.3).clamp(0.0, 1.0) : 1.0;
      final paint = Paint()
        ..color = p.color.withOpacity(opacity * 0.85)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.angle + progress * p.rotSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.5),
            Radius.circular(1)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
