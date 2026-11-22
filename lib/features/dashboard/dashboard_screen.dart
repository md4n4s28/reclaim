import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/bottom_nav.dart';
import 'widgets/streak_timer.dart';
import 'widgets/mood_tracker.dart';

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
    await context.read<AppProvider>().refreshProtectionStatus();
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
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(child: _TopNavigationBar(provider: provider)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 4),
                      // 1. Hero Circular Streak Timer Card
                      const StreakTimerHero(),
                      const SizedBox(height: 14),

                      // 2. Daily Stoic Reflection / Quote directly beneath Progress Card
                      const _DailyWisdomCard(),
                      const SizedBox(height: 16),

                      // 3. Immediate Tactical Urge / Panic Banner
                      _TacticalPanicBanner(provider: provider),
                      const SizedBox(height: 20),

                      // 4. Quick Metrics Overview (Urges, Time Saved, Blocks)
                      _MetricsBar(provider: provider),
                      const SizedBox(height: 24),

                      // 5. Bento Navigation Grid (Journal, Breathing, Blocker, Progress)
                      const _SectionHeader(title: 'Discipline Hub', subtitle: 'Actionable routines & quick access'),
                      const SizedBox(height: 12),
                      const _BentoHubGrid(),
                      const SizedBox(height: 24),

                      // 6. Interactive Daily Mood Tracker (With dynamic guidance & video tips)
                      const InteractiveMoodTracker(),
                      const SizedBox(height: 36),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}

class _TopNavigationBar extends StatelessWidget {
  final AppProvider provider;
  const _TopNavigationBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isProtected = provider.isAccessibilityEnabled;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'RECLAIM',
                    style: TextStyle(
                      color: AppColors.primaryGlow,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Live Shield Status Badge
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/advanced_protection'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isProtected ? AppColors.accent.withOpacity(0.12) : AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isProtected ? AppColors.accent.withOpacity(0.3) : AppColors.danger.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isProtected ? AppColors.accent : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isProtected ? 'ACTIVE SHIELD' : 'SHIELD OFF',
                            style: TextStyle(
                              color: isProtected ? AppColors.accent : AppColors.danger,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Today\'s Focus',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/settings'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.settings_outlined, color: AppColors.textPrimary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TacticalPanicBanner extends StatelessWidget {
  final AppProvider provider;
  const _TacticalPanicBanner({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.pushNamed(context, '/panic');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.panicRed.withOpacity(0.18),
              AppColors.panicRed.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.panicRed.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.panicRed.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.panicRed, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feeling an urge right now?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap for 15-min Urge Surfing wave & shield',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.panicRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsBar extends StatelessWidget {
  final AppProvider provider;
  const _MetricsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricChip(
            icon: Icons.shield_rounded,
            iconColor: AppColors.accent,
            value: '${provider.urgesResisted}',
            label: 'Urges Defeated',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricChip(
            icon: Icons.block_rounded,
            iconColor: AppColors.streakOrange,
            value: '${provider.blockedAttemptsToday}',
            label: 'Blocks Today',
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BentoHubGrid extends StatelessWidget {
  const _BentoHubGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column (Journal & Blocker)
        Expanded(
          child: Column(
            children: [
              _BentoCard(
                title: 'Journal',
                subtitle: 'Daily reflections & triggers',
                icon: Icons.edit_note_rounded,
                accentColor: AppColors.primaryGlow,
                tag: 'MINDSET',
                onTap: () => Navigator.pushNamed(context, '/journal'),
              ),
              const SizedBox(height: 12),
              _BentoCard(
                title: 'Blocker Hub',
                subtitle: '5,945 filters & apps',
                icon: Icons.security_rounded,
                accentColor: AppColors.warning,
                tag: 'GUARD',
                onTap: () => Navigator.pushNamed(context, '/block'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right Column (Breathing & Progress)
        Expanded(
          child: Column(
            children: [
              _BentoCard(
                title: 'Box Breathing',
                subtitle: '4-4-4-4 reset coach',
                icon: Icons.air_rounded,
                accentColor: AppColors.accent,
                tag: 'CALM',
                onTap: () => Navigator.pushNamed(context, '/breathing'),
              ),
              const SizedBox(height: 12),
              _BentoCard(
                title: 'Analytics',
                subtitle: 'Screen time & streaks',
                icon: Icons.insights_rounded,
                accentColor: Colors.deepPurpleAccent,
                tag: 'DATA',
                onTap: () => Navigator.pushNamed(context, '/progress'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String tag;
  final VoidCallback onTap;

  const _BentoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                Text(
                  tag,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyWisdomCard extends StatelessWidget {
  const _DailyWisdomCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.primaryGlow, size: 18),
              const SizedBox(width: 6),
              const Text(
                'DAILY DISCIPLINE',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '“Discipline is choosing between what you want now, and what you want most.”',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— Abraham Lincoln',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
