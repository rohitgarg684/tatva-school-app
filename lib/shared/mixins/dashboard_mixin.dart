import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../animations/animations.dart';
import '../theme/colors.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/logout_sheet.dart';
import '../../core/router/app_router.dart';
import '../../repositories/auth_repository.dart';

mixin DashboardMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController shimmerController;
  late AnimationController greetingController;
  late AnimationController tabController;
  late Animation<double> shimmerAnim;
  late Animation<double> greetingFade;
  late Animation<Offset> greetingSlide;
  late Animation<double> greetingScale;
  late Animation<double> tabFade;

  int currentTab = 0;
  bool isLoading = true;

  void initDashboardAnimations() {
    shimmerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    shimmerAnim = Tween<double>(begin: -1, end: 2).animate(shimmerController);

    greetingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    greetingFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: greetingController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut)));
    greetingSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
            CurvedAnimation(
                parent: greetingController,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)));
    greetingScale = Tween<double>(begin: 0.96, end: 1.0).animate(
        CurvedAnimation(
            parent: greetingController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));

    tabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    tabFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: tabController, curve: Curves.easeOut));
  }

  void disposeDashboardAnimations() {
    shimmerController.dispose();
    greetingController.dispose();
    tabController.dispose();
  }

  void onDataLoaded() {
    if (!mounted) return;
    setState(() => isLoading = false);
    greetingController.forward();
    tabController.forward();
  }

  void switchTab(int index) {
    if (index == currentTab) return;
    HapticFeedback.selectionClick();
    tabController.reset();
    setState(() => currentTab = index);
    tabController.forward();
  }

  void logout() {
    LogoutSheet.show(context, onConfirm: () async {
      await AuthRepository().signOut();
      if (context.mounted) {
        AppRouter.toWelcomeAndClearStack(context);
      }
    });
  }

  Widget buildShimmerBox(double width, double height, {double radius = 12}) {
    return AnimatedBuilder(
      animation: shimmerAnim,
      builder: (_, __) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: const [
              Color(0xFFE8F0E8),
              Color(0xFFF5FAF5),
              Color(0xFFE8F0E8),
            ],
            stops: [
              (shimmerAnim.value - 1).clamp(0.0, 1.0),
              shimmerAnim.value.clamp(0.0, 1.0),
              (shimmerAnim.value + 1).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDefaultShimmer() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          buildShimmerBox(double.infinity, 200, radius: 24),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: buildShimmerBox(double.infinity, 88)),
            const SizedBox(width: 10),
            Expanded(child: buildShimmerBox(double.infinity, 88)),
            const SizedBox(width: 10),
            Expanded(child: buildShimmerBox(double.infinity, 88)),
          ]),
          const SizedBox(height: 20),
          buildShimmerBox(double.infinity, 80),
          const SizedBox(height: 10),
          buildShimmerBox(double.infinity, 80),
        ]),
      ),
    );
  }

  Widget buildDashboardScaffold({
    required List<TabItem> tabs,
    required Widget Function() bodyBuilder,
    Widget Function()? shimmerBuilder,
  }) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark));
    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      body: isLoading
          ? (shimmerBuilder?.call() ?? buildDefaultShimmer())
          : SafeArea(
              child: FadeTransition(
                opacity: tabFade,
                child: bodyBuilder(),
              ),
            ),
      bottomNavigationBar: isLoading
          ? null
          : TatvaBottomNavBar(
              items: tabs, currentIndex: currentTab, onTap: switchTab),
    );
  }
}
