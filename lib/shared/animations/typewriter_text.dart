import 'package:flutter/material.dart';

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
