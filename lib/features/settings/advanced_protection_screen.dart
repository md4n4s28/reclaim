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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => PinSetupSheet(provider: provider),
    );
  }
}

class PinSetupSheet extends StatefulWidget {
  final AppProvider provider;
  const PinSetupSheet({super.key, required this.provider});

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  bool _isConfirming = false;
  final List<String> _firstPin = [];
  final List<String> _confirmPin = [];
  String _errorMessage = "";

  List<String> get _currentList => _isConfirming ? _confirmPin : _firstPin;

  void _onKeyPress(String val) {
    if (_currentList.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentList.add(val);
        _errorMessage = "";
      });

      if (_currentList.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          if (!_isConfirming) {
            setState(() {
              _isConfirming = true;
            });
          } else {
            _checkMatch();
          }
        });
      }
    }
  }

  void _onBackspace() {
    if (_currentList.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentList.removeLast();
        _errorMessage = "";
      });
    }
  }

  void _checkMatch() {
    final p1 = _firstPin.join();
    final p2 = _confirmPin.join();
    if (p1 == p2) {
      HapticFeedback.mediumImpact();
      widget.provider.setPin(p1);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 4-Digit Protection PIN successfully set!'),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _firstPin.clear();
        _confirmPin.clear();
        _isConfirming = false;
        _errorMessage = "PINs did not match. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                _isConfirming ? 'CONFIRM 4-DIGIT PIN' : (widget.provider.hasPin ? 'CHANGE 4-DIGIT PIN' : 'SET 4-DIGIT PIN'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isConfirming
                    ? 'Re-enter your 4 digits to confirm'
                    : 'Enter a 4-digit code to lock settings',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 24),

              // 4 Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _currentList.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: isFilled ? 18 : 14,
                    height: isFilled ? 18 : 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? AppColors.primaryGlow : AppColors.surface,
                      border: Border.all(
                        color: isFilled ? AppColors.primaryGlow : AppColors.border,
                        width: isFilled ? 0 : 2,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: AppColors.primaryGlow.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Error Message
              SizedBox(
                height: 20,
                child: _errorMessage.isNotEmpty
                    ? Text(
                        _errorMessage,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),

              // Keypad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final row in [
                      ['1', '2', '3'],
                      ['4', '5', '6'],
                      ['7', '8', '9'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: row.map((d) => _buildKey(d)).toList(),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildResetKey(),
                        _buildKey('0'),
                        _buildBackspaceKey(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Remove PIN button if existing
              if (widget.provider.hasPin)
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await widget.provider.removePin();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔓 4-Digit PIN removed successfully'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 16),
                  label: const Text(
                    'Remove Current PIN',
                    style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () => _onKeyPress(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetKey() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _firstPin.clear();
          _confirmPin.clear();
          _isConfirming = false;
          _errorMessage = "";
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: const Text(
          'RESET',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return GestureDetector(
      onTap: _onBackspace,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: AppColors.textSecondary,
          size: 20,
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
