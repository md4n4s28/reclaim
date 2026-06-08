import 'package:flutter/material.dart';
import 'theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  
  const BottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                active: currentIndex == 0,
                onTap: () => _navigate(context, '/dashboard', 0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Progress',
                active: currentIndex == 1,
                onTap: () => _navigate(context, '/progress', 1),
              ),
              _NavItem(
                icon: Icons.block_rounded,
                label: 'Block',
                active: currentIndex == 2,
                onTap: () => _navigate(context, '/block', 2),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                active: currentIndex == 3,
                onTap: () => _navigate(context, '/settings', 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, String route, int index) {
    if (currentIndex != index) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Export for use in other files
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({this.currentIndex = 0});

  @override
  Widget build(BuildContext context) {
    return BottomNav(currentIndex: currentIndex);
  }
}
