import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../teacher/teacher_dashboard.dart';
import '../parent/child_picker_screen.dart';
import '../principal/principal_dashboard.dart';
import '../../shared/animations/animations.dart';
import '../../services/auth_service.dart';
import '../../models/user_role.dart';
import '../../core/router/app_router.dart';
import '../../repositories/auth_repository.dart';

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

  bool _emailLoading = false;
  bool _socialLoading = false;
  bool obscurePassword = true;
  bool _showConfetti = false;
  String emailError = '';
  String passwordError = '';
  String generalError = '';

  bool get _busy => _emailLoading || _socialLoading;

  static const Color bg1 = Color(0xFF1B3A2D);
  static const Color bg2 = Color(0xFF2D4A1E);
  static const Color accent = Color(0xFFE8A020);
  static const Color accentLight = Color(0xFFF0BC50);
  static const Color textWhite = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFF8FAF8F);
  static const Color fieldBg = Color(0xFF1E3828);

  static const _studentBlockedMsg =
      'Student accounts cannot log in. Please use a parent account.';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final _authService = AuthService();

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

  // ── Helpers ──────────────────────────────────────────────────────────

  bool get _showAppleButton =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  void _setError(String msg) {
    if (mounted) setState(() => generalError = msg);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('user-not-found') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('too-many-requests')) {
      return 'Too many attempts. Please wait and try again.';
    }
    if (msg.contains('network')) {
      return 'No internet connection. Please check and retry.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Blocks student roles with sign-out. Returns `true` if blocked.
  Future<bool> _blockStudentRole(UserRole role) async {
    if (role != UserRole.student) return false;
    await _authService.signOut();
    _setError(_studentBlockedMsg);
    return true;
  }

  void _navigateToDashboard(UserRole role) {
    HapticFeedback.mediumImpact();
    setState(() => _showConfetti = true);
    Future.delayed(Duration(milliseconds: 900), () {
      if (!mounted) return;
      final Widget dashboard;
      switch (role) {
        case UserRole.teacher:
          dashboard = TeacherDashboard();
        case UserRole.parent:
          dashboard = ChildPickerScreen();
        case UserRole.principal:
          dashboard = PrincipalDashboard();
        default:
          dashboard = ChildPickerScreen();
      }
      Navigator.pushReplacement(context, TatvaPageRoute.slideUp(dashboard));
    });
  }

  // ── Email login ──────────────────────────────────────────────────────

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

  Future<void> _login() async {
    if (!_validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _emailLoading = true);

    try {
      final result = await _authService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (await _blockStudentRole(result.role)) return;

      _navigateToDashboard(result.role);
    } on UnverifiedEmailException {
      _setError('Please verify your email first. Check your inbox.');
    } on UserNotFoundException {
      _setError('User profile not found. Please register first.');
    } catch (e) {
      _setError(_friendlyError(e));
      HapticFeedback.vibrate();
    }
    if (mounted) setState(() => _emailLoading = false);
  }

  // ── Social login ─────────────────────────────────────────────────────

  Future<void> _handleSocialSignIn(
    Future<SocialSignInResult> Function() signIn,
  ) async {
    HapticFeedback.lightImpact();
    setState(() {
      _socialLoading = true;
      generalError = '';
    });

    try {
      final result = await signIn();

      if (result.isNewUser || result.role == null) {
        if (!mounted) return;
        final pickedRole = await _showRolePicker();
        if (pickedRole == null) {
          await _authService.signOut();
          if (mounted) setState(() => _socialLoading = false);
          return;
        }
        if (await _blockStudentRole(pickedRole)) return;

        final profile =
            await _authService.completeSocialProfile(role: pickedRole);
        _navigateToDashboard(profile.role);
        return;
      }

      if (await _blockStudentRole(result.role!)) return;

      _navigateToDashboard(result.role!);
    } on SignInCancelledException {
      // User cancelled native flow — no-op
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'cancelled') return;
      _setError(_friendlyError(e));
    } catch (e) {
      _setError(_friendlyError(e));
    }
    if (mounted) setState(() => _socialLoading = false);
  }

  // ── Forgot password ──────────────────────────────────────────────────

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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textWhite)),
                SizedBox(height: 8),
                Text('We sent a reset link to\n${emailController.text.trim()}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

  // ── Role picker ──────────────────────────────────────────────────────

  Future<UserRole?> _showRolePicker() {
    UserRole selected = UserRole.parent;
    return showModalBottomSheet<UserRole>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Color(0xFF243D2F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(28, 16, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text('Choose your role',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textWhite)),
              SizedBox(height: 6),
              Text('How will you use Tatva Academy?',
                  style: TextStyle(fontSize: 13, color: textMuted)),
              SizedBox(height: 20),
              for (final role in [UserRole.parent, UserRole.teacher, UserRole.principal])
                _RolePickerTile(
                  role: role,
                  selected: selected == role,
                  onTap: () => setSheetState(() => selected = role),
                ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text('Continue',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

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
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textWhite)),
                      SizedBox(height: 6),
                      Text('Sign in to your Tatva Academy account',
                          style: TextStyle(
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
                        onSubmitted: (_) => _login(),
                        style: TextStyle(
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
                                          fontSize: 13,
                                          color: Colors.red.shade300))),
                            ],
                          ),
                        ),
                      _PressableButton(
                        onPressed: _busy ? null : _login,
                        color: accent,
                        child: _emailLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text('Sign In',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white12)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or continue with',
                                style: TextStyle(
                                    fontSize: 12, color: textMuted)),
                          ),
                          Expanded(child: Divider(color: Colors.white12)),
                        ],
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              onPressed: _busy
                                  ? null
                                  : () => _handleSocialSignIn(
                                      _authService.signInWithGoogle),
                              icon: const _GoogleIcon(),
                              label: 'Google',
                              backgroundColor: fieldBg,
                            ),
                          ),
                          if (_showAppleButton) ...[
                            SizedBox(width: 12),
                            Expanded(
                              child: _SocialButton(
                                onPressed: _busy
                                    ? null
                                    : () => _handleSocialSignIn(
                                        _authService.signInWithApple),
                                icon: Icon(Icons.apple,
                                    color: textWhite, size: 22),
                                label: 'Apple',
                                backgroundColor: fieldBg,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_socialLoading)
                        Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: accent, strokeWidth: 2),
                            ),
                          ),
                        ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Don't have an account?",
                              style: TextStyle(
                                  fontSize: 13,
                                  color: textMuted)),
                          TextButton(
                            onPressed: () => AppRouter.toRegisterReplacement(context),
                            style: TextButton.styleFrom(
                                padding: EdgeInsets.only(left: 4)),
                            child: Text('Register',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: accentLight,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Center(
                          child: Text('v1.0.0',
                              style: TextStyle(
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
                    fontSize: 12,
                    color: Colors.red.shade300)),
          ],
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon, String error) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(fontSize: 13, color: Colors.white24),
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
}

// ── Extracted widgets ────────────────────────────────────────────────────

class _RolePickerTile extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RolePickerTile({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  static const _icons = {
    UserRole.parent: Icons.family_restroom,
    UserRole.teacher: Icons.school,
    UserRole.principal: Icons.admin_panel_settings,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _LoginScreenState.accent.withOpacity(0.15)
                : _LoginScreenState.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _LoginScreenState.accent : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _icons[role] ?? Icons.person,
                color: selected
                    ? _LoginScreenState.accent
                    : _LoginScreenState.textMuted,
                size: 22,
              ),
              SizedBox(width: 12),
              Text(role.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? _LoginScreenState.textWhite
                        : _LoginScreenState.textMuted,
                  )),
              Spacer(),
              if (selected)
                Icon(Icons.check_circle,
                    color: _LoginScreenState.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.96, h * 0.42)
        ..lineTo(w * 0.50, h * 0.42)
        ..lineTo(w * 0.50, h * 0.58)
        ..lineTo(w * 0.77, h * 0.58)
        ..cubicTo(w * 0.73, h * 0.72, w * 0.62, h * 0.80, w * 0.50, h * 0.80)
        ..cubicTo(w * 0.33, h * 0.80, w * 0.20, h * 0.67, w * 0.20, h * 0.50)
        ..cubicTo(w * 0.20, h * 0.33, w * 0.33, h * 0.20, w * 0.50, h * 0.20)
        ..cubicTo(w * 0.58, h * 0.20, w * 0.65, h * 0.23, w * 0.71, h * 0.29)
        ..lineTo(w * 0.82, h * 0.18)
        ..cubicTo(w * 0.74, h * 0.10, w * 0.63, h * 0.05, w * 0.50, h * 0.05)
        ..cubicTo(w * 0.25, h * 0.05, w * 0.05, h * 0.25, w * 0.05, h * 0.50)
        ..cubicTo(w * 0.05, h * 0.75, w * 0.25, h * 0.95, w * 0.50, h * 0.95)
        ..cubicTo(w * 0.75, h * 0.95, w * 0.98, h * 0.75, w * 0.96, h * 0.42)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.05, h * 0.50)
        ..cubicTo(w * 0.05, h * 0.75, w * 0.25, h * 0.95, w * 0.50, h * 0.95)
        ..cubicTo(w * 0.62, h * 0.95, w * 0.73, h * 0.90, w * 0.80, h * 0.82)
        ..lineTo(w * 0.65, h * 0.72)
        ..cubicTo(w * 0.61, h * 0.77, w * 0.56, h * 0.80, w * 0.50, h * 0.80)
        ..cubicTo(w * 0.38, h * 0.80, w * 0.28, h * 0.72, w * 0.23, h * 0.60)
        ..lineTo(w * 0.07, h * 0.72)
        ..cubicTo(w * 0.05, h * 0.65, w * 0.05, h * 0.58, w * 0.05, h * 0.50)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.23, h * 0.60)
        ..cubicTo(w * 0.21, h * 0.55, w * 0.20, h * 0.53, w * 0.20, h * 0.50)
        ..cubicTo(w * 0.20, h * 0.47, w * 0.21, h * 0.45, w * 0.23, h * 0.40)
        ..lineTo(w * 0.07, h * 0.28)
        ..cubicTo(w * 0.05, h * 0.35, w * 0.05, h * 0.42, w * 0.05, h * 0.50)
        ..cubicTo(w * 0.05, h * 0.58, w * 0.05, h * 0.65, w * 0.07, h * 0.72)
        ..lineTo(w * 0.23, h * 0.60)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.50, h * 0.20)
        ..cubicTo(w * 0.58, h * 0.20, w * 0.65, h * 0.23, w * 0.71, h * 0.29)
        ..lineTo(w * 0.82, h * 0.18)
        ..cubicTo(w * 0.74, h * 0.10, w * 0.63, h * 0.05, w * 0.50, h * 0.05)
        ..cubicTo(w * 0.35, h * 0.05, w * 0.22, h * 0.12, w * 0.12, h * 0.24)
        ..lineTo(w * 0.07, h * 0.28)
        ..lineTo(w * 0.23, h * 0.40)
        ..cubicTo(w * 0.28, h * 0.28, w * 0.38, h * 0.20, w * 0.50, h * 0.20)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SocialButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String label;
  final Color backgroundColor;

  const _SocialButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _LoginScreenState.textWhite,
                  )),
            ],
          ),
        ),
      ),
    );
  }
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
