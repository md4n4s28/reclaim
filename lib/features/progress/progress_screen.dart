import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';
import '../../core/bottom_nav.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Progress')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StreakHero(provider: provider),
            const SizedBox(height: 20),
            _WeeklyChart(),
            const SizedBox(height: 20),
            _BadgesSection(provider: provider),
            const SizedBox(height: 20),
            _TimeSavedBreakdown(provider: provider),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

class _StreakHero extends StatelessWidget {
  final AppProvider provider;
  const _StreakHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.streakOrange.withOpacity(0.2),
            AppColors.primary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.streakOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 48))
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms),
          const SizedBox(height: 12),
          Text(
            '${provider.streakDays}',
            style: const TextStyle(
              color: AppColors.streakOrange,
              fontSize: 72,
              fontWeight: FontWeight.w800,
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const Text('Day Streak',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MiniStat(
                  value: '${provider.urgesResisted}',
                  label: 'Urges Resisted',
                  color: AppColors.accent),
              const SizedBox(width: 32),
              _MiniStat(
                  value: provider.timeSavedLabel,
                  label: 'Time Saved',
                  color: AppColors.primary),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  // Mock weekly data — in production, persist daily urge counts
  static final _data = [3, 1, 4, 0, 2, 1, 0];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Urges This Week'),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        _days[v.toInt()],
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _data.asMap().entries.map((e) {
                  final isToday = e.key == DateTime.now().weekday - 1;
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
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _BadgesSection extends StatelessWidget {
  final AppProvider provider;
  const _BadgesSection({required this.provider});

  List<_Badge> get _badges => [
        _Badge('🌱', 'First Step', 'Started your journey', provider.streakDays >= 1),
        _Badge('🔥', '3-Day Streak', 'Three days strong', provider.streakDays >= 3),
        _Badge('⚡', 'Week Warrior', '7 days clean', provider.streakDays >= 7),
        _Badge('💎', 'Iron Will', '30 days clean', provider.streakDays >= 30),
        _Badge('🛡️', 'Urge Slayer', 'Resisted 10 urges', provider.urgesResisted >= 10),
        _Badge('⏰', 'Time Reclaimer', 'Saved 1 hour', provider.hoursSaved >= 1),
      ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Badges'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: _badges
              .asMap()
              .entries
              .map((e) => _BadgeCard(badge: e.value, delay: e.key * 80))
              .toList(),
        ),
      ],
    );
  }
}

class _Badge {
  final String emoji;
  final String title;
  final String desc;
  final bool unlocked;
  const _Badge(this.emoji, this.title, this.desc, this.unlocked);
}

class _BadgeCard extends StatelessWidget {
  final _Badge badge;
  final int delay;

  const _BadgeCard({required this.badge, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.unlocked
            ? AppColors.card
            : AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.unlocked
              ? AppColors.streakOrange.withOpacity(0.4)
              : AppColors.border,
        ),
        boxShadow: badge.unlocked
            ? [
                BoxShadow(
                    color: AppColors.streakOrange.withOpacity(0.1),
                    blurRadius: 12)
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.emoji,
            style: TextStyle(
                fontSize: 28,
                color: badge.unlocked ? null : const Color(0xFF333333)),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: badge.unlocked
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut);
  }
}

class _TimeSavedBreakdown extends StatelessWidget {
  final AppProvider provider;
  const _TimeSavedBreakdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    final hours = provider.hoursSaved;
    return GlowCard(
      glowColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Time Reclaimed'),
          const SizedBox(height: 16),
          _TimeRow(emoji: '⏱️', label: 'Total saved', value: provider.timeSavedLabel),
          const SizedBox(height: 10),
          _TimeRow(
              emoji: '🏋️',
              label: 'Workouts equivalent',
              value: '${(hours / 1.5).floor()} sessions'),
          const SizedBox(height: 10),
          _TimeRow(
              emoji: '📚',
              label: 'Study chapters',
              value: '${(hours * 2).floor()} chapters'),
          const SizedBox(height: 10),
          _TimeRow(
              emoji: '🧘',
              label: 'Meditation sessions',
              value: '${(hours * 4).floor()} sessions'),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _TimeRow extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const _TimeRow(
      {required this.emoji, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Text(value,
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
