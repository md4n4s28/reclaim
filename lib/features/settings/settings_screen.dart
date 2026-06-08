import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';
import '../../core/theme_provider.dart';
import '../../core/bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer2<AppProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ThemeSection(themeProvider: themeProvider),
            const SizedBox(height: 20),
            _AdvancedProtectionLink(),
            const SizedBox(height: 20),
            _NotificationsSection(),
            const SizedBox(height: 20),
            _AboutSection(),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  final ThemeProvider themeProvider;
  const _ThemeSection({required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '🎨 Appearance'),
        const SizedBox(height: 12),
        GlowCard(
          glowColor: AppColors.primary,
          child: _ToggleRow(
            icon: themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            iconColor: AppColors.primary,
            title: 'Dark Mode',
            subtitle: themeProvider.isDarkMode
                ? 'Dark theme is active'
                : 'Light theme is active',
            value: themeProvider.isDarkMode,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 50.ms);
  }
}

class _AdvancedProtectionLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '🛡️ Advanced Protection'),
        const SizedBox(height: 12),
        GlowCard(
          glowColor: AppColors.danger,
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: AppColors.danger,
                title: 'Security & Accountability',
                subtitle: 'App Lock, Uninstall Protection, Strict Mode',
                onTap: () => Navigator.pushNamed(context, '/advanced_protection'),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _NotificationsSection extends StatefulWidget {
  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  bool _dailyMotivation = true;
  bool _nightReminder = true;
  bool _urgeReminder = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '🔔 Notifications'),
        const SizedBox(height: 12),
        GlowCard(
          child: Column(
            children: [
              _ToggleRow(
                icon: Icons.wb_sunny_rounded,
                iconColor: AppColors.warning,
                title: 'Daily Motivation',
                subtitle: 'Morning reminder to stay focused',
                value: _dailyMotivation,
                onChanged: (v) => setState(() => _dailyMotivation = v),
              ),
              const Divider(color: AppColors.border, height: 1),
              _ToggleRow(
                icon: Icons.nightlight_round,
                iconColor: AppColors.primary,
                title: 'Night Discipline',
                subtitle: 'Evening check-in reminder',
                value: _nightReminder,
                onChanged: (v) => setState(() => _nightReminder = v),
              ),
              const Divider(color: AppColors.border, height: 1),
              _ToggleRow(
                icon: Icons.psychology_rounded,
                iconColor: AppColors.accent,
                title: 'Urge Prediction',
                subtitle: 'Alert during high-risk times',
                value: _urgeReminder,
                onChanged: (v) => setState(() => _urgeReminder = v),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'About'),
        const SizedBox(height: 12),
        GlowCard(
          child: Column(
            children: [
              _SettingRow(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Version',
                subtitle: '1.0.0',
                onTap: null,
              ),
              const Divider(color: AppColors.border, height: 1),
              _SettingRow(
                icon: Icons.privacy_tip_outlined,
                iconColor: AppColors.textSecondary,
                title: 'Privacy Policy',
                subtitle: 'No data leaves your device',
                onTap: () {},
              ),
              const Divider(color: AppColors.border, height: 1),
              _SettingRow(
                icon: Icons.favorite_outline_rounded,
                iconColor: AppColors.danger,
                title: 'Philosophy',
                subtitle: 'Progress over perfection',
                onTap: null,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
