import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/dashboard_service.dart';
import '../../repositories/auth_repository.dart';
import '../../shared/theme/colors.dart';
import '../../shared/animations/page_routes.dart';
import '../../shared/animations/animations.dart';
import 'parent_dashboard.dart';

/// Netflix-style profile picker shown when a parent has multiple children.
/// If only one child exists, navigates directly to the dashboard.
class ChildPickerScreen extends StatefulWidget {
  const ChildPickerScreen({super.key});

  @override
  State<ChildPickerScreen> createState() => _ChildPickerScreenState();
}

class _ChildPickerScreenState extends State<ChildPickerScreen>
    with SingleTickerProviderStateMixin {
  final _dashSvc = DashboardService();
  ParentDashboardData? _data;
  bool _loading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _avatarColors = [
    Color(0xFF6A1B9A),
    Color(0xFF1E88E5),
    Color(0xFFE8A020),
    Color(0xFF43A047),
    Color(0xFFE53935),
    Color(0xFF00897B),
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uid = AuthRepository().currentUid ?? '';
      final data =
          await _dashSvc.loadParentDashboard(overrideUid: uid, forceRefresh: true);
      if (!mounted) return;

      final uniqueNames = data.childrenData
          .map((c) => c.info.childName)
          .toSet();
      if (uniqueNames.length <= 1) {
        _goToDashboard(0);
        return;
      }

      setState(() {
        _data = data;
        _loading = false;
      });
      _animCtrl.forward();
    } catch (_) {
      if (!mounted) return;
      _goToDashboard(0);
    }
  }

  void _goToDashboard(int childIndex) {
    HapticFeedback.selectionClick();
    Navigator.pushReplacement(
      context,
      TatvaPageRoute.slideUp(ParentDashboard(initialChildIndex: childIndex)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: TatvaColors.bgLight,
        body: Center(child: CircularProgressIndicator(color: TatvaColors.purple)),
      );
    }

    final children = _data!.childrenData;
    final userName = _data!.user.name;

    // Group by unique child name, keeping the first index for each
    final seen = <String>{};
    final uniqueChildren = <({int firstIndex, String name, String className})>[];
    for (var i = 0; i < children.length; i++) {
      final name = children[i].info.childName;
      if (seen.add(name)) {
        uniqueChildren.add((
          firstIndex: i,
          name: name,
          className: children[i].info.className,
        ));
      }
    }

    return Scaffold(
      backgroundColor: TatvaColors.bgLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              const SizedBox(height: 48),
              Text('Welcome, $userName',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: TatvaColors.neutral900)),
              const SizedBox(height: 8),
              const Text("Who's profile would you like to view?",
                  style: TextStyle(fontSize: 14, color: TatvaColors.neutral400)),
              const SizedBox(height: 48),
              Expanded(
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 32,
                    children: List.generate(uniqueChildren.length, (i) {
                      final uc = uniqueChildren[i];
                      final color = _avatarColors[i % _avatarColors.length];
                      final initials = _initials(uc.name);
                      return _ProfileTile(
                        name: uc.name,
                        className: uc.className,
                        color: color,
                        initials: initials,
                        delay: i * 100,
                        onTap: () => _goToDashboard(uc.firstIndex),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _ProfileTile extends StatefulWidget {
  final String name;
  final String className;
  final Color color;
  final String initials;
  final int delay;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.name,
    required this.className,
    required this.color,
    required this.initials,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_ProfileTile> createState() => _ProfileTileState();
}

class _ProfileTileState extends State<_ProfileTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: BouncyTap(
          onTap: widget.onTap,
          child: SizedBox(
            width: 130,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: widget.color.withOpacity(0.4), width: 2.5),
                  ),
                  child: Center(
                    child: Text(widget.initials,
                        style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: widget.color)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TatvaColors.neutral900)),
                if (widget.className.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(widget.className,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 11, color: TatvaColors.neutral400)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
