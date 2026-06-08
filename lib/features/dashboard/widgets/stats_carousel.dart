import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/app_provider.dart';

class StatsCarousel extends StatelessWidget {
  const StatsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final successRate = provider.urgesResisted > 0 
        ? (provider.urgesResisted / (provider.urgesResisted + 3) * 100).toInt() 
        : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ModernStatCard(
                icon: Icons.shield_rounded,
                value: '${provider.urgesResisted}',
                label: 'Urges Resisted',
                color: AppColors.accent,
                delay: 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                icon: Icons.access_time_rounded,
                value: provider.timeSavedLabel,
                label: 'Time Saved',
                color: AppColors.primary,
                delay: 200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ModernStatCard(
                icon: Icons.block_rounded,
                value: '${provider.blockedSites.length}',
                label: 'Sites Blocked',
                color: AppColors.danger,
                delay: 300,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _ModernStatCard(
                icon: Icons.trending_up_rounded,
                value: '$successRate%',
                label: 'Success Rate',
                color: AppColors.warning,
                delay: 400,
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _ModernStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int delay;

  const _ModernStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}