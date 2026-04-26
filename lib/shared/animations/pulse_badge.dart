import 'package:flutter/material.dart';

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
