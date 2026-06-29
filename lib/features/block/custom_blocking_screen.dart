import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/protection_service.dart';

class CustomBlockingScreen extends StatefulWidget {
  const CustomBlockingScreen({super.key});

  @override
  State<CustomBlockingScreen> createState() => _CustomBlockingScreenState();
}

class _CustomBlockingScreenState extends State<CustomBlockingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Custom Blocking',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerHeight: 0,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apps_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('App Blocker'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('Website Blocker'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AppBlockerTab(),
          _WebsiteBlockerTab(),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 1: App Blocker
// ══════════════════════════════════════════════════════════════════════════════

class _AppBlockerTab extends StatefulWidget {
  const _AppBlockerTab();

  @override
  State<_AppBlockerTab> createState() => _AppBlockerTabState();
}

class _AppBlockerTabState extends State<_AppBlockerTab> {
  List<Map<String, String>> _installedApps = [];
  List<Map<String, String>> _filteredApps = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
    _searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    setState(() => _isLoading = true);
    final apps = await ProtectionService.getInstalledApps();
    setState(() {
      _installedApps = apps;
      _filteredApps = apps;
      _isLoading = false;
    });
  }

  void _filterApps() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApps = _installedApps.where((app) {
        final name = app["appName"]?.toLowerCase() ?? "";
        final pkg = app["packageName"]?.toLowerCase() ?? "";
        return name.contains(query) || pkg.contains(query);
      }).toList();
    });
  }

  void _showBlockModeDialog(BuildContext context, String pkg, String name, AppProvider provider) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BlockModeSheet(
        name: name,
        packageName: pkg,
        type: 'app',
        provider: provider,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final blockedCount = provider.blockedPackages.length;
        final totalCount = _installedApps.length;

        return Column(
          children: [
            // Stats bar
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _MiniStat(label: 'Installed', value: '$totalCount', color: AppColors.textSecondary),
                  Container(width: 1, height: 24, color: AppColors.border),
                  _MiniStat(label: 'Blocked', value: '$blockedCount', color: AppColors.danger),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search installed apps...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            // App list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                          SizedBox(height: 16),
                          Text('Loading apps...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    )
                  : _filteredApps.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
                              const SizedBox(height: 12),
                              const Text('No apps found', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredApps.length,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemBuilder: (context, index) {
                            final app = _filteredApps[index];
                            final pkg = app["packageName"] ?? "";
                            final name = app["appName"] ?? "";
                            final isBlocked = provider.blockedPackages.contains(pkg);
                            final timedBlock = provider.getTimedBlock(pkg);
                            final isTimed = timedBlock != null;

                            Color accentColor = AppColors.textMuted;
                            if (isTimed) {
                              accentColor = AppColors.streakOrange;
                            } else if (isBlocked) {
                              accentColor = AppColors.danger;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isBlocked ? accentColor.withOpacity(0.2) : AppColors.border,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isBlocked ? Icons.block_rounded : Icons.apps_rounded,
                                    color: accentColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pkg,
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (isTimed)
                                      _TimerCountdown(timedBlock: timedBlock),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isBlocked)
                                      GestureDetector(
                                        onTap: () => _showBlockModeDialog(context, pkg, name, provider),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.timer_rounded, color: accentColor, size: 16),
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: isBlocked,
                                      onChanged: (val) {
                                        HapticFeedback.lightImpact();
                                        if (val) {
                                          _showBlockModeDialog(context, pkg, name, provider);
                                        } else {
                                          provider.removeBlockedPackage(pkg);
                                          provider.removeTimedBlock(pkg);
                                        }
                                      },
                                      activeColor: accentColor,
                                      inactiveThumbColor: AppColors.textMuted,
                                    ),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: (index * 15).clamp(0, 300)),
                                duration: 200.ms,
                              );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Tab 2: Website Blocker
// ══════════════════════════════════════════════════════════════════════════════

class _WebsiteBlockerTab extends StatefulWidget {
  const _WebsiteBlockerTab();

  @override
  State<_WebsiteBlockerTab> createState() => _WebsiteBlockerTabState();
}

class _WebsiteBlockerTabState extends State<_WebsiteBlockerTab> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addWebsite(AppProvider provider) {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Basic domain validation
    if (!url.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid domain (e.g. reddit.com)'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    provider.addUserWebsite(url);
    _urlController.clear();
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛡️ $url added to blocklist'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final websites = provider.userAddedWebsites
            .where((w) => _searchQuery.isEmpty || w.contains(_searchQuery))
            .toList();

        return Column(
          children: [
            // Add website input
            Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Add Website',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. reddit.com',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _addWebsite(provider),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _addWebsite(provider),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Search bar
            if (provider.userAddedWebsites.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search blocked websites...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            // Stats
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language_rounded, color: AppColors.textMuted, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.userAddedWebsites.length} custom website${provider.userAddedWebsites.length == 1 ? '' : 's'} blocked',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Website list
            Expanded(
              child: websites.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.language_rounded : Icons.search_off_rounded,
                            color: AppColors.textMuted,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No custom websites blocked yet'
                                : 'No matching websites',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Add websites above to start blocking',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: websites.length,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemBuilder: (context, index) {
                        final domain = websites[index];
                        final isActive = provider.blockedSites.contains(domain);
                        final timedBlock = provider.getTimedBlock(domain);
                        final isTimed = timedBlock != null;

                        Color accentColor = AppColors.textMuted;
                        if (isTimed) {
                          accentColor = AppColors.streakOrange;
                        } else if (isActive) {
                          accentColor = AppColors.danger;
                        }

                        return Dismissible(
                          key: Key(domain),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.delete_rounded, color: AppColors.danger),
                          ),
                          onDismissed: (_) {
                            provider.removeUserWebsite(domain);
                            HapticFeedback.mediumImpact();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive ? accentColor.withOpacity(0.2) : AppColors.border,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isActive ? Icons.lock_rounded : Icons.lock_open_rounded,
                                  color: accentColor,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                domain,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: isTimed
                                  ? _TimerCountdown(timedBlock: timedBlock)
                                  : Text(
                                      isActive ? 'Permanently blocked' : 'Disabled',
                                      style: TextStyle(
                                        color: isActive ? accentColor : AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (ctx) => _BlockModeSheet(
                                          name: domain,
                                          packageName: domain,
                                          type: 'website',
                                          provider: provider,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.timer_rounded, color: accentColor, size: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: isActive,
                                    onChanged: (val) {
                                      HapticFeedback.lightImpact();
                                      provider.toggleUserWebsite(domain, val);
                                    },
                                    activeColor: accentColor,
                                    inactiveThumbColor: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fadeIn(
                            delay: Duration(milliseconds: (index * 30).clamp(0, 300)),
                            duration: 200.ms,
                          );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared Components
// ══════════════════════════════════════════════════════════════════════════════

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
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
          ),
        ],
      ),
    );
  }
}

class _TimerCountdown extends StatefulWidget {
  final TimedBlock timedBlock;
  const _TimerCountdown({required this.timedBlock});

  @override
  State<_TimerCountdown> createState() => _TimerCountdownState();
}

class _TimerCountdownState extends State<_TimerCountdown> {
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

  @override
  Widget build(BuildContext context) {
    final remaining = widget.timedBlock.remaining;
    if (remaining.isNegative) {
      return const Text(
        'Expired',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
      );
    }
    final h = remaining.inHours;
    final m = remaining.inMinutes % 60;
    final s = remaining.inSeconds % 60;
    final text = h > 0 ? '${h}h ${m}m ${s}s remaining' : '${m}m ${s}s remaining';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.timer_outlined, color: AppColors.streakOrange, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.streakOrange,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Block Mode Bottom Sheet (Permanent / Timed)
// ══════════════════════════════════════════════════════════════════════════════

class _BlockModeSheet extends StatelessWidget {
  final String name;
  final String packageName;
  final String type; // 'app' or 'website'
  final AppProvider provider;

  const _BlockModeSheet({
    required this.name,
    required this.packageName,
    required this.type,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    type == 'app' ? Icons.apps_rounded : Icons.language_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Block $name',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Choose blocking mode',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Permanent Block
          _BlockOption(
            icon: Icons.lock_rounded,
            title: 'Permanent Block',
            subtitle: 'Blocked until manually disabled',
            color: AppColors.danger,
            onTap: () {
              HapticFeedback.mediumImpact();
              if (type == 'app') {
                provider.addBlockedPackage(packageName);
              } else {
                provider.addUserWebsite(packageName);
              }
              provider.removeTimedBlock(packageName);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 4),
          // Timed Block options
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.timer_rounded, color: AppColors.streakOrange, size: 16),
                SizedBox(width: 8),
                Text(
                  'Timed Block',
                  style: TextStyle(
                    color: AppColors.streakOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _TimedOption(label: '15 Minutes', duration: const Duration(minutes: 15), target: packageName, type: type, provider: provider),
          _TimedOption(label: '30 Minutes', duration: const Duration(minutes: 30), target: packageName, type: type, provider: provider),
          _TimedOption(label: '1 Hour', duration: const Duration(hours: 1), target: packageName, type: type, provider: provider),
          _TimedOption(label: '2 Hours', duration: const Duration(hours: 2), target: packageName, type: type, provider: provider),
          _TimedOption(label: '4 Hours', duration: const Duration(hours: 4), target: packageName, type: type, provider: provider),
          SafeArea(child: const SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _BlockOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BlockOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TimedOption extends StatelessWidget {
  final String label;
  final Duration duration;
  final String target;
  final String type;
  final AppProvider provider;

  const _TimedOption({
    required this.label,
    required this.duration,
    required this.target,
    required this.type,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        provider.addTimedBlock(target, type, duration);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏱️ Blocked for $label'),
            backgroundColor: AppColors.streakOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded, color: AppColors.streakOrange, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
