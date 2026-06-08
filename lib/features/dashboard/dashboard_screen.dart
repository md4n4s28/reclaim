import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';
import '../../core/bottom_nav.dart';
import 'widgets/focus_card.dart';
import 'widgets/streak_timer.dart';
import 'widgets/stats_carousel.dart';
import 'widgets/mood_tracker.dart';
import 'widgets/mini_calendar.dart';
import 'widgets/weekly_comparison.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<AppProvider>().refreshProtectionStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().refreshProtectionStatus();
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) => RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(provider: provider)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      const FocusCard(),
                      const SizedBox(height: 16),
                      const StatsCarousel(),
                      const SizedBox(height: 20),
                      const MiniCalendar(),
                      const SizedBox(height: 20),
                      const StreakTimer(),
                      const SizedBox(height: 20),
                      _PanicButton(),
                      const SizedBox(height: 20),
                      const MoodTracker(),
                      const SizedBox(height: 20),
                      const WeeklyComparison(),
                      const SizedBox(height: 20),
                      _LifeEquivalent(provider: provider),
                      const SizedBox(height: 20),
                      _QuickActions(),
                      const SizedBox(height: 20),
                      _MotivationCard(),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/panic'),
        backgroundColor: AppColors.panicRed,
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
        label: const Text('PANIC',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
    );
  }
}

class _Header extends StatelessWidget {
  final AppProvider provider;
  const _Header({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good morning 👋',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                const Text('Stay strong today',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.settings_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

class _StatsRow extends StatelessWidget {
  final AppProvider provider;
  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            value: '${provider.streakDays}',
            label: 'Day Streak 🔥',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streakOrange,
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            value: '${provider.urgesResisted}',
            label: 'Urges Resisted',
            icon: Icons.shield_rounded,
            color: AppColors.accent,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0),
        ),
      ],
    );
  }
}

class _PanicButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/panic'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.panicRed.withOpacity(0.15),
              AppColors.panicRed.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.panicRed.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: AppColors.panicRed.withOpacity(0.1),
                blurRadius: 24,
                spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.panicRed.withOpacity(0.2),
                border: Border.all(color: AppColors.panicRed.withOpacity(0.5)),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.panicRed, size: 28),
            )
                .animate(onPlay: (c) => c.repeat())
                .shimmer(duration: 2000.ms, color: AppColors.panicRed.withOpacity(0.3)),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PANIC BUTTON',
                      style: TextStyle(
                          color: AppColors.panicRed,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text('Tap when urge spikes — we\'ll help you through it',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.panicRed, size: 24),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95));
  }
}

class _LifeEquivalent extends StatelessWidget {
  final AppProvider provider;
  const _LifeEquivalent({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.primary,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.access_time_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.timeSavedLabel,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(provider.lifeEquivalent,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Row(
          children: [
            _ActionChip(
              icon: Icons.block_rounded,
              label: 'Block Sites',
              color: AppColors.danger,
              onTap: () => Navigator.pushNamed(context, '/block'),
            ),
            const SizedBox(width: 10),
            _ActionChip(
              icon: Icons.book_rounded,
              label: 'Journal',
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/journal'),
            ),
            const SizedBox(width: 10),
            _ActionChip(
              icon: Icons.air_rounded,
              label: 'Breathe',
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/breathing'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  static const _quotes = [
    'Discipline is choosing what you want most over what you want now.',
    'Urges don\'t define you. Your choices do.',
    'Progress over perfection. Every day counts.',
    'You are stronger than any urge.',
    'The pain of discipline is less than the pain of regret.',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[DateTime.now().day % _quotes.length];
    return GlowCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💬', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"$quote"',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}


