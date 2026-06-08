import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/app_provider.dart';

class WeeklyComparison extends StatelessWidget {
  const WeeklyComparison({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Mock data - in production, track weekly urges
    final thisWeekUrges = 2;
    final lastWeekUrges = 5;
    final improvement = lastWeekUrges > 0
        ? ((lastWeekUrges - thisWeekUrges) / lastWeekUrges * 100).toInt()
        : 0;
    final isImproving = improvement > 0;

    return GlowCard(
      glowColor: isImproving ? AppColors.accent : AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isImproving ? AppColors.accent : AppColors.warning)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isImproving
                      ? Icons.trending_up_rounded
                      : Icons.trending_flat_rounded,
                  color: isImproving ? AppColors.accent : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 Weekly Progress',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('This week vs last week',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WeekCard(
                  label: 'Last Week',
                  value: '$lastWeekUrges',
                  subtitle: 'urges',
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeekCard(
                  label: 'This Week',
                  value: '$thisWeekUrges',
                  subtitle: 'urges',
                  color: isImproving ? AppColors.accent : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isImproving ? AppColors.accent : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isImproving ? AppColors.accent : AppColors.warning)
                    .withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImproving ? Icons.arrow_upward_rounded : Icons.remove_rounded,
                  color: isImproving ? AppColors.accent : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isImproving
                      ? '$improvement% Better!'
                      : 'Keep pushing!',
                  style: TextStyle(
                    color: isImproving ? AppColors.accent : AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                duration: 2000.ms,
                color: (isImproving ? AppColors.accent : AppColors.warning)
                    .withOpacity(0.3),
              ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0);
  }
}

class _WeekCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _WeekCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
