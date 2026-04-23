import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ============================================================
// TATVA ACADEMY — GLOBAL DESIGN SYSTEM
// Every color, spacing, typography and style lives here.
// Never hardcode values in screens — always reference this.
// ============================================================

class TatvaColors {
  TatvaColors._();

  // Primary
  static const Color primary = Color(0xFF2E6B4F);
  static const Color primaryLight = Color(0xFF4CAF7D);
  static const Color primaryDark = Color(0xFF1B3A2D);

  // Accent (saffron gold — Chinmaya brand)
  static const Color accent = Color(0xFFE8A020);
  static const Color accentLight = Color(0xFFF0BC50);
  static const Color accentDark = Color(0xFFB87A10);

  // Neutrals (900 → 50)
  static const Color neutral900 = Color(0xFF1A2E22);
  static const Color neutral800 = Color(0xFF243D2F);
  static const Color neutral700 = Color(0xFF2E6B4F);
  static const Color neutral600 = Color(0xFF4A6B55);
  static const Color neutral500 = Color(0xFF6B8F76);
  static const Color neutral400 = Color(0xFF8FAF8F);
  static const Color neutral300 = Color(0xFFB5CDB5);
  static const Color neutral200 = Color(0xFFD8EAD8);
  static const Color neutral100 = Color(0xFFEEF7EE);
  static const Color neutral50 = Color(0xFFF4F9F4);

  // Semantic
  static const Color success = Color(0xFF43A047);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFE8A020);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1E88E5);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Background
  static const Color bgLight = Color(0xFFF4F9F4);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgDark = Color(0xFF1B3A2D);
  static const Color bgDarkCard = Color(0xFF243D2F);

  // Dark mode
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkText = Color(0xFFF5F0E8);
  static const Color darkTextMuted = Color(0xFF8FAF8F);
}

class TatvaSpacing {
  TatvaSpacing._();

  // Strict 8pt grid — use ONLY these values
  static const double xs = 8.0;
  static const double sm = 16.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 40.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Screen padding
  static const double screenH = 20.0;
  static const double screenV = 24.0;

  // Card padding
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0;

  // Button
  static const double buttonHeight = 52.0;
  static const double buttonRadius = 14.0;

  // Input
  static const double inputRadius = 12.0;
  static const double inputPaddingV = 14.0;
  static const double inputPaddingH = 16.0;
}

class TatvaText {
  TatvaText._();

  static const String fontFamily = 'Raleway';

  // Display
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.0,
    height: 1.1,
    color: TatvaColors.neutral900,
  );

  // H1
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    height: 1.2,
    color: TatvaColors.neutral900,
  );

  // H2
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    height: 1.3,
    color: TatvaColors.neutral900,
  );

  // H3
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: TatvaColors.neutral900,
  );

  // Body large
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: TatvaColors.neutral600,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: TatvaColors.neutral600,
  );

  // Body small
  static const TextStyle bodySm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: TatvaColors.neutral600,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.4,
    color: TatvaColors.neutral400,
  );

  // Tiny
  static const TextStyle tiny = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: TatvaColors.neutral400,
  );

  // Button
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  // Label
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: TatvaColors.neutral900,
  );
}

class TatvaTheme {
  TatvaTheme._();

  static ThemeData get light => ThemeData(
        fontFamily: TatvaText.fontFamily,
        scaffoldBackgroundColor: TatvaColors.bgLight,
        primaryColor: TatvaColors.primary,
        colorScheme: ColorScheme.light(
          primary: TatvaColors.primary,
          secondary: TatvaColors.accent,
          surface: TatvaColors.bgCard,
          error: TatvaColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: TatvaColors.neutral900),
          titleTextStyle: TatvaText.h3.copyWith(color: TatvaColors.neutral900),
        ),
        cardTheme: CardTheme(
          color: TatvaColors.bgCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TatvaSpacing.cardRadius),
            side: BorderSide(color: TatvaColors.neutral200),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TatvaColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, TatvaSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TatvaSpacing.buttonRadius)),
            elevation: 0,
            textStyle: TatvaText.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TatvaColors.neutral50,
          contentPadding: EdgeInsets.symmetric(
              horizontal: TatvaSpacing.inputPaddingH,
              vertical: TatvaSpacing.inputPaddingV),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(color: TatvaColors.neutral200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(
                  color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide:
                  BorderSide(color: TatvaColors.error.withOpacity(0.4))),
          hintStyle: TatvaText.bodySm.copyWith(color: TatvaColors.neutral300),
          labelStyle: TatvaText.label,
        ),
        dividerTheme: DividerThemeData(
            color: TatvaColors.neutral200, thickness: 1, space: 1),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? TatvaColors.accent
                  : Colors.transparent),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: BorderSide(color: TatvaColors.neutral300, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentTextStyle: TatvaText.body.copyWith(color: Colors.white),
        ),
      );

  static ThemeData get dark => ThemeData(
        fontFamily: TatvaText.fontFamily,
        scaffoldBackgroundColor: TatvaColors.darkBg,
        primaryColor: TatvaColors.primary,
        colorScheme: ColorScheme.dark(
          primary: TatvaColors.primary,
          secondary: TatvaColors.accent,
          surface: TatvaColors.darkCard,
          error: TatvaColors.error,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: TatvaColors.darkText),
          titleTextStyle: TatvaText.h3.copyWith(color: TatvaColors.darkText),
        ),
        cardTheme: CardTheme(
          color: TatvaColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TatvaSpacing.cardRadius),
            side: BorderSide(color: TatvaColors.darkBorder),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: TatvaColors.primary,
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, TatvaSpacing.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TatvaSpacing.buttonRadius)),
            elevation: 0,
            textStyle: TatvaText.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: TatvaColors.darkCard,
          contentPadding: EdgeInsets.symmetric(
              horizontal: TatvaSpacing.inputPaddingH,
              vertical: TatvaSpacing.inputPaddingV),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(color: TatvaColors.darkBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
              borderSide: BorderSide(
                  color: TatvaColors.primary.withOpacity(0.5), width: 1.5)),
          hintStyle: TatvaText.bodySm.copyWith(color: TatvaColors.neutral500),
          labelStyle: TatvaText.label.copyWith(color: TatvaColors.darkText),
        ),
      );
}

// ============================================================
// REUSABLE WIDGETS — use these everywhere for consistency
// ============================================================

class TatvaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double? radius;

  const TatvaCard(
      {super.key,
      required this.child,
      this.padding,
      this.onTap,
      this.color,
      this.radius});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? EdgeInsets.all(TatvaSpacing.cardPadding),
        decoration: BoxDecoration(
          color: color ?? (isDark ? TatvaColors.darkCard : TatvaColors.bgCard),
          borderRadius:
              BorderRadius.circular(radius ?? TatvaSpacing.cardRadius),
          border: Border.all(
              color: isDark ? TatvaColors.darkBorder : TatvaColors.neutral200),
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
  _TatvaButtonState createState() => _TatvaButtonState();
}

class _TatvaButtonState extends State<TatvaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: Duration(milliseconds: 100));
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
          duration: Duration(milliseconds: 150),
          width: double.infinity,
          height: widget.height ?? TatvaSpacing.buttonHeight,
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (enabled ? color : TatvaColors.neutral200),
            borderRadius: BorderRadius.circular(TatvaSpacing.buttonRadius),
            border: widget.isOutlined
                ? Border.all(
                    color: enabled ? color : TatvaColors.neutral300, width: 1.5)
                : null,
            boxShadow: !widget.isOutlined && enabled
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 6))
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
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
                                  ? (enabled ? color : TatvaColors.neutral300)
                                  : Colors.white)),
                      if (widget.icon != null) ...[
                        SizedBox(width: TatvaSpacing.xs),
                        Icon(widget.icon,
                            color: widget.isOutlined ? color : Colors.white,
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
                color: isDark ? TatvaColors.darkText : TatvaColors.neutral900)),
        SizedBox(height: TatvaSpacing.xs),
        TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword ? obscure : false,
          keyboardType: keyboardType,
          textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
          onSubmitted: onSubmitted ??
              (isLast
                  ? null
                  : (_) {
                      if (nextFocus != null)
                        FocusScope.of(context).requestFocus(nextFocus);
                    }),
          onChanged: onChanged,
          style: TatvaText.body.copyWith(
              color: isDark ? TatvaColors.darkText : TatvaColors.neutral900),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color:
                        hasError ? TatvaColors.error : TatvaColors.neutral400,
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
                borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide(
                    color: hasError
                        ? TatvaColors.error.withOpacity(0.4)
                        : (isDark
                            ? TatvaColors.darkBorder
                            : TatvaColors.neutral200))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide(
                    color: hasError
                        ? TatvaColors.error
                        : TatvaColors.primary.withOpacity(0.5),
                    width: 1.5)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TatvaSpacing.inputRadius),
                borderSide: BorderSide.none),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 13, color: TatvaColors.error),
              SizedBox(width: 4),
              Text(error,
                  style: TatvaText.caption.copyWith(color: TatvaColors.error)),
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

  const TatvaShimmer(
      {super.key,
      required this.width,
      required this.height,
      required this.animation,
      this.radius});

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
              colors: [Color(0xFFE8F0E8), Color(0xFFF5FAF5), Color(0xFFE8F0E8)],
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

  const TatvaBadge(
      {super.key, required this.label, required this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  const TatvaSectionHeader(
      {super.key,
      required this.title,
      required this.icon,
      this.badge = 0,
      this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TatvaColors.primary, size: 18),
        SizedBox(width: TatvaSpacing.xs),
        Text(title, style: TatvaText.h3),
        if (badge > 0) ...[
          SizedBox(width: TatvaSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: TatvaColors.error,
                borderRadius: BorderRadius.circular(10)),
            child: Text('$badge',
                style: TatvaText.tiny.copyWith(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
        Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
                style: TatvaText.caption.copyWith(
                    color: TatvaColors.primary, fontWeight: FontWeight.w600)),
          ),
      ],
    );
  }
}
