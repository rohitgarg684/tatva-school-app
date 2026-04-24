import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../student/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../principal/principal_dashboard.dart';
import '../../shared/animations/animations.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';
import '../../core/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  bool isLoading = false;
  bool obscurePassword = true;
  bool _showConfetti = false;
  String emailError = '';
  String passwordError = '';
  String generalError = '';

  static const Color bg1 = Color(0xFF1B3A2D);
  static const Color bg2 = Color(0xFF2D4A1E);
  static const Color accent = Color(0xFFE8A020);
  static const Color accentLight = Color(0xFFF0BC50);
  static const Color textWhite = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFF8FAF8F);
  static const Color fieldBg = Color(0xFF1E3828);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 700));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: Offset(0, 0.2), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      emailError = '';
      passwordError = '';
      generalError = '';
    });
    if (emailController.text.trim().isEmpty) {
      setState(() => emailError = 'Please enter your email');
      valid = false;
    } else if (!emailController.text.contains('@')) {
      setState(() => emailError = 'Please enter a valid email');
      valid = false;
    }
    if (passwordController.text.isEmpty) {
      setState(() => passwordError = 'Please enter your password');
      valid = false;
    }
    return valid;
  }

  final _authService = AuthService();

  Future<void> login() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => isLoading = true);

    try {
      final result = await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (result == null) throw UserNotFoundException();

      HapticFeedback.mediumImpact();
      setState(() => _showConfetti = true);
      await Future.delayed(Duration(milliseconds: 900));

      if (mounted) {
        final Widget dashboard;
        switch (result.role) {
          case UserRole.teacher:
            dashboard = TeacherDashboard();
            break;
          case UserRole.parent:
            dashboard = ParentDashboard();
            break;
          case UserRole.principal:
            dashboard = PrincipalDashboard();
            break;
          default:
            dashboard = StudentDashboard();
        }
        Navigator.pushReplacement(
            context, TatvaPageRoute.slideUp(dashboard));
      }
    } on UnverifiedEmailException {
      if (!mounted) return;
      setState(() {
        generalError = 'Please verify your email first. Check your inbox.';
      });
    } on UserNotFoundException {
      if (!mounted) return;
      setState(() {
        generalError = 'User profile not found. Please register first.';
      });
    } catch (e) {
      String msg = e.toString();
      if (!mounted) return;
      setState(() {
        if (msg.contains('user-not-found') ||
            msg.contains('wrong-password') ||
            msg.contains('invalid-credential')) {
          generalError = 'Incorrect email or password. Please try again.';
        } else if (msg.contains('too-many-requests')) {
          generalError = 'Too many attempts. Please wait and try again.';
        } else if (msg.contains('network')) {
          generalError = 'No internet connection. Please check and retry.';
        } else {
          generalError = 'Something went wrong. Please try again.';
        }
      });
      HapticFeedback.vibrate();
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _forgotPassword() async {
    if (emailController.text.trim().isEmpty) {
      setState(() => emailError = 'Enter your email above first');
      return;
    }
    try {
      await _authService.sendPasswordReset(
          email: emailController.text.trim());
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            decoration: BoxDecoration(
                color: Color(0xFF243D2F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
                SizedBox(height: 20),
                Icon(Icons.mark_email_read_rounded, size: 48, color: accent),
                SizedBox(height: 16),
                Text('Check your email!',
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textWhite)),
                SizedBox(height: 8),
                Text('We sent a reset link to\n${emailController.text.trim()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 13,
                        color: textMuted,
                        height: 1.5)),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        elevation: 0),
                    child: Text('Got it',
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(
          () => emailError = 'Could not send reset email. Check the address.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      trigger: _showConfetti,
      child: Scaffold(
        backgroundColor: bg1,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textWhite),
          systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light),
        ),
        body: AnimatedGradientBg(
          gradients: [
            [Color(0xFF1B3A2D), Color(0xFF2D4A1E)],
            [Color(0xFF1E3828), Color(0xFF243D2F)],
            [Color(0xFF1B3A2D), Color(0xFF2D4A1E)],
          ],
          duration: Duration(seconds: 8),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Center(
                        child: Hero(
                          tag: 'tatva_logo',
                          child:
                              Image.asset('assets/tatva_logo.png', height: 64),
                        ),
                      ),
                      SizedBox(height: 28),
                      Text('Welcome back 👋',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textWhite)),
                      SizedBox(height: 6),
                      Text('Sign in to your Tatva Academy account',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 13,
                              color: textMuted)),
                      SizedBox(height: 32),
                      _label('Email Address'),
                      SizedBox(height: 6),
                      TextField(
                        controller: emailController,
                        focusNode: emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(passwordFocus),
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textWhite),
                        decoration: _inputDecoration('Enter your email',
                            Icons.email_outlined, emailError),
                      ),
                      if (emailError.isNotEmpty) _errorText(emailError),
                      SizedBox(height: 20),
                      _label('Password'),
                      SizedBox(height: 6),
                      TextField(
                        controller: passwordController,
                        focusNode: passwordFocus,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => login(),
                        style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 14,
                            color: textWhite),
                        decoration: _inputDecoration('Enter your password',
                                Icons.lock_outline, passwordError)
                            .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: textMuted,
                                size: 20),
                            onPressed: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                        ),
                      ),
                      if (passwordError.isNotEmpty) _errorText(passwordError),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size(0, 0)),
                          child: Text('Forgot password?',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 13,
                                  color: accentLight,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (generalError.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade900.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.shade400.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  color: Colors.red.shade300, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(generalError,
                                      style: TextStyle(
                                          fontFamily: 'Raleway',
                                          fontSize: 13,
                                          color: Colors.red.shade300))),
                            ],
                          ),
                        ),
                      _PressableButton(
                        onPressed: isLoading ? null : login,
                        color: accent,
                        child: isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Sign In',
                                style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _trustBadge(Icons.lock_outline, 'Secure'),
                          SizedBox(width: 24),
                          _trustBadge(Icons.shield_outlined, 'Role-Based'),
                          SizedBox(width: 24),
                          _trustBadge(Icons.school_outlined, 'Tatva'),
                        ],
                      ),
                      SizedBox(height: 20),
                      Center(
                          child: Text('v1.0.0',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 10,
                                  color: Colors.white24))),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          fontFamily: 'Raleway',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textWhite));

  Widget _errorText(String text) => Padding(
        padding: EdgeInsets.only(top: 6, left: 4),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 13, color: Colors.red.shade300),
            SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 12,
                    color: Colors.red.shade300)),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon, String error) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(fontFamily: 'Raleway', fontSize: 13, color: Colors.white24),
      prefixIcon: Icon(icon,
          color: error.isEmpty ? textMuted : Colors.red.shade300, size: 20),
      filled: true,
      fillColor: error.isEmpty ? fieldBg : Colors.red.shade900.withOpacity(0.2),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: error.isEmpty
                  ? Colors.white12
                  : Colors.red.shade400.withOpacity(0.4))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color:
                  error.isEmpty ? accent.withOpacity(0.6) : Colors.red.shade400,
              width: 1.5)),
    );
  }

  Widget _trustBadge(IconData icon, String label) => Column(
        children: [
          Icon(icon, size: 18, color: accent),
          SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Raleway', fontSize: 10, color: textMuted)),
        ],
      );
}

class _PressableButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Color color;
  final Widget child;
  const _PressableButton(
      {required this.onPressed, required this.color, required this.child});

  @override
  __PressableButtonState createState() => __PressableButtonState();
}

class __PressableButtonState extends State<_PressableButton>
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
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          _ctrl.forward();
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: widget.onPressed != null ? widget.color : Colors.white10,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.onPressed != null
                ? [
                    BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 16,
                        offset: Offset(0, 6))
                  ]
                : [],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
