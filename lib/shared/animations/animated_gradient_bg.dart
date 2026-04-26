import 'package:flutter/material.dart';

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
