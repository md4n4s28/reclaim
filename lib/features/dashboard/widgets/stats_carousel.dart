import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/app_provider.dart';

class StatsCarousel extends StatelessWidget {
  const StatsCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    final stats = [
      _StatData(
        icon: Icons.local_fire_department_rounded,
        value: '${provider.streakDays}',
        label: 'Day Streak',
        color: AppColors.streakOrange,
        emoji: '🔥',
      ),
      _StatData(
        icon: Icons.shield_rounded,
        value: '${provider.urgesResisted}',
        label: 'Urges Resisted',
        color: AppColors.accent,
        emoji: '🛡️',
      ),
      _StatData(
        icon: Icons.access_time_rounded,
        value: provider.timeSavedLabel,
        label: 'Time Saved',
        color: AppColors.primary,
        emoji: '⏰',
      ),
      _StatData(
        icon: Icons.block_rounded,
        value: '${provider.blockedSites.length}',
        label: 'Sites Blocked',
        color: AppColors.danger,
        emoji: '🚫',
      ),
      _StatData(
        icon: Icons.trending_up_rounded,
        value: '${(provider.urgesResisted > 0 ? (provider.urgesResisted / (provider.urgesResisted + 3) * 100).toInt() : 0)}%',
        label: 'Success Rate',
        color: AppColors.warning,
        emoji: '📈',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text('📊 Your Stats',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              SizedBox(width: 8),
              Text('Swipe →',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CarouselSlider.builder(
          itemCount: stats.length,
          options: CarouselOptions(
            height: 170,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            autoPlay: false,
          ),
          itemBuilder: (context, index, _) {
            return _StatCard(stat: stats[index], delay: index * 100);
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final String emoji;

  _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.emoji,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData stat;
  final int delay;

  const _StatCard({required this.stat, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            stat.color.withOpacity(0.15),
            stat.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stat.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(stat.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 5),
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            stat.label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }
}
