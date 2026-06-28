import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  final _controller = PageController();
  int _page = 0;

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

  static const _pages = [
    _OnboardPage(
      icon: Icons.psychology_rounded,
      color: AppColors.primary,
      title: 'Urges are temporary',
      subtitle: 'The 90-second rule: every urge peaks and fades within 90 seconds. You just need to outlast it.',
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      color: AppColors.accent,
      title: 'Add friction, not force',
      subtitle: 'We don\'t lock you out. We slow you down — giving your rational mind time to catch up.',
    ),
    _OnboardPage(
      icon: Icons.dns_rounded,
      color: AppColors.primary,
      title: 'Website Filter',
      subtitle: 'Block adult content at the network level by setting your Private DNS to CleanBrowsing.',
      isSetup: true,
      setupType: 'dns',
    ),
    _OnboardPage(
      icon: Icons.bar_chart_rounded,
      color: AppColors.accent,
      title: 'App Usage Monitor',
      subtitle: 'Reclaim needs Usage Statistics access to calculate screen time analytics and block restricted apps.',
      isSetup: true,
      setupType: 'usage',
    ),
    _OnboardPage(
      icon: Icons.admin_panel_settings_rounded,
      color: AppColors.danger,
      title: 'Prevent Uninstallation',
      subtitle: 'To prevent accidental uninstallation during strong urges, enable Device Administrator privileges.',
      isSetup: true,
      setupType: 'admin',
    ),
    _OnboardPage(
      icon: Icons.accessibility_new_rounded,
      color: AppColors.streakOrange,
      title: 'Urges Protection',
      subtitle: 'To block adult searches and sites, Reclaim needs Accessibility Service enabled. Click below during setup.',
      isSetup: true,
      setupType: 'accessibility',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: 300.ms,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i], provider: provider),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _page < _pages.length - 1
                    ? Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Next',
                              onTap: () => _controller.nextPage(
                                duration: 400.ms,
                                curve: Curves.easeInOut,
                              ),
                            ),
                          ),
                        ],
                      )
                    : PrimaryButton(
                        label: 'Start My Journey',
                        onTap: () async {
                          await provider.completeOnboarding();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/dashboard');
                          }
                        },
                        isLarge: true,
                        icon: Icons.arrow_forward_rounded,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  final AppProvider provider;
  const _PageContent({required this.page, required this.provider});

  @override
  Widget build(BuildContext context) {
    final bool isSetupPage = page.isSetup;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.color.withOpacity(0.1),
              border: Border.all(color: page.color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(color: page.color.withOpacity(0.2), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Icon(page.icon, color: page.color, size: 52),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          if (isSetupPage) ...[
            const SizedBox(height: 32),
            if (page.setupType == 'dns') ...[
              const Text(
                'How to set up:\n'
                '1. Click Copy to save the hostname.\n'
                '2. Click Open DNS Settings below.\n'
                '3. Choose Private DNS provider hostname.\n'
                '4. Paste the copied text and save.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: SelectableText(
                        'family-filter-dns.cleanbrowsing.org',
                        style: TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: 'family-filter-dns.cleanbrowsing.org'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied: family-filter-dns.cleanbrowsing.org'),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open DNS Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: page.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => provider.openPrivateDnsSettings(),
              ),
            ],
            if (page.setupType == 'usage')
              ElevatedButton.icon(
                icon: const Icon(Icons.bar_chart_rounded),
                label: Text(provider.hasUsagePermission ? 'Granted ✓' : 'Grant Usage Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.hasUsagePermission ? AppColors.accent : page.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => provider.requestUsagePermission(),
              ),
            if (page.setupType == 'accessibility')
              ElevatedButton.icon(
                icon: const Icon(Icons.accessibility_new_rounded),
                label: Text(provider.isAccessibilityEnabled ? 'Enabled ✓' : 'Enable Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isAccessibilityEnabled ? AppColors.accent : page.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => provider.openAccessibilitySettings(),
              ),
            if (page.setupType == 'admin')
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings_rounded),
                label: Text(provider.isAdminActive ? 'Activated ✓' : 'Activate Device Admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isAdminActive ? AppColors.accent : page.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => provider.enableDeviceAdmin(),
              ),
          ],
        ],
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isSetup;
  final String setupType;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isSetup = false,
    this.setupType = '',
  });
}
