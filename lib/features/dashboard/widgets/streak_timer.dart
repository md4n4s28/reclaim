import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme.dart';
import '../../../core/app_provider.dart';

class StreakTimerHero extends StatefulWidget {
  const StreakTimerHero({super.key});

  @override
  State<StreakTimerHero> createState() => _StreakTimerHeroState();
}

class _StreakTimerHeroState extends State<StreakTimerHero> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatClock(Duration d) {
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  int _getNextMilestone(int days) {
    if (days < 3) return 3;
    if (days < 7) return 7;
    if (days < 14) return 14;
    if (days < 30) return 30;
    if (days < 60) return 60;
    if (days < 90) return 90;
    return ((days ~/ 30) + 1) * 30;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    Duration elapsed = Duration.zero;
    int days = 0;

    if (provider.streakStartTime != null) {
      elapsed = DateTime.now().difference(provider.streakStartTime!);
      days = elapsed.inDays;
    }

    final nextMilestone = _getNextMilestone(days);
    final prevMilestone = days >= 90 ? (days ~/ 30) * 30 : (days >= 30 ? 14 : (days >= 14 ? 7 : (days >= 7 ? 3 : 0)));
    final milestoneSpan = (nextMilestone - prevMilestone).toDouble();
    final progressInSpan = (days - prevMilestone).toDouble().clamp(0.0, milestoneSpan);
    final percent = (milestoneSpan > 0 ? (progressInSpan / milestoneSpan) : 0.0).clamp(0.05, 1.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withOpacity(0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Ambient soft glow in top right
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGlow.withOpacity(0.15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              children: [
                // Top Tag Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.streakOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.streakOrange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: AppColors.streakOrange, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'DAY $days OF YOUR JOURNEY',
                            style: const TextStyle(
                              color: AppColors.streakOrange,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded, color: AppColors.textSecondary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Target: Day $nextMilestone',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Radial Circular Progress & Center Counter
                CircularPercentIndicator(
                  radius: 78.0,
                  lineWidth: 10.0,
                  animation: true,
                  animateFromLastPercent: true,
                  percent: percent,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: AppColors.surface,
                  linearGradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryGlow, AppColors.accent],
                  ),
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$days',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        days == 1 ? 'DAY CLEAN' : 'DAYS CLEAN',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Live Monospace Digital Clock Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 800.ms, begin: 0.3, end: 1.0),
                      const SizedBox(width: 8),
                      Text(
                        _formatClock(elapsed),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ELAPSED',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Milestone Progress Bar Label
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGlow),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Milestone ${prevMilestone}d',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${nextMilestone - days} days remaining',
                      style: const TextStyle(color: AppColors.primaryGlow, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
