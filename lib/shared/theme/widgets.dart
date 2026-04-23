import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class TatvaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;

  const TatvaCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(TatvaSpacing.cardPadding),
        decoration: BoxDecoration(
          color:
              color ?? (isDark ? TatvaColors.darkCard : TatvaColors.bgCard),
          borderRadius:
              BorderRadius.circular(radius ?? TatvaSpacing.cardRadius),
          border: Border.all(
              color:
                  isDark ? TatvaColors.darkBorder : TatvaColors.neutral200),
        ),
        child: child,
      ),
    );
  }
}

class TatvaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isOutlined;
  final bool isLoading;
  final IconData? icon;
  final double? height;

  const TatvaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.isOutlined = false,
    this.isLoading = false,
    this.icon,
    this.height,
  });

  @override
  State<TatvaButton> createState() => _TatvaButtonState();
}

class _TatvaButtonState extends State<TatvaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? TatvaColors.primary;
    final enabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (enabled) {
          _ctrl.forward();
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        _ctrl.reverse();
        if (enabled) widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: widget.height ?? TatvaSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (enabled ? color : TatvaColors.neutral200),
            borderRadius: BorderRadius.circular(TatvaSpacing.buttonRadius),
            border: widget.isOutlined
                ? Border.all(
                    color:
                        enabled ? color : TatvaColors.neutral300, width: 1.5)
                : null,
            boxShadow: !widget.isOutlined && enabled
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label,
                          style: TatvaText.button.copyWith(
                              color: widget.isOutlined
                                  ? (enabled
                                      ? color
                                      : TatvaColors.neutral300)
                                  : Colors.white)),
                      if (widget.icon != null) ...[
                        const SizedBox(width: TatvaSpacing.xs),
                        Icon(widget.icon,
                            color:
                                widget.isOutlined ? color : Colors.white,
                            size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class TatvaTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final String hint;
  final String label;
  final IconData? prefixIcon;
  final String error;
  final bool isPassword;
  final bool obscure;
  final bool isLast;
  final TextInputType keyboardType;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const TatvaTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.nextFocus,
    required this.hint,
    required this.label,
    this.prefixIcon,
    this.error = '',
    this.isPassword = false,
    this.obscure = false,
    this.isLast = false,
    this.keyboardType = TextInputType.text,
    this.onToggleObscure,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TatvaText.label.copyWith(
                color: isDark
                    ? TatvaColors.darkText
                    : TatvaColors.neutral900)),
        const SizedBox(height: TatvaSpacing.xs),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword ? obscure : false,
          keyboardType: keyboardType,
          textInputAction:
              isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: onSubmitted ??
              (isLast
                  ? null
                  : (_) {
                      if (nextFocus != null) {
                        FocusScope.of(context).requestFocus(nextFocus);
                      }
                    }),
          onChanged: onChanged,
          style: TatvaText.body.copyWith(
              color: isDark
                  ? TatvaColors.darkText
                  : TatvaColors.neutral900),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: hasError
                        ? TatvaColors.error
                        : TatvaColors.neutral400,
                    size: 20)
                : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: TatvaColors.neutral400,
                        size: 20),
                    onPressed: onToggleObscure)
                : null,
            filled: true,
            fillColor: hasError
                ? TatvaColors.errorLight
                : (isDark ? TatvaColors.darkCard : TatvaColors.neutral50),
            enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide(
                    color: hasError
                        ? TatvaColors.error.withOpacity(0.4)
                        : (isDark
                            ? TatvaColors.darkBorder
                            : TatvaColors.neutral200))),
            focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide(
                    color: hasError
                        ? TatvaColors.error
                        : TatvaColors.primary.withOpacity(0.5),
                    width: 1.5)),
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide.none),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 13, color: TatvaColors.error),
              const SizedBox(width: 4),
              Text(error,
                  style: TatvaText.caption
                      .copyWith(color: TatvaColors.error)),
            ],
          ),
        ],
      ],
    );
  }
}

class TatvaShimmer extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> animation;
  final double? radius;

  const TatvaShimmer({
    super.key,
    required this.width,
    required this.height,
    required this.animation,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius ?? 12),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8F0E8),
                Color(0xFFF5FAF5),
                Color(0xFFE8F0E8),
              ],
              stops: [
                (animation.value - 1).clamp(0.0, 1.0),
                animation.value.clamp(0.0, 1.0),
                (animation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TatvaBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const TatvaBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TatvaText.caption.copyWith(
              color: textColor ?? color, fontWeight: FontWeight.w600)),
    );
  }
}

class TatvaSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int badge;
  final VoidCallback? onSeeAll;

  const TatvaSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.badge = 0,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TatvaColors.primary, size: 18),
        const SizedBox(width: TatvaSpacing.xs),
        Text(title, style: TatvaText.h3),
        if (badge > 0) ...[
          const SizedBox(width: TatvaSpacing.xs),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: TatvaColors.error,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$badge',
                style: TatvaText.tiny.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
                style: TatvaText.caption.copyWith(
                    color: TatvaColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
