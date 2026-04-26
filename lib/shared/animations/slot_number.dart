import 'package:flutter/material.dart';

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
