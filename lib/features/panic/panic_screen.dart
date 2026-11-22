import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panicRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.panicRed.withOpacity(0.35)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, color: AppColors.panicRed, size: 16),
              SizedBox(width: 6),
              Text(
                'EMERGENCY SHIELD ACTIVE',
                style: TextStyle(
                  color: AppColors.panicRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            // 1. Urge Surfing Timer with Animated Wave Simulator (FRONT & CENTER)
            const _UrgeSurfingTimer(),
            const SizedBox(height: 18),

            // 2. Psychological anchor banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "\"You are in complete control. An urge is only a temporary neurochemical wave — it cannot force you to act.\"",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Immediate Tactical Emergency Actions
            const _ActionGrid(),
            const SizedBox(height: 24),

            // 4. Grounding 5-4-3-2-1 Checklist
            const _GroundingChecklist(),
            const SizedBox(height: 28),

            // 5. "I Survived This Urge" Primary Button
            const _IResistedButton(),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. URGE SURFING TIMER (15-MIN COUNTDOWN WITH LIVE ANIMATED SINE WAVE)
// ─────────────────────────────────────────────────────────────────────────────

class _UrgeSurfingTimer extends StatefulWidget {
  const _UrgeSurfingTimer();

  @override
  State<_UrgeSurfingTimer> createState() => _UrgeSurfingTimerState();
}

class _UrgeSurfingTimerState extends State<_UrgeSurfingTimer> with SingleTickerProviderStateMixin {
  static const int _totalDurationSeconds = 15 * 60; // 15 minutes
  int _remainingSeconds = _totalDurationSeconds;
  Timer? _ticker;
  bool _isRunning = false;
  bool _isCompleted = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (_remainingSeconds <= 0) {
        _remainingSeconds = _totalDurationSeconds;
        _isCompleted = false;
      }
      setState(() => _isRunning = true);
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 1) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          _ticker?.cancel();
          setState(() {
            _remainingSeconds = 0;
            _isRunning = false;
            _isCompleted = true;
          });
          _onComplete();
        }
      });
    }
  }

  void _resetTimer() {
    HapticFeedback.selectionClick();
    _ticker?.cancel();
    setState(() {
      _remainingSeconds = _totalDurationSeconds;
      _isRunning = false;
      _isCompleted = false;
    });
  }

  void _onComplete() {
    HapticFeedback.heavyImpact();
    context.read<AppProvider>().resistUrge();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: AppColors.accent, size: 30),
            SizedBox(width: 10),
            Text('Wave Conquered!', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'You rode the entire 15-minute urge wave without surrendering.\n\nYour dopamine receptors are resetting and your prefrontal cortex is back in command. +15m focus time logged!',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Return Victorious', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPhaseInfo() {
    if (_remainingSeconds > 12 * 60) {
      return {
        'phaseIndex': 1,
        'phase': 'Phase 1 of 4 • Ride The Crest',
        'guidance': 'Don’t fight the thoughts. Breathe slowly into the physical tightness in your body.',
        'color': const Color(0xFFEF4444),
        'icon': Icons.waves_rounded,
        'amplitude': 8.5,
      };
    } else if (_remainingSeconds > 8 * 60) {
      return {
        'phaseIndex': 2,
        'phase': 'Phase 2 of 4 • Soften & Release',
        'guidance': 'Drop your shoulders and loosen your jaw. This chemical wave is peaking and will recede.',
        'color': const Color(0xFFF97316),
        'icon': Icons.air_rounded,
        'amplitude': 6.0,
      };
    } else if (_remainingSeconds > 4 * 60) {
      return {
        'phaseIndex': 3,
        'phase': 'Phase 3 of 4 • Wave Dissipating',
        'guidance': 'The dopamine spike is dying down. Notice your breathing slowing and mind clearing.',
        'color': const Color(0xFF6366F1),
        'icon': Icons.psychology_rounded,
        'amplitude': 4.0,
      };
    } else {
      return {
        'phaseIndex': 4,
        'phase': 'Phase 4 of 4 • Safe Harbor',
        'guidance': 'The urge has broken. You have regained total control over your actions and destiny.',
        'color': AppColors.accent,
        'icon': Icons.verified_user_rounded,
        'amplitude': 2.2,
      };
    }
  }

  String _formatTime(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final phaseInfo = _getPhaseInfo();
    final phaseColor = phaseInfo['color'] as Color;
    final phaseIndex = phaseInfo['phaseIndex'] as int;
    final progress = (_totalDurationSeconds - _remainingSeconds) / _totalDurationSeconds;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _isRunning ? phaseColor.withOpacity(0.5) : AppColors.border,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: phaseColor.withOpacity(_isRunning ? 0.16 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with tag & status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(phaseInfo['icon'] as IconData, color: phaseColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URGE SURFING TIMER',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Clinical 15-min craving crest cycle',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: phaseColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: phaseColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCompleted ? 'COMPLETED' : (_isRunning ? 'SURFING' : 'READY'),
                      style: TextStyle(
                        color: phaseColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Circular countdown clock
          CircularPercentIndicator(
            radius: 64,
            lineWidth: 8.5,
            percent: progress.clamp(0.0, 1.0),
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _isCompleted ? 'VICTORY' : (_isRunning ? 'HOLD FAST' : '15:00 GOAL'),
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            progressColor: phaseColor,
            backgroundColor: AppColors.surface,
            circularStrokeCap: CircularStrokeCap.round,
            animation: false,
          ),
          const SizedBox(height: 16),

          // 4-Phase Stepper Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final stepNumber = index + 1;
              final isPassed = stepNumber < phaseIndex;
              final isCurrent = stepNumber == phaseIndex;
              final stepColor = isCurrent ? phaseColor : (isPassed ? AppColors.accent : AppColors.textMuted.withOpacity(0.3));

              return Row(
                children: [
                  Container(
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: stepColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (index < 3)
                    Container(
                      width: 14,
                      height: 1.5,
                      color: isPassed ? AppColors.accent.withOpacity(0.5) : AppColors.border,
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Live Animated Wave Crest Canvas
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: phaseColor.withOpacity(0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final waveWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
                  return AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      return CustomPaint(
                        size: Size(waveWidth, 52),
                        painter: _WavePainter(
                          animationValue: _waveController.value,
                          color: phaseColor,
                          amplitude: _isRunning ? (phaseInfo['amplitude'] as double) : 3.0,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Phase guidance callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: phaseColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: phaseColor.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: phaseColor, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phaseInfo['phase'] as String,
                        style: TextStyle(
                          color: phaseColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  phaseInfo['guidance'] as String,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary Controls Row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(
                    _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _isRunning ? 'PAUSE SURFING' : (_isCompleted ? 'SURF AGAIN' : 'START SURFING'),
                    style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: phaseColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: _isRunning ? 6 : 2,
                    shadowColor: phaseColor.withOpacity(0.4),
                  ),
                ),
              ),
              if (_remainingSeconds < _totalDurationSeconds) ...[
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.all(13),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. IMMEDIATE ACTION GRID WITH INTERACTIVE DIALOGS
// ─────────────────────────────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'IMMEDIATE INTERVENTIONS',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'TAP AN ACTION',
              style: TextStyle(
                color: AppColors.primaryGlow,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.water_drop_rounded,
                title: 'Cold Water',
                subtitle: 'Splash face now',
                color: AppColors.primary,
                onTap: () => _showColdWaterDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.fitness_center_rounded,
                title: '15 Push-ups',
                subtitle: 'Physical reset',
                color: AppColors.warning,
                onTap: () => _showPushupsDialog(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.directions_walk_rounded,
                title: 'Leave Room',
                subtitle: 'Change environment',
                color: AppColors.accent,
                onTap: () => _showLeaveRoomDialog(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.air_rounded,
                title: 'Box Breath',
                subtitle: '4-4-4-4 calm',
                color: AppColors.streakOrange,
                onTap: () => Navigator.pushNamed(context, '/breathing'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0);
  }

  void _showColdWaterDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mammalian Dive Reflex',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Go to the bathroom and splash cold water directly onto your eyes and forehead for 30 seconds.\n\nThis triggers the vagus nerve, rapidly lowering your heart rate and breaking the urge frenzy.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Did This • Return', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPushupsDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: _InteractivePushupCounter(onComplete: () => Navigator.pop(ctx)),
      ),
    );
  }

  void _showLeaveRoomDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk_rounded, color: AppColors.accent, size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Change Your Physical State',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Leave this room right now. Put your phone face down on your desk.\n\nWalk outside, go to the kitchen, or talk to family or roommates. Breaking environmental cues interrupts 90% of urges.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('I Changed Rooms', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractivePushupCounter extends StatefulWidget {
  final VoidCallback onComplete;
  const _InteractivePushupCounter({required this.onComplete});

  @override
  State<_InteractivePushupCounter> createState() => _InteractivePushupCounterState();
}

class _InteractivePushupCounterState extends State<_InteractivePushupCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '15 Push-up Challenge',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap every time you complete a push-up:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                if (_count < 15) _count++;
              });
              if (_count == 15) {
                HapticFeedback.heavyImpact();
              }
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warning, width: 2),
              ),
              child: Center(
                child: Text(
                  '$_count/15',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _count >= 15 ? AppColors.accent : AppColors.surface,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: widget.onComplete,
              child: Text(
                _count >= 15 ? 'Complete! Great Job' : 'Done with Exercise',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. GROUNDING CHECKLIST (5-4-3-2-1 SENSORY TECHNIQUE)
// ─────────────────────────────────────────────────────────────────────────────

class _GroundingChecklist extends StatefulWidget {
  const _GroundingChecklist();

  @override
  State<_GroundingChecklist> createState() => _GroundingChecklistState();
}

class _GroundingChecklistState extends State<_GroundingChecklist> {
  final List<bool> _checked = List.filled(5, false);

  final List<Map<String, dynamic>> _steps = [
    {'number': '5', 'text': '5 things you can SEE', 'icon': Icons.visibility_rounded, 'color': AppColors.primary},
    {'number': '4', 'text': '4 things you can FEEL', 'icon': Icons.pan_tool_rounded, 'color': AppColors.accent},
    {'number': '3', 'text': '3 things you can HEAR', 'icon': Icons.hearing_rounded, 'color': AppColors.warning},
    {'number': '2', 'text': '2 things you can SMELL', 'icon': Icons.local_florist_rounded, 'color': AppColors.streakOrange},
    {'number': '1', 'text': '1 thing you can TASTE', 'icon': Icons.restaurant_rounded, 'color': AppColors.danger},
  ];

  @override
  Widget build(BuildContext context) {
    final checkedCount = _checked.where((c) => c).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '5-4-3-2-1 GROUNDING TECHNIQUE',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: checkedCount == 5 ? AppColors.accent.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: checkedCount == 5 ? AppColors.accent : AppColors.border),
              ),
              child: Text(
                '$checkedCount OF 5 GROUNDED',
                style: TextStyle(
                  color: checkedCount == 5 ? AppColors.accent : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Acknowledge these sensory inputs in your immediate environment to pull your mind out of dopamine loop.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 14),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isChecked = _checked[index];
          final color = step['color'] as Color;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _checked[index] = !_checked[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isChecked ? color.withOpacity(0.08) : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChecked ? color.withOpacity(0.4) : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isChecked ? color : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        step['number'] as String,
                        style: TextStyle(
                          color: isChecked ? Colors.white : color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step['text'] as String,
                      style: TextStyle(
                        color: isChecked ? color : AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Icon(
                    isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isChecked ? color : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 60))).slideX(begin: 0.04, end: 0),
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. "I SURVIVED THIS URGE" CTA
// ─────────────────────────────────────────────────────────────────────────────

class _IResistedButton extends StatelessWidget {
  const _IResistedButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.heavyImpact();
        await context.read<AppProvider>().resistUrge();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💪 Victory Logged! You proved who is in control.'),
              backgroundColor: AppColors.accent,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.military_tech_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'I SURVIVED THIS URGE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. ANIMATED SINE WAVE CUSTOM PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double amplitude;

  _WavePainter({
    required this.animationValue,
    required this.color,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || !size.width.isFinite || !size.height.isFinite) return;

    final paintBg = Paint()
      ..color = color.withOpacity(0.14)
      ..style = PaintingStyle.fill;

    final paintFg = Paint()
      ..color = color.withOpacity(0.28)
      ..style = PaintingStyle.fill;

    final crestStroke = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final pathBg = Path();
    final pathFg = Path();
    final crestPath = Path();

    pathBg.moveTo(0, size.height);
    pathFg.moveTo(0, size.height);

    bool firstPoint = true;
    for (double x = 0; x <= size.width; x += 3) {
      final yBg = size.height * 0.52 +
          math.cos((x / size.width * 2 * math.pi) - (animationValue * 2 * math.pi)) * (amplitude * 0.7);
      pathBg.lineTo(x, yBg);

      final yFg = size.height * 0.52 +
          math.sin((x / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * amplitude;
      pathFg.lineTo(x, yFg);

      if (firstPoint) {
        crestPath.moveTo(x, yFg);
        firstPoint = false;
      } else {
        crestPath.lineTo(x, yFg);
      }
    }

    pathBg.lineTo(size.width, size.height);
    pathBg.close();

    pathFg.lineTo(size.width, size.height);
    pathFg.close();

    canvas.drawPath(pathBg, paintBg);
    canvas.drawPath(pathFg, paintFg);
    canvas.drawPath(crestPath, crestStroke);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.amplitude != amplitude;
  }
}
