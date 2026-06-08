import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';

class AdvancedProtectionScreen extends StatefulWidget {
  const AdvancedProtectionScreen({super.key});

  @override
  State<AdvancedProtectionScreen> createState() => _AdvancedProtectionScreenState();
}

class _AdvancedProtectionScreenState extends State<AdvancedProtectionScreen> with WidgetsBindingObserver {
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
      appBar: AppBar(title: const Text('Advanced Protection')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'These features add deep friction to your device to prevent you from easily disabling Reclaim during an urge.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _AppLockCard(provider: provider),
            const SizedBox(height: 20),
            _UninstallPreventionCard(provider: provider),
            const SizedBox(height: 20),
            _StrictModeStatusCard(provider: provider),
          ],
        ),
      ),
    );
  }
}

class _AppLockCard extends StatelessWidget {
  final AppProvider provider;
  const _AppLockCard({required this.provider});

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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('App Lock (PIN)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Require a PIN to change app settings.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                provider.hasPin ? 'PIN is active' : 'No PIN set',
                style: TextStyle(
                  color: provider.hasPin ? AppColors.accent : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showPinDialog(context, provider),
                child: Text(provider.hasPin ? 'Change PIN' : 'Set PIN'),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  void _showPinDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          provider.hasPin ? 'Change PIN' : 'Set PIN',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter 4-6 digit PIN',
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
            counterStyle: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.length >= 4) {
                provider.setPin(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔐 PIN set successfully'),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _UninstallPreventionCard extends StatelessWidget {
  final AppProvider provider;
  const _UninstallPreventionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.danger),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Uninstall Prevention', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Prevents accidental uninstallation by enabling Device Administrator.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: provider.isAdminActive ? AppColors.accent : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  provider.isAdminActive ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                  color: provider.isAdminActive ? AppColors.accent : AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.isAdminActive ? 'Device Admin is Active' : 'Device Admin is Inactive',
                    style: TextStyle(
                      color: provider.isAdminActive ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isAdminActive ? AppColors.background : AppColors.danger,
                foregroundColor: provider.isAdminActive ? AppColors.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                side: provider.isAdminActive ? const BorderSide(color: AppColors.border) : BorderSide.none,
              ),
              onPressed: () => provider.enableDeviceAdmin(),
              child: Text(
                provider.isAdminActive ? 'Manage Device Admin' : 'Enable Device Admin',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

class _StrictModeStatusCard extends StatelessWidget {
  final AppProvider provider;
  const _StrictModeStatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      glowColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Strict Mode', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Automatically enforced when Browser Protection is active.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            provider.isAccessibilityEnabled
                ? '✅ Strict Mode is currently ACTIVE. System settings like Private DNS and Device Admin cannot be easily disabled.'
                : '❌ Strict Mode is currently INACTIVE. Enable Browser Protection to lock down your settings.',
            style: TextStyle(
              color: provider.isAccessibilityEnabled ? AppColors.accent : AppColors.danger,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
