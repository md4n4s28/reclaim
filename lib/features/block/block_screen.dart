import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';
import '../../core/bottom_nav.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => CustomScrollView(
          slivers: [
            // ── Premium App Bar ──
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Protection',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildStatusBadge(provider.isAccessibilityEnabled),
                ),
              ],
            ),
            // ── Body Content ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Section 1: Hero Protection Card
                  _HeroProtectionCard(provider: provider),
                  const SizedBox(height: 20),

                  // Section 1.5: Setup Card (only shows if accessibility disabled)
                  _SetupCard(provider: provider),

                  // Section 2: Protection Overview Stats
                  _ProtectionOverview(provider: provider),
                  const SizedBox(height: 24),

                  // Section 3: Quick Protection Categories
                  const _SectionHeader(
                    title: 'Protection Categories',
                    icon: Icons.category_rounded,
                  ),
                  const SizedBox(height: 12),
                  _QuickCategories(provider: provider),
                  const SizedBox(height: 24),

                  // Section 4: Custom Blocking Hub
                  _CustomBlockingHub(),
                  const SizedBox(height: 24),

                  // Section 5: Today's Protection
                  const _SectionHeader(
                    title: "Today's Protection",
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(height: 12),
                  _TodaysProtection(provider: provider),
                  const SizedBox(height: 24),

                  // Section 6: Recent Activity
                  const _SectionHeader(
                    title: 'Recent Activity',
                    icon: Icons.history_rounded,
                  ),
                  const SizedBox(height: 12),
                  _RecentActivity(provider: provider),
                  const SizedBox(height: 24),

                  // Adult Protection Database summary card
                  _AdultDatabaseCard(provider: provider),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.accent : AppColors.danger).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isActive ? AppColors.accent : AppColors.danger).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section Header
// ══════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 1: Hero Protection Card (keeps and enhances existing _ProtectionStatus)
// ══════════════════════════════════════════════════════════════════════════════

class _HeroProtectionCard extends StatelessWidget {
  final AppProvider provider;
  const _HeroProtectionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.isAccessibilityEnabled;
    final Color statusColor = isActive ? AppColors.accent : AppColors.danger;
    final String statusTitle = isActive ? 'Protection Active' : 'Protection Inactive';
    final String statusSubtitle = isActive
        ? 'Real-Time Monitoring Enabled'
        : 'Accessibility service is offline';
    final IconData statusIcon = isActive ? Icons.shield_rounded : Icons.gpp_bad_rounded;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF0A2E1A), const Color(0xFF0D1F12), AppColors.card]
              : [const Color(0xFF2E0A0A), const Color(0xFF1F0D0D), AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: Shield + Status
          Row(
            children: [
              // Animated Shield icon with pulse
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Icon(statusIcon, color: statusColor, size: 32),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.06, 1.06),
                    duration: 2000.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusSubtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                _FixButton(onTap: () => provider.openAccessibilitySettings()),
            ],
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  statusColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stats Row inside hero
          Row(
            children: [
              _HeroStat(
                label: 'Adult Sites',
                value: '${provider.builtInSiteCount}+',
                icon: Icons.block_rounded,
                color: const Color(0xFFEF4444),
              ),
              _HeroStat(
                label: 'Blocked Apps',
                value: '${provider.blockedAppCount}',
                icon: Icons.apps_rounded,
                color: const Color(0xFFF59E0B),
              ),
              _HeroStat(
                label: 'Custom Sites',
                value: '${provider.userSiteCount}',
                icon: Icons.language_rounded,
                color: const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Protection Coverage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: statusColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Protection Coverage: ${provider.protectionCoverage}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _HeroStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FixButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FixButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Fix',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Setup Card (kept from original, only shows when accessibility disabled)
// ══════════════════════════════════════════════════════════════════════════════

class _SetupCard extends StatelessWidget {
  final AppProvider provider;
  const _SetupCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isAccessibilityEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.streakOrange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.streakOrange.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.streakOrange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.accessibility_new_rounded, color: AppColors.streakOrange, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Browser Protection Required',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Enable accessibility to instantly block adult searches and websites.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.streakOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => provider.openAccessibilitySettings(),
                child: const Text('Enable Permission', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 2: Protection Overview (3 compact stat cards)
// ══════════════════════════════════════════════════════════════════════════════

class _ProtectionOverview extends StatelessWidget {
  final AppProvider provider;
  const _ProtectionOverview({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _OverviewCard(
          icon: Icons.shield_rounded,
          count: '${provider.builtInSiteCount}+',
          label: 'Protected',
          color: const Color(0xFFEF4444),
          delay: 0,
        ),
        const SizedBox(width: 10),
        _OverviewCard(
          icon: Icons.language_rounded,
          count: '${provider.userSiteCount}',
          label: 'Custom',
          color: const Color(0xFF6366F1),
          delay: 80,
        ),
        const SizedBox(width: 10),
        _OverviewCard(
          icon: Icons.apps_rounded,
          count: '${provider.blockedAppCount}',
          label: 'Apps',
          color: const Color(0xFFF59E0B),
          delay: 160,
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;
  final int delay;

  const _OverviewCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 10),
              Text(
                count,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 3: Quick Protection Categories (horizontal scroll)
// ══════════════════════════════════════════════════════════════════════════════

class _QuickCategories extends StatelessWidget {
  final AppProvider provider;
  const _QuickCategories({required this.provider});

  @override
  Widget build(BuildContext context) {
    final categories = AppProvider.categoryNames.keys.toList();

    return SizedBox(
      height: 155,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final key = categories[index];
          final isOn = provider.categoryToggles[key] ?? false;
          final name = AppProvider.categoryNames[key] ?? '';
          final count = AppProvider.categoryCounts[key] ?? 0;
          final icon = AppProvider.categoryIcons[key] ?? Icons.block;

          return _CategoryCard(
            name: name,
            count: count,
            icon: icon,
            isOn: isOn,
            delay: index * 60,
            onToggle: (val) => provider.toggleCategory(key, val),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final int count;
  final IconData icon;
  final bool isOn;
  final int delay;
  final ValueChanged<bool> onToggle;

  const _CategoryCard({
    required this.name,
    required this.count,
    required this.icon,
    required this.isOn,
    required this.delay,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = isOn ? AppColors.accent : AppColors.textMuted;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle(!isOn);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOn ? accentColor.withOpacity(0.06) : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOn ? accentColor.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const Spacer(),
            Text(
              name,
              style: TextStyle(
                color: isOn ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '$count sites',
              style: TextStyle(
                color: isOn ? accentColor : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Toggle indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOn ? accentColor.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: isOn ? accentColor : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideX(begin: 0.15, end: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 4: Custom Blocking Hub
// ══════════════════════════════════════════════════════════════════════════════

class _CustomBlockingHub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Blocking',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Manage apps & websites with advanced tools',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FeatureChip(icon: Icons.apps_rounded, label: 'App Blocking'),
              _FeatureChip(icon: Icons.language_rounded, label: 'Website Blocking'),
              _FeatureChip(icon: Icons.timer_rounded, label: 'Timed Blocking'),
              _FeatureChip(icon: Icons.lock_rounded, label: 'Permanent Lock'),
            ],
          ),
          const SizedBox(height: 18),
          // Navigate button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.pushNamed(context, '/custom_blocking');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'View / Manage Blocking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 5: Today's Protection Dashboard
// ══════════════════════════════════════════════════════════════════════════════

class _TodaysProtection extends StatelessWidget {
  final AppProvider provider;
  const _TodaysProtection({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _TodayStat(
                icon: Icons.block_rounded,
                value: '${provider.blockedAttemptsToday}',
                label: 'Blocked\nAttempts',
                color: const Color(0xFFEF4444),
              ),
              _TodayStat(
                icon: Icons.language_rounded,
                value: '${provider.websitesBlockedToday}',
                label: 'Websites\nBlocked',
                color: const Color(0xFF6366F1),
              ),
              _TodayStat(
                icon: Icons.apps_rounded,
                value: '${provider.appsRestrictedToday}',
                label: 'Apps\nRestricted',
                color: const Color(0xFFF59E0B),
              ),
              _TodayStat(
                icon: Icons.timer_rounded,
                value: provider.focusTimeSavedLabel,
                label: 'Focus\nTime Saved',
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _TodayStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Section 6: Recent Activity
// ══════════════════════════════════════════════════════════════════════════════

class _RecentActivity extends StatelessWidget {
  final AppProvider provider;
  const _RecentActivity({required this.provider});

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'app':
        return Icons.apps_rounded;
      case 'adult':
        return Icons.shield_rounded;
      default:
        return Icons.language_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'app':
        return const Color(0xFFF59E0B);
      case 'adult':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = provider.recentActivity;
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No recent blocking activity',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;
          final color = _colorForType(activity.type);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconForType(activity.type), color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blocked ${activity.name}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(activity.timestamp),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.block_rounded, color: color.withOpacity(0.5), size: 16),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: AppColors.border, height: 1),
                ),
            ],
          );
        }).toList(),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Adult Protection Database Summary Card (replaces raw website list)
// ══════════════════════════════════════════════════════════════════════════════

class _AdultDatabaseCard extends StatelessWidget {
  final AppProvider provider;
  const _AdultDatabaseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.danger.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.security_rounded, color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Adult Protection Database',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${provider.builtInSiteCount}+ Websites Protected',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, color: AppColors.danger, size: 14),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms);
  }
}
