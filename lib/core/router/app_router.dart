import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../shared/animations/animations.dart';
import '../factory/dashboard_factory.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/messaging/messaging_screen.dart';

class AppRouter {
  AppRouter._();

  static void toSplash(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  static void toWelcomeAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static void toLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  static void toLoginReplacement(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  static void toLoginAndClearStack(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  static void toRegister(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  static void toRegisterReplacement(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  static void toDashboard(BuildContext context, UserRole role) {
    Navigator.pushReplacement(
      context,
      TatvaPageRoute.slideUp(DashboardFactory.create(role)),
    );
  }

  static void toDashboardAndClearStack(BuildContext context, UserRole role) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => DashboardFactory.create(role)),
      (route) => false,
    );
  }

  static void toMessaging(
    BuildContext context, {
    required String otherUserId,
    required String otherUserName,
    required String otherUserRole,
    required String otherUserEmail,
    String otherPhotoUrl = '',
    Color avatarColor = const Color(0xFF2E6B4F),
  }) {
    Navigator.push(
      context,
      TatvaPageRoute.slideRight(
        MessagingScreen(
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserRole: otherUserRole,
          otherUserEmail: otherUserEmail,
          otherPhotoUrl: otherPhotoUrl,
          avatarColor: avatarColor,
        ),
      ),
    );
  }
}
