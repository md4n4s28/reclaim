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
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from system settings, refresh protection status
    if (state == AppLifecycleState.resumed) {
      context.read<AppProvider>().refreshProtectionStatus();
    }
  }

  void _addSite() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    context.read<AppProvider>().addSite(url);
    _urlController.clear();
    FocusScope.of(context).unfocus();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Block List'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'ALWAYS ON',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ProtectionStatus(provider: provider),
            const SizedBox(height: 12),
            _PrivateDNSCard(provider: provider),
            const SizedBox(height: 12),
            _SetupCard(provider: provider),
            const SizedBox(height: 20),
            _AddSiteCard(controller: _urlController, onAdd: _addSite),
            const SizedBox(height: 20),
            _BlockedSitesHeader(count: provider.blockedSites.length),
            const SizedBox(height: 12),
            ...provider.blockedSites.take(50).toList().asMap().entries.map(
                  (e) => _SiteItem(
                    url: e.value,
                    delay: e.key * 20,
                  ),
                ),
            if (provider.blockedSites.length > 50)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '+ ${provider.blockedSites.length - 50} more sites blocked',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real-time protection status banner
// ─────────────────────────────────────────────────────────────────────────────
class _ProtectionStatus extends StatelessWidget {
  final AppProvider provider;
  const _ProtectionStatus({required this.provider});

  @override
  Widget build(BuildContext context) {
    final accessibilityOk = provider.isAccessibilityEnabled;

    // Determine banner style
    final Color statusColor;
    final String statusTitle;
    final String statusSubtitle;
    final IconData statusIcon;

    if (accessibilityOk) {
      statusColor = AppColors.accent;
      statusTitle = '🛡️ Protection Active';
      statusSubtitle = 'Browser protection is monitoring your phone';
      statusIcon = Icons.shield_rounded;
    } else {
      statusColor = AppColors.danger;
      statusTitle = '⚠️ Protection Inactive';
      statusSubtitle = 'Browser protection is not running';
      statusIcon = Icons.shield_outlined;
    }

    return GlowCard(
      glowColor: statusColor,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 28,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 2000.ms, color: statusColor.withOpacity(0.3)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
           if (!accessibilityOk)
             _MiniActionButton(
               icon: Icons.settings_accessibility_rounded,
               color: statusColor,
               tooltip: 'Enable',
               onTap: () => provider.openAccessibilitySettings(),
             ),
          if (accessibilityOk)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _MiniActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private DNS card — simplify DNS-level blocking
// ─────────────────────────────────────────────────────────────────────────────
class _PrivateDNSCard extends StatelessWidget {
  final AppProvider provider;
  const _PrivateDNSCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.dns_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safe DNS (Recommended)',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Blocks adult sites at the system level.',
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
          const Text(
            'Copy one of these URLs and paste it in "Private DNS" settings:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          _DNSCopyRow(label: 'AdGuard Family', url: 'family.adguard-dns.com'),
          const SizedBox(height: 6),
          _DNSCopyRow(label: 'CleanBrowsing', url: 'family-filter-dns.cleanbrowsing.org'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_rounded, color: AppColors.accent, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Strict Mode Active: System settings are locked to prevent bypass.',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Open Private DNS Settings',
            onTap: () => provider.openPrivateDnsSettings(),
            color: AppColors.primary,
            icon: Icons.settings_rounded,
          ),
        ],
      ),
    );
  }
}

class _DNSCopyRow extends StatelessWidget {
  final String label;
  final String url;
  const _DNSCopyRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📋 $label copied!'), duration: const Duration(seconds: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: Text(
                url,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Setup card — shown when Accessibility is not active
// ─────────────────────────────────────────────────────────────────────────────
class _SetupCard extends StatelessWidget {
  final AppProvider provider;
  const _SetupCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final accessibilityOk = provider.isAccessibilityEnabled;

    if (accessibilityOk) return const SizedBox.shrink();

    return _SetupRow(
      icon: Icons.accessibility_new_rounded,
      color: AppColors.streakOrange,
      title: 'Browser protection required',
      subtitle: 'Monitors URLs and keywords to block adult content in real time.',
      buttonLabel: 'Enable Browser Protection',
      onTap: () => provider.openAccessibilitySettings(),
    );
  }
}

class _SetupRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _SetupRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: buttonLabel,
            onTap: onTap,
            color: color,
            icon: icon,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Site Card
// ─────────────────────────────────────────────────────────────────────────────

class _BlockedSitesHeader extends StatelessWidget {
  final int count;
  const _BlockedSitesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Blocked Sites',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.danger.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AddSiteCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onAdd;

  const _AddSiteCard({required this.controller, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Website to Block',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            '⚠️ Once added, requires 24h cooldown to remove',
            style: TextStyle(color: AppColors.warning, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'example.com',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.danger.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SiteItem extends StatelessWidget {
  final String url;
  final int delay;

  const _SiteItem({required this.url, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(url,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
          const Icon(Icons.lock_rounded,
              color: AppColors.textMuted, size: 16),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0);
  }
}

// Intervention screen shown when a blocked site is accessed
class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key});

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  int _countdown = 10;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 10; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _countdown = i);
    }
    if (mounted) setState(() => _canProceed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.danger.withOpacity(0.1),
                  border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                ),
                child: const Icon(Icons.block_rounded,
                    color: AppColors.danger, size: 40),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 32),
              const Text(
                'You are stronger\nthan this urge.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              const Text(
                'This moment will pass.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 48),
              if (!_canProceed) ...[
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 64,
                    fontWeight: FontWeight.w700,
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                    duration: 1000.ms, color: AppColors.primaryGlow),
                const SizedBox(height: 8),
                const Text(
                  'If you still want this after the countdown,\nchoose consciously.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Go Back — I\'m Stronger',
                onTap: () => Navigator.pop(context),
                color: AppColors.accent,
                icon: Icons.arrow_back_rounded,
                isLarge: true,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Open Panic Mode',
                onTap: () => Navigator.pushNamed(context, '/panic'),
                color: AppColors.primary,
                icon: Icons.warning_amber_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
