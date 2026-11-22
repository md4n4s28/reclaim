import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
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
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: AppColors.accent, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Block & Protection',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _StatusPill(isActive: provider.isAccessibilityEnabled),
                ),
              ],
            ),

            // Content List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. Sleek Compact Hero Shield Card
                  _CompactHeroShield(provider: provider),
                  const SizedBox(height: 12),

                  // 1.5 Permission Fix Alert (Only if accessibility offline)
                  if (!provider.isAccessibilityEnabled) ...[
                    _SetupWarningCard(provider: provider),
                    const SizedBox(height: 12),
                  ],

                  // 2. High-Impact Quick Action Shortcuts (Apps & Custom Sites)
                  _QuickToolRow(),
                  const SizedBox(height: 16),

                  // 3. Protection Category Toggles (Grid View)
                  const _SubHeader(title: 'Content Filtering Categories', subtitle: 'Tap to toggle domain categories'),
                  const SizedBox(height: 10),
                  _CategoryGrid(provider: provider),
                  const SizedBox(height: 16),

                  // 4. Today's Block Metrics Strip
                  const _SubHeader(title: 'Today\'s Defense Metrics', subtitle: 'Live intercept statistics'),
                  const SizedBox(height: 10),
                  _TodayMetricsStrip(provider: provider),
                  const SizedBox(height: 16),

                  // 5. Recent Intercept Log
                  const _SubHeader(title: 'Recent Activity Feed', subtitle: 'Live blocked threats & apps'),
                  const SizedBox(height: 10),
                  _RecentActivityCard(provider: provider),
                  const SizedBox(height: 16),

                  // 6. Built-in Database Info Card
                  _BuiltInDatabaseTile(provider: provider),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;
  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.accent : AppColors.danger).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (isActive ? AppColors.accent : AppColors.danger).withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'SHIELD ON' : 'DISABLED',
            style: TextStyle(
              color: isActive ? AppColors.accent : AppColors.danger,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactHeroShield extends StatelessWidget {
  final AppProvider provider;
  const _CompactHeroShield({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isActive = provider.isAccessibilityEnabled;
    final color = isActive ? AppColors.accent : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(isActive ? Icons.verified_user_rounded : Icons.gpp_bad_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'System Protection Active' : 'Accessibility Offline',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? 'Zero-latency browser & keyword watchdog active' : 'Tap Fix to restore adult content blocking',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!isActive)
                ElevatedButton(
                  onPressed: () => provider.openAccessibilitySettings(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Fix', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // 3-Column Summary Stats
          Row(
            children: [
              _MiniHeroStat(
                label: 'Adult Database',
                value: '${provider.builtInSiteCount}+',
                color: AppColors.danger,
                icon: Icons.shield_rounded,
              ),
              _MiniHeroStat(
                label: 'Blocked Apps',
                value: '${provider.blockedAppCount}',
                color: AppColors.warning,
                icon: Icons.apps_rounded,
              ),
              _MiniHeroStat(
                label: 'Custom Domains',
                value: '${provider.userSiteCount}',
                color: AppColors.primaryGlow,
                icon: Icons.language_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniHeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniHeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupWarningCard extends StatelessWidget {
  final AppProvider provider;
  const _SetupWarningCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Grant accessibility permission so Reclaim can shield browser URLs.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5),
            ),
          ),
          TextButton(
            onPressed: () => provider.openAccessibilitySettings(),
            child: const Text('Enable', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _QuickToolRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToolActionTile(
            title: 'Manage Apps',
            subtitle: 'Block installed apps',
            icon: Icons.apps_rounded,
            iconColor: AppColors.warning,
            onTap: () => Navigator.pushNamed(context, '/app_blocker'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ToolActionTile(
            title: 'Custom URLs',
            subtitle: 'Timed & permanent',
            icon: Icons.language_rounded,
            iconColor: AppColors.primaryGlow,
            onTap: () => Navigator.pushNamed(context, '/custom_blocking'),
          ),
        ),
      ],
    );
  }
}

class _ToolActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ToolActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final AppProvider provider;
  const _CategoryGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final categories = AppProvider.categoryNames.keys.toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((key) {
        final isOn = provider.categoryToggles[key] ?? false;
        final name = AppProvider.categoryNames[key] ?? '';
        final count = AppProvider.categoryCounts[key] ?? 0;
        final icon = AppProvider.categoryIcons[key] ?? Icons.block;
        final color = isOn ? AppColors.accent : AppColors.textMuted;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            provider.toggleCategory(key, !isOn);
          },
          child: Container(
            width: (MediaQuery.of(context).size.width - 48) / 3,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isOn ? AppColors.accent.withOpacity(0.1) : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isOn ? AppColors.accent.withOpacity(0.4) : AppColors.border,
                width: isOn ? 1.2 : 1.0,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(icon, color: color, size: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isOn ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: isOn ? Colors.black : AppColors.textMuted,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: TextStyle(
                      color: isOn ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 1),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$count targets',
                    style: TextStyle(
                      color: isOn ? AppColors.accent : AppColors.textMuted,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TodayMetricsStrip extends StatelessWidget {
  final AppProvider provider;
  const _TodayMetricsStrip({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _MetricItem(label: 'Attempts', value: '${provider.blockedAttemptsToday}', color: AppColors.danger),
          _MetricDivider(),
          _MetricItem(label: 'Sites', value: '${provider.websitesBlockedToday}', color: AppColors.primaryGlow),
          _MetricDivider(),
          _MetricItem(label: 'Apps', value: '${provider.appsRestrictedToday}', color: AppColors.warning),
          _MetricDivider(),
          _MetricItem(label: 'Saved', value: provider.focusTimeSavedLabel, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: AppColors.border,
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  final AppProvider provider;
  const _RecentActivityCard({required this.provider});

  String _timeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final activities = provider.recentActivity;
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('No blocks recorded today', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: activities.take(4).map((item) {
          final isAdult = item.type == 'adult';
          final color = isAdult ? AppColors.danger : (item.type == 'app' ? AppColors.warning : AppColors.primaryGlow);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: color, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Blocked ${item.name}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _timeAgo(item.timestamp),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BuiltInDatabaseTile extends StatelessWidget {
  final AppProvider provider;
  const _BuiltInDatabaseTile({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: AppColors.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permanent Adult Filter Database',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${provider.builtInSiteCount}+ high-risk & adult domains enforced 24/7',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(color: AppColors.accent, fontSize: 9.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SubHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
