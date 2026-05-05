import 'package:flutter/material.dart';
import '../theme/colors.dart';

class TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class TatvaBottomNavBar extends StatelessWidget {
  final List<TabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color accentColor;
  final Map<int, int> badges;

  const TatvaBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.accentColor = const Color(0xFF2E6B4F),
    this.badges = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TatvaColors.bgCard,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentColor.withOpacity(0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isActive ? item.activeIcon : item.icon,
                                key: ValueKey(isActive),
                                color: isActive
                                    ? accentColor
                                    : TatvaColors.neutral400,
                                size: 20,
                              ),
                            ),
                            if ((badges[index] ?? 0) > 0)
                              Positioned(
                                right: -8,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: TatvaColors.error,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                                  child: Text(
                                    '${badges[index]!}',
                                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            fontSize: 9,
                            color: isActive
                                ? accentColor
                                : TatvaColors.neutral400,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                          ),
                          child: Text(item.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
