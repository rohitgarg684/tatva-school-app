import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/animations/animations.dart';
import '../../models/user_role.dart';
import '../../core/router/app_router.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _glowController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _progressAnim;
  late Animation<double> _glowAnim;

  static const Color accent = Color(0xFFE8A020);
  static const Color textWhite = Color(0xFFF5F0E8);
  static const Color textMuted = Color(0xFF8FAF8F);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    _logoController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));

    _textController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _textFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut)));

    _progressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3000));
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    _logoController.forward();
    Future.delayed(
        const Duration(milliseconds: 600), () => _textController.forward());
    _progressController.forward();
    Future.delayed(const Duration(milliseconds: 3200), _navigate);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _navigate() async {
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;

    if (!onboardingDone) {
      _pushFade(const OnboardingScreen());
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final tokenResult = await firebaseUser.getIdTokenResult();
        final roleStr = tokenResult.claims?['role'] as String?;
        if (roleStr != null && mounted) {
          final role = UserRole.fromString(roleStr);
          AppRouter.toDashboardAndClearStack(context, role);
          return;
        }
      } catch (_) {}
    }

    if (mounted) _pushFade(const LoginScreen());
  }

  void _pushFade(Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child),
      ),
    );
  }

  String _getLoadingText(double progress) {
    if (progress < 0.3) return 'Initializing secure connection...';
    if (progress < 0.6) return 'Verifying credentials...';
    if (progress < 0.85) return 'Loading your workspace...';
    return 'Almost ready...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBg(
        gradients: const [
          [Color(0xFF0F2318), Color(0xFF1B3A2D)],
          [Color(0xFF1A2E22), Color(0xFF243D2F)],
          [Color(0xFF0F2318), Color(0xFF1E3828)],
        ],
        duration: const Duration(seconds: 6),
        child: Stack(children: [
          Positioned.fill(
              child:
                  FloatingParticles(color: const Color(0xFFE8A020), count: 20)),
          Positioned.fill(
              child:
                  FloatingParticles(color: const Color(0xFF4CAF7D), count: 14)),
          Positioned(
              top: -100,
              right: -100,
              child: _bgCircle(300, const Color(0xFF2E6B4F).withOpacity(0.08))),
          Positioned(
              bottom: -80,
              left: -80,
              child: _bgCircle(250, const Color(0xFFE8A020).withOpacity(0.05))),
          SafeArea(
            child: Column(children: [
              Expanded(
                child: Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: AnimatedBuilder(
                              animation: _glowAnim,
                              builder: (context, child) => Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                        color: accent
                                            .withOpacity(_glowAnim.value * 0.4),
                                        blurRadius: 60,
                                        spreadRadius: 10),
                                    BoxShadow(
                                        color: const Color(0xFF2E6B4F)
                                            .withOpacity(_glowAnim.value * 0.3),
                                        blurRadius: 40,
                                        spreadRadius: 5),
                                  ],
                                ),
                                child: Hero(
                                  tag: 'tatva_logo',
                                  child: Image.asset('assets/tatva_logo.png',
                                      height: 110, width: 110),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(children: [
                              const Text('Tatva Academy',
                                  style: TextStyle(
                                      fontFamily: 'Raleway',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: textWhite,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 10),
                              FadeTransition(
                                opacity: _taglineFade,
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                          width: 20,
                                          height: 1,
                                          color: accent.withOpacity(0.5)),
                                      const SizedBox(width: 10),
                                      const Text(
                                          'Empowering Academic Excellence',
                                          style: TextStyle(
                                              fontFamily: 'Raleway',
                                              fontSize: 13,
                                              color: textMuted,
                                              letterSpacing: 0.8)),
                                      const SizedBox(width: 10),
                                      Container(
                                          width: 20,
                                          height: 1,
                                          color: accent.withOpacity(0.5)),
                                    ]),
                              ),
                            ]),
                          ),
                        ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(children: [
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, child) => Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progressAnim.value,
                          minHeight: 2,
                          backgroundColor: Colors.white.withOpacity(0.08),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(_getLoadingText(_progressAnim.value),
                          style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 12,
                              color: textMuted)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _trustBadge(Icons.lock_outline, 'Secure'),
                    const SizedBox(width: 20),
                    _trustBadge(Icons.shield_outlined, 'Encrypted'),
                    const SizedBox(width: 20),
                    _trustBadge(Icons.verified_outlined, 'Trusted'),
                  ]),
                  const SizedBox(height: 16),
                  const Text('v1.0.0',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 10,
                          color: Colors.white12)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _bgCircle(double size, Color color) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _trustBadge(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white24),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Raleway', fontSize: 11, color: Colors.white24)),
        ],
      );
}
