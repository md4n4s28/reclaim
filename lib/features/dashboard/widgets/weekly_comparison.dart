import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/app_provider.dart';

class WeeklyComparison extends StatelessWidget {
  const WeeklyComparison({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Calculate real relapses
    final now = DateTime.now();
    
    // Create a list of 7 days for the current week ending today
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dayLabels = days.map((d) {
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekDays[d.weekday - 1];
    }).toList();

    // Map relapses to these 7 days
    final weekData = List.filled(7, 0);
    int thisWeekUrges = 0;
    int lastWeekUrges = 0;

    final startOfThisWeek = now.subtract(const Duration(days: 7));
    final startOfLastWeek = now.subtract(const Duration(days: 14));

    for (final relapse in provider.relapses) {
      // Calculate daily distribution for chart
      for (int i = 0; i < 7; i++) {
        if (relapse.year == days[i].year && relapse.month == days[i].month && relapse.day == days[i].day) {
          weekData[i]++;
        }
      }
      
      // Calculate totals
      if (relapse.isAfter(startOfThisWeek)) {
        thisWeekUrges++;
      } else if (relapse.isAfter(startOfLastWeek)) {
        lastWeekUrges++;
      }
    }

    final improvement = lastWeekUrges > 0
        ? ((lastWeekUrges - thisWeekUrges) / lastWeekUrges * 100).toInt()
        : (thisWeekUrges == 0 ? 100 : 0); // 100% improvement if 0 this week and 0 last week
    final isImproving = thisWeekUrges <= lastWeekUrges;

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
                    Text('This week vs last week relapses',
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
                  subtitle: 'relapses',
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _WeekCard(
                  label: 'This Week',
                  value: '$thisWeekUrges',
                  subtitle: 'relapses',
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
                      ? (thisWeekUrges == 0 && lastWeekUrges == 0 ? 'Perfect!' : '$improvement% Better!')
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
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: weekData.reduce((curr, next) => curr > next ? curr : next).toDouble() + 1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        dayLabels[v.toInt()],
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weekData.asMap().entries.map((e) {
                  final isToday = e.key == 6; // Last item is always today
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.toDouble(),
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.4),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
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
