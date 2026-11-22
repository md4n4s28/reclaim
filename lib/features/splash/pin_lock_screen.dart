import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> with SingleTickerProviderStateMixin {
  final List<String> _enteredCode = [];
  String _errorMessage = "";
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    if (_enteredCode.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredCode.add(val);
        _errorMessage = "";
      });
      if (_enteredCode.length == 4) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (mounted) _verifyCode();
        });
      }
    }
  }

  void _onBackspace() {
    if (_enteredCode.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredCode.removeLast();
        _errorMessage = "";
      });
    }
  }

  void _onClear() {
    if (_enteredCode.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredCode.clear();
        _errorMessage = "";
      });
    }
  }

  void _verifyCode() {
    final code = _enteredCode.join();
    final verified = context.read<AppProvider>().verifyPin(code);
    if (verified) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _enteredCode.clear();
        _errorMessage = "Incorrect PIN. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Top Shield Icon with Ambient Glow
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryGlow.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGlow.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGlow.withOpacity(0.2),
                    blurRadius: 28,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: AppColors.primaryGlow,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'RECLAIM SECURITY',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter 4-digit PIN to access protection controls',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // 4-Digit PIN Indicator Dots with Micro-Shake on Error
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final double offset = math.sin(_shakeController.value * math.pi * 4) * 8 * (1 - _shakeController.value);
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredCode.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: isFilled ? 20 : 16,
                    height: isFilled ? 20 : 16,
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
                                color: AppColors.primaryGlow.withOpacity(0.6),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),

            // Error message container (fixed height to prevent layout jumps)
            SizedBox(
              height: 22,
              child: _errorMessage.isNotEmpty
                  ? Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            const Spacer(flex: 3),

            // 4-Digit Dedicated Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: _buildKeypad(),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildClearKey(),
            _buildKey('0'),
            _buildBackspaceKey(),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value) {
    return GestureDetector(
      onTap: () => _onKeyPress(value),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border.withOpacity(0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClearKey() {
    return GestureDetector(
      onTap: _onClear,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: const Text(
          'CLEAR',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
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
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: AppColors.textSecondary,
          size: 22,
        ),
      ),
    );
  }
}
