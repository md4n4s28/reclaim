import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/protection_service.dart';

class AppBlockerScreen extends StatefulWidget {
  const AppBlockerScreen({super.key});

  @override
  State<AppBlockerScreen> createState() => _AppBlockerScreenState();
}

class _AppBlockerScreenState extends State<AppBlockerScreen> {
  List<Map<String, String>> _installedApps = [];
  List<Map<String, String>> _filteredApps = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  String _activeFilter = 'all'; // 'all', 'blocked', 'browsers'

  @override
  void initState() {
    super.initState();
    _loadApps();
    _searchController.addListener(_applyFilters);
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
      _isLoading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final provider = context.read<AppProvider>();

    setState(() {
      _filteredApps = _installedApps.where((app) {
        final name = (app["appName"] ?? "").toLowerCase();
        final pkg = (app["packageName"] ?? "").toLowerCase();

        final matchesSearch = query.isEmpty || name.contains(query) || pkg.contains(query);
        if (!matchesSearch) return false;

        if (_activeFilter == 'blocked') {
          return provider.blockedPackages.contains(pkg);
        } else if (_activeFilter == 'browsers') {
          return pkg.contains('chrome') ||
              pkg.contains('browser') ||
              pkg.contains('tube') ||
              pkg.contains('snaptube') ||
              pkg.contains('vidmate') ||
              pkg.contains('opera') ||
              pkg.contains('firefox') ||
              pkg.contains('edge') ||
              pkg.contains('brave') ||
              pkg.contains('instagram') ||
              pkg.contains('reddit') ||
              pkg.contains('tiktok') ||
              pkg.contains('twitter') ||
              pkg.contains('xhamster') ||
              pkg.contains('downloader');
        }

        return true;
      }).toList();
    });
  }

  void _setFilter(String filter) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeFilter = filter;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final blockedCount = provider.blockedPackages.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'APPLICATION FIREWALL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _loadApps,
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Search and Filter Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Search by app name or package...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter tabs
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All (${_installedApps.length})',
                          isSelected: _activeFilter == 'all',
                          onTap: () => _setFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Restricted ($blockedCount)',
                          isSelected: _activeFilter == 'blocked',
                          color: AppColors.danger,
                          onTap: () => _setFilter('blocked'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Browsers & Media',
                          isSelected: _activeFilter == 'browsers',
                          color: AppColors.warning,
                          onTap: () => _setFilter('browsers'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Apps List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _filteredApps.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 44),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No matching apps found',
                                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Try another search term or switch filters.',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredApps.length,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemBuilder: (context, index) {
                              final app = _filteredApps[index];
                              final pkg = app["packageName"] ?? "";
                              final name = app["appName"] ?? "Unknown App";
                              final isBlocked = provider.blockedPackages.contains(pkg);
                              final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isBlocked ? AppColors.danger.withOpacity(0.06) : AppColors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isBlocked ? AppColors.danger.withOpacity(0.35) : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // App Initial Avatar
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isBlocked ? AppColors.danger.withOpacity(0.15) : AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isBlocked ? AppColors.danger.withOpacity(0.4) : AppColors.border,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          initial,
                                          style: TextStyle(
                                            color: isBlocked ? AppColors.danger : AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // App Name & Package
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            pkg,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 10.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Block Switch
                                    Switch(
                                      value: isBlocked,
                                      activeColor: AppColors.danger,
                                      activeTrackColor: AppColors.danger.withOpacity(0.35),
                                      inactiveThumbColor: AppColors.textMuted,
                                      inactiveTrackColor: AppColors.surface,
                                      onChanged: (val) {
                                        HapticFeedback.lightImpact();
                                        if (val) {
                                          provider.addBlockedPackage(pkg);
                                        } else {
                                          provider.removeBlockedPackage(pkg);
                                        }
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
