import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../student/student_dashboard.dart';
import '../teacher/teacher_dashboard.dart';
import '../parent/parent_dashboard.dart';
import '../principal/principal_dashboard.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const Color bg = Color(0xFF1B3A2D);
  static const Color accent = Color(0xFFE8A020);
  static const Color textW = Color(0xFFF5F0E8);
  static const Color textMut = Color(0xFF8FAF8F);

  void _go(BuildContext ctx, Widget screen) {
    HapticFeedback.lightImpact();
    Navigator.push(
        ctx,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2318), Color(0xFF1B3A2D), Color(0xFF2D4A1E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              // Logo row
              Row(children: [
                Hero(
                  tag: 'tatva_logo',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2E6B4F),
                      border: Border.all(
                          color: accent.withOpacity(0.4), width: 1.5),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/tatva_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text('T',
                              style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: accent)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tatva Academy',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textW)),
                      Text('Academic Management',
                          style: TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 10,
                              color: textMut,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.2)),
                    ]),
              ]),
              const SizedBox(height: 44),
              const Text('Choose a role\nto preview',
                  style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textW,
                      height: 1.15,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('Explore each dashboard with sample data',
                  style: TextStyle(
                      fontFamily: 'Raleway', fontSize: 14, color: textMut)),
              const SizedBox(height: 36),
              _roleCard(context, '🎓', 'Student', 'Arjun Mehta · Grade 8-A',
                  const Color(0xFF1E88E5), const StudentDashboard()),
              const SizedBox(height: 12),
              _roleCard(
                  context,
                  '🧑‍🏫',
                  'Teacher',
                  'Mrs. Priya Sharma · Mathematics',
                  const Color(0xFF2E6B4F),
                  const TeacherDashboard()),
              const SizedBox(height: 12),
              _roleCard(
                  context,
                  '👨‍👩‍👧',
                  'Parent',
                  'Mr. Suresh Mehta · Parent of Arjun',
                  const Color(0xFF8E24AA),
                  const ParentDashboard()),
              const SizedBox(height: 12),
              _roleCard(
                  context,
                  '🏫',
                  'Principal',
                  'Dr. Anjali Nair · Tatva Academy',
                  const Color(0xFFE8A020),
                  const PrincipalDashboard()),
              const Spacer(),
              Center(
                  child: Text('Swipe back anytime to switch roles',
                      style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 12,
                          color: textMut.withOpacity(0.6)))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(BuildContext ctx, String emoji, String role, String subtitle,
      Color color, Widget screen) {
    return GestureDetector(
      onTap: () => _go(ctx, screen),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(role,
                    style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textW)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Raleway', fontSize: 12, color: textMut)),
              ])),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_forward_rounded, color: color, size: 16),
          ),
        ]),
      ),
    );
  }
}
