import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
