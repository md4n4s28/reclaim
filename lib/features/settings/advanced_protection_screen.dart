import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
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
      appBar: AppBar(
        title: const Text(
          'ADVANCED HARDENING',
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
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          children: [
            // Informational Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.primaryGlow, size: 24),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Deep anti-relapse friction. Prevents impulsively disabling filters, clearing data, or uninstalling Reclaim during vulnerability.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 18),

            _AppLockCard(provider: provider),
            const SizedBox(height: 14),

            _UninstallPreventionCard(provider: provider),
            const SizedBox(height: 14),

            _StrictModeStatusCard(provider: provider),
            const SizedBox(height: 24),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.hasPin ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Lock (PIN Protection)',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.hasPin ? 'PIN is configured & active' : 'No PIN set — settings unlocked',
                      style: TextStyle(
                        color: provider.hasPin ? AppColors.accent : AppColors.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.hasPin ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.hasPin ? 'PROTECTED' : 'DISABLED',
                  style: TextStyle(
                    color: provider.hasPin ? AppColors.accent : AppColors.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Requires a 4-digit PIN before anyone can change blocklists, customize streak dates, or modify app restrictions.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.hasPin ? AppColors.surface : AppColors.primary,
                foregroundColor: provider.hasPin ? AppColors.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: provider.hasPin ? const BorderSide(color: AppColors.border) : BorderSide.none,
              ),
              onPressed: () => _showPinDialog(context, provider),
              icon: Icon(provider.hasPin ? Icons.edit_rounded : Icons.lock_outline_rounded, size: 16),
              label: Text(
                provider.hasPin ? 'Manage or Remove PIN' : 'Set Protection PIN',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  void _showPinDialog(BuildContext context, AppProvider provider) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    bool isConfirming = false;
    String firstPin = "";

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isConfirming ? 'Confirm PIN' : (provider.hasPin ? 'Change or Remove PIN' : 'Set Protection PIN'),
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: isConfirming ? confirmController : controller,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary, letterSpacing: 6, fontSize: 20),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '••••',
                  hintStyle: const TextStyle(color: AppColors.textMuted, letterSpacing: 6),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  counterStyle: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              if (!isConfirming && provider.hasPin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger.withOpacity(0.15),
                      foregroundColor: AppColors.danger,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await provider.removePin();
                      Navigator.pop(dialogCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔓 PIN removed successfully'),
                          backgroundColor: AppColors.accent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Remove Current PIN', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                HapticFeedback.lightImpact();
                if (isConfirming) {
                  if (confirmController.text == firstPin) {
                    await provider.setPin(firstPin);
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔒 PIN successfully configured!'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ PINs do not match. Try again.'),
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() {
                      isConfirming = false;
                      controller.clear();
                      confirmController.clear();
                    });
                  }
                } else {
                  if (controller.text.length == 4) {
                    setState(() {
                      firstPin = controller.text;
                      isConfirming = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ PIN must be exactly 4 digits'),
                        backgroundColor: AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(isConfirming ? 'Save PIN' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UninstallPreventionCard extends StatelessWidget {
  final AppProvider provider;
  const _UninstallPreventionCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.isAdminActive ? AppColors.accent.withOpacity(0.4) : AppColors.danger.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Device Admin Hardening',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.isAdminActive ? 'Device Administrator is ACTIVE' : 'Device Administrator is INACTIVE',
                      style: TextStyle(
                        color: provider.isAdminActive ? AppColors.accent : AppColors.warning,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.isAdminActive ? AppColors.accent.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.isAdminActive ? 'ENFORCED' : 'OFF',
                  style: TextStyle(
                    color: provider.isAdminActive ? AppColors.accent : AppColors.warning,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Grants Android Device Administrator rights to Reclaim so an urge cannot be resolved by casually dragging the icon to "Uninstall".',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: provider.isAdminActive ? AppColors.surface : AppColors.danger,
                foregroundColor: provider.isAdminActive ? AppColors.textPrimary : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: provider.isAdminActive ? const BorderSide(color: AppColors.border) : BorderSide.none,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                provider.enableDeviceAdmin();
              },
              icon: Icon(provider.isAdminActive ? Icons.check_circle_outline_rounded : Icons.lock_rounded, size: 16),
              label: Text(
                provider.isAdminActive ? 'Manage Admin Rights' : 'Enable Device Admin',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
  }
}

class _StrictModeStatusCard extends StatelessWidget {
  final AppProvider provider;
  const _StrictModeStatusCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: provider.isAccessibilityEnabled ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Strict Protection Shield',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      provider.isAccessibilityEnabled ? 'Real-time guardian active' : 'Accessibility service required',
                      style: TextStyle(
                        color: provider.isAccessibilityEnabled ? AppColors.accent : AppColors.danger,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: provider.isAccessibilityEnabled ? AppColors.accent.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.isAccessibilityEnabled ? 'GUARD ON' : 'DISABLED',
                  style: TextStyle(
                    color: provider.isAccessibilityEnabled ? AppColors.accent : AppColors.danger,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            provider.isAccessibilityEnabled
                ? 'Strict Shield monitors browser address bars, incognito tabs, in-app downloaders, and intercepts adult keywords across all apps with instant overlay protection.'
                : 'Accessibility service is currently turned OFF. Enable Reclaim Protection in Android Accessibility settings to activate real-time web & in-app defense.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
          ),
          if (!provider.isAccessibilityEnabled) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  provider.openAccessibilitySettings();
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: const Text('Open Accessibility Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05, end: 0);
  }
}
