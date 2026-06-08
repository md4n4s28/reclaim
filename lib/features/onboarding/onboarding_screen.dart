import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';
import '../../core/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

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
      icon: Icons.loop_rounded,
      color: AppColors.warning,
      title: 'Replace the habit',
      subtitle: 'Every blocked urge is replaced with a healthier action. Build new neural pathways.',
    ),
    _OnboardPage(
      icon: Icons.local_fire_department_rounded,
      color: AppColors.streakOrange,
      title: 'Reward discipline',
      subtitle: 'Track your streaks, time saved, and urges resisted. Progress over perfection.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
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
                         await context.read<AppProvider>().completeOnboarding();
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
    );
  }
}

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
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
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
