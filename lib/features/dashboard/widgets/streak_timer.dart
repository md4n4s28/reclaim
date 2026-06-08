import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../../core/app_provider.dart';

class StreakTimer extends StatefulWidget {
  const StreakTimer({super.key});

  @override
  State<StreakTimer> createState() => _StreakTimerState();
}

class _StreakTimerState extends State<StreakTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final totalDuration = Duration(days: provider.streakDays) + _elapsed;

    return GlowCard(
      glowColor: AppColors.streakOrange,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.streakOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: AppColors.streakOrange, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⏱️ Live Streak Timer',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('Time since last urge',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  '${provider.streakDays}',
                  style: const TextStyle(
                    color: AppColors.streakOrange,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms, color: AppColors.streakOrange.withOpacity(0.3)),
                const Text('DAYS',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(_elapsed),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Text('Hours : Minutes : Seconds',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
