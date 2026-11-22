import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/theme_provider.dart';
import '../../core/bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String githubRepoUrl = 'https://github.com/md4n4s28/reclaim';
  static const String githubProfileUrl = 'https://github.com/md4n4s28/';

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: $url'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.privacy_tip_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('Privacy Policy', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.accent, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Zero Data Collection: Everything happens 100% on your phone. No tracking, no cloud servers, no analytics.',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  '1. What Data Do We Collect?',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'None. We do not require an email, phone number, name, or account. We do not have servers logging your browsing habits, searched words, or streak count.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  '2. How Are URLs & Search Queries Handled?',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The Reclaim Accessibility Watchdog evaluates URLs and omnibox text strictly in-memory on your local Android CPU using offline sets of regex and domain lists. No URL is ever transmitted over the internet or saved to external databases.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  '3. Journal & Daily Notes',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your daily reflections, moods, and urges are saved exclusively in your device\'s local sandbox storage (SharedPreferences / Hive). If you uninstall Reclaim or clear app data, all records are permanently deleted.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  '4. Third-Party Sharing',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'We do not integrate Google Analytics, Firebase Analytics, Facebook SDK, or ad networks. Your privacy remains completely intact.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understood', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.description_rounded, color: AppColors.primaryGlow, size: 22),
            SizedBox(width: 10),
            Text('Terms & Conditions', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '1. Purpose & User Commitment',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Reclaim is an accountability tool created to assist users in building self-discipline, stopping pornography consumption, and establishing digital health boundaries. By using Reclaim, you agree to use it as a personal self-restraint utility.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '2. Native Permissions & Anti-Tamper Enforcement',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'To prevent impulsive uninstallation or circumventing blocks during intense urges, Reclaim employs Device Administration and Accessibility Service APIs. You grant Reclaim permission to dismiss uninstall/force-stop dialogs and intercept prohibited browser navigation.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '3. Disclaimer of Medical Liability',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Reclaim provides behavioral tracking and content restrictions, but does not provide clinical, psychological, or medical counseling. The app is provided on an "as-is" open-source basis without warranties.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
                SizedBox(height: 12),
                Text(
                  '4. Open Source License',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Reclaim source code is hosted on GitHub under open-source terms. You are free to audit, study, and contribute to the code repository.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Accept Terms', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showOpenSourceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('Open Source Code', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reclaim is 100% open-source software. You can inspect the source code, verify that no data is collected, report issues, or contribute improvements.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Repository:',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  SelectableText(
                    'https://github.com/md4n4s28/reclaim',
                    style: TextStyle(color: AppColors.primaryGlow, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open on GitHub', style: TextStyle(fontWeight: FontWeight.w800)),
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(context, githubRepoUrl);
            },
          ),
        ],
      ),
    );
  }

  void _showResetStreakDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 10),
            Text('Reset Streak Clock', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Do you want to reset your live streak counter to 0 right now? This will register a new streak start time without deleting your journal entries or custom blocklists.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              provider.setStreakStartDate(DateTime.now());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Streak reset to day 0. Ready for a fresh start!'),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            child: const Text('Reset to 0', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Consumer2<AppProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // 1. Author Support Banner (GitHub md4n4s28)
            _DeveloperSupportBanner(
              onTap: () => _launchUrl(context, githubRepoUrl),
            ),
            const SizedBox(height: 16),

            // 1.5. Data Privacy Guarantee Box
            _DataPrivacyGuaranteeCard(),
            const SizedBox(height: 16),

            // 2. Security & Anti-Tamper Section
            _SettingsSection(
              title: '🛡️ Security & Protection',
              children: [
                _SettingsTile(
                  icon: Icons.admin_panel_settings_rounded,
                  iconColor: AppColors.danger,
                  title: 'Security & Anti-Tamper',
                  subtitle: 'App Lock, Uninstall Protection & Admin policies',
                  onTap: () => Navigator.pushNamed(context, '/advanced_protection'),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.dns_rounded,
                  iconColor: AppColors.accent,
                  title: 'Family DNS Filtering',
                  subtitle: 'CleanBrowsing DNS configuration guide',
                  onTap: () => _showDnsDialog(context, provider),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.primaryGlow,
                  title: provider.hasPin ? 'Change Access PIN' : 'Set 4-Digit Security PIN',
                  subtitle: provider.hasPin ? 'PIN verification is enabled' : 'Protect dashboard with a PIN code',
                  onTap: () => _showPinDialog(context, provider),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Discipline & Counter Management
            _SettingsSection(
              title: '⚡ Habit & Timeline Controls',
              children: [
                _SettingsTile(
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppColors.primaryGlow,
                  title: 'Adjust Sobriety Start Date',
                  subtitle: 'Set custom timeline or correct missed dates',
                  onTap: () => Navigator.pushNamed(context, '/progress'),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.restart_alt_rounded,
                  iconColor: AppColors.warning,
                  title: 'Reset Live Streak',
                  subtitle: 'Reset live clock to Day 0 after relapse',
                  onTap: () => _showResetStreakDialog(context, provider),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Notifications & Reminders
            _SettingsSection(
              title: '🔔 Reminders & Accountability',
              children: const [
                _NotificationToggles(),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Open Source, Legal & Community
            _SettingsSection(
              title: 'ℹ️ About & Open Source',
              children: [
                _SettingsTile(
                  icon: Icons.code_rounded,
                  iconColor: AppColors.accent,
                  title: 'Open Source Code',
                  subtitle: 'github.com/md4n4s28/reclaim',
                  trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 16),
                  onTap: () => _showOpenSourceDialog(context),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.person_rounded,
                  iconColor: AppColors.primaryGlow,
                  title: 'Author Profile',
                  subtitle: 'Follow @md4n4s28 on GitHub',
                  trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 16),
                  onTap: () => _launchUrl(context, githubProfileUrl),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: AppColors.accent,
                  title: 'Privacy Policy',
                  subtitle: 'Zero tracking & 100% on-device guarantee',
                  onTap: () => _showPrivacyPolicyDialog(context),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'Terms & Conditions',
                  subtitle: 'User commitment & anti-tamper policies',
                  onTap: () => _showTermsDialog(context),
                ),
                _TileDivider(),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textMuted,
                  title: 'Reclaim Version',
                  subtitle: 'v1.0.0+1 (Native Zero-Latency Engine)',
                  onTap: null,
                ),
              ],
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  void _showDnsDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.accent, size: 22),
            SizedBox(width: 10),
            Text('CleanBrowsing DNS', style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy this Private DNS hostname to filter adult content directly at the router/network level:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: SelectableText(
                      'family-filter-dns.cleanbrowsing.org',
                      style: TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 11.5),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 18),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: 'family-filter-dns.cleanbrowsing.org'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied DNS hostname to clipboard!'),
                          backgroundColor: AppColors.accent,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              provider.openPrivateDnsSettings();
            },
            child: const Text('Open DNS Settings', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          provider.hasPin ? 'Update Security PIN' : 'Set 4-Digit PIN',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter a 4-digit numeric PIN to protect access to Reclaim.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 8, fontSize: 18),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
          ],
        ),
        actions: [
          if (provider.hasPin)
            TextButton(
              onPressed: () {
                provider.removePin();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN removed.'), backgroundColor: AppColors.warning),
                );
              },
              child: const Text('Remove PIN', style: TextStyle(color: AppColors.danger)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (controller.text.length == 4) {
                provider.setPin(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN saved successfully!'), backgroundColor: AppColors.accent),
                );
              }
            },
            child: const Text('Save PIN', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DeveloperSupportBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DeveloperSupportBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGlow.withOpacity(0.18),
              AppColors.card,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGlow.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGlow.withOpacity(0.3)),
              ),
              child: const Icon(Icons.code_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'github.com/md4n4s28/reclaim',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'REPO',
                          style: TextStyle(color: AppColors.accent, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Open Source Self-Control & Digital Discipline App',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _DataPrivacyGuaranteeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Private & Stays on Your Phone',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 2),
                Text(
                  'We do not collect, transmit, or sell any user data. All history and blocklists stay strictly on your device.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap != null
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      trailing: trailing ??
          (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20) : null),
    );
  }
}

class _TileDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: 1, indent: 52);
  }
}

class _NotificationToggles extends StatefulWidget {
  const _NotificationToggles();

  @override
  State<_NotificationToggles> createState() => _NotificationTogglesState();
}

class _NotificationTogglesState extends State<_NotificationToggles> {
  bool _dailyMotivation = true;
  bool _nightReflection = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 18),
          ),
          title: const Text('Daily Morning Motivation', style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
          subtitle: const Text('Inspiring quotes at 08:00 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          value: _dailyMotivation,
          activeColor: AppColors.primaryGlow,
          onChanged: (v) => setState(() => _dailyMotivation = v),
        ),
        const Divider(color: AppColors.border, height: 1, indent: 52),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.nightlight_round, color: AppColors.primaryGlow, size: 18),
          ),
          title: const Text('Evening Reflection Check-in', style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w700)),
          subtitle: const Text('Evening journal nudge at 09:30 PM', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          value: _nightReflection,
          activeColor: AppColors.primaryGlow,
          onChanged: (v) => setState(() => _nightReflection = v),
        ),
      ],
    );
  }
}
