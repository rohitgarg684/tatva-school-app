import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// TATVA ACADEMY — GLOBAL ANIMATION UTILITIES v2
// ============================================================

// PAGE TRANSITIONS
class TatvaPageRoute {
  static PageRouteBuilder slideUp(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: 400),
      reverseTransitionDuration: Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.08), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(0, 0.7, curve: Curves.easeOut))),
            child: child,
          ),
        );
      },
    );
  }

  static PageRouteBuilder slideRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: 380),
      reverseTransitionDuration: Duration(milliseconds: 320),
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(
                  parent: animation, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
                parent: animation,
                curve: Interval(0, 0.6, curve: Curves.easeOut))),
            child: child,
          ),
        );
      },
    );
  }

  static PageRouteBuilder fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}

// FLOATING PARTICLES
class FloatingParticles extends StatefulWidget {
  final Color color;
  final int count;

  const FloatingParticles({super.key, required this.color, this.count = 18});

  @override
  _FloatingParticlesState createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late List<_Particle> particles;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    particles = List.generate(widget.count, (_) => _Particle(rng));
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 8))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(particles, _controller.value, widget.color),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity, angle;
  _Particle(Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        size = rng.nextDouble() * 3 + 1,
        speed = rng.nextDouble() * 0.015 + 0.005,
        opacity = rng.nextDouble() * 0.35 + 0.05,
        angle = rng.nextDouble() * pi * 2;
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter(this.particles, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = (p.y - progress * p.speed * 10) % 1.0;
      final x = p.x + sin(progress * pi * 2 + p.angle) * 0.02;
      final paint = Paint()
        ..color = color.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x * size.width, y * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ANIMATED GRADIENT BACKGROUND
class AnimatedGradientBg extends StatefulWidget {
  final List<List<Color>> gradients;
  final Widget child;
  final Duration duration;

  const AnimatedGradientBg({
    super.key,
    required this.gradients,
    required this.child,
    this.duration = const Duration(seconds: 5),
  });

  @override
  _AnimatedGradientBgState createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() =>
            _currentIndex = (_currentIndex + 1) % widget.gradients.length);
        _ctrl.forward(from: 0);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final next = (_currentIndex + 1) % widget.gradients.length;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final colors = List.generate(
          widget.gradients[_currentIndex].length,
          (i) => Color.lerp(widget.gradients[_currentIndex][i],
              widget.gradients[next][i], _ctrl.value)!,
        );
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// CARD FLIP REVEAL
class FlipCard extends StatefulWidget {
  final Widget child;
  final int delayMs;

  const FlipCard({super.key, required this.child, this.delayMs = 0});

  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flip;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _flip = Tween<double>(begin: -pi / 12, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _ctrl, curve: Interval(0, 0.6, curve: Curves.easeOut)));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_flip.value),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// SLOT MACHINE NUMBER
class SlotNumber extends StatefulWidget {
  final double value;
  final String suffix;
  final String prefix;
  final TextStyle style;
  final int decimals;
  final int delayMs;

  const SlotNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.prefix = '',
    this.decimals = 0,
    this.delayMs = 300,
  });

  @override
  _SlotNumberState createState() => _SlotNumberState();
}

class _SlotNumberState extends State<SlotNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1600));
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        String display = widget.decimals > 0
            ? _anim.value.toStringAsFixed(widget.decimals)
            : _anim.value.toInt().toString();
        return ClipRect(
          child: Text(
            '${widget.prefix}$display${widget.suffix}',
            style: widget.style,
          ),
        );
      },
    );
  }
}

// ANIMATED PROGRESS BAR (animates from 0 on enter)
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final Color color;
  final double height;
  final int delayMs;
  final Duration duration;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.delayMs = 400,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  _AnimatedProgressBarState createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height),
          child: LinearProgressIndicator(
            value: _anim.value,
            minHeight: widget.height,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation(widget.color),
          ),
        );
      },
    );
  }
}

// CONFETTI
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

// RIPPLE TAP
class RippleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;
  final BorderRadius? borderRadius;

  const RippleTap({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor = const Color(0xFF2E6B4F),
    this.borderRadius,
  });

  @override
  _RippleTapState createState() => _RippleTapState();
}

class _RippleTapState extends State<RippleTap> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
        splashColor: widget.rippleColor.withOpacity(0.12),
        highlightColor: widget.rippleColor.withOpacity(0.06),
        child: widget.child,
      ),
    );
  }
}

// BOUNCY TAP
class BouncyTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const BouncyTap(
      {super.key, required this.child, this.onTap, this.scale = 0.96});

  @override
  _BouncyTapState createState() => _BouncyTapState();
}

class _BouncyTapState extends State<BouncyTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) async {
        await Future.delayed(Duration(milliseconds: 80));
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// STAGGERED LIST ITEM
class StaggeredItem extends StatefulWidget {
  final Widget child;
  final int index;
  final int delayMs;

  const StaggeredItem(
      {super.key, required this.child, required this.index, this.delayMs = 80});

  @override
  _StaggeredItemState createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}

// COUNTING NUMBER
class CountingNumber extends StatefulWidget {
  final double value;
  final String suffix;
  final String prefix;
  final TextStyle style;
  final int decimals;
  final Duration duration;

  const CountingNumber({
    super.key,
    required this.value,
    required this.style,
    this.suffix = '',
    this.prefix = '',
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  _CountingNumberState createState() => _CountingNumberState();
}

class _CountingNumberState extends State<CountingNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        String display = widget.decimals > 0
            ? _anim.value.toStringAsFixed(widget.decimals)
            : _anim.value.toInt().toString();
        return Text('${widget.prefix}$display${widget.suffix}',
            style: widget.style);
      },
    );
  }
}

// PULSE BADGE
class PulseBadge extends StatefulWidget {
  final int count;
  final Color color;

  const PulseBadge(
      {super.key, required this.count, this.color = const Color(0xFFE53935)});

  @override
  _PulseBadgeState createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1200))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return SizedBox.shrink();
    return ScaleTransition(
      scale: _pulse,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        child: Text('${widget.count}',
            style: TextStyle(
                fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// FADE SLIDE IN
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Offset beginOffset;

  const FadeSlideIn(
      {super.key,
      required this.child,
      this.delayMs = 0,
      this.beginOffset = const Offset(0, 0.1)});

  @override
  _FadeSlideInState createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
        opacity: _fade,
        child: SlideTransition(position: _slide, child: widget.child));
  }
}

// HERO AVATAR — tappable zoom
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
                  fontFamily: 'Raleway',
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
                    fontFamily: 'Raleway',
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

// TYPEWRITER TEXT
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final int delayMs;
  final Duration charDuration;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.delayMs = 0,
    this.charDuration = const Duration(milliseconds: 50),
  });

  @override
  _TypewriterTextState createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _charCount;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds:
              widget.text.length * widget.charDuration.inMilliseconds),
    );
    _charCount = IntTween(begin: 0, end: widget.text.length)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charCount,
      builder: (context, _) {
        return Text(widget.text.substring(0, _charCount.value),
            style: widget.style);
      },
    );
  }
}

// WAVE PAINTER for greeting card
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

// WAVE CARD — greeting card with wave animation
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
