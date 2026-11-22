import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingPattern {
  final String title;
  final String subtitle;
  final String tag;
  final List<_BreathPhase> phases;

  const _BreathingPattern({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.phases,
  });
}

class _BreathPhase {
  final String name;
  final int duration;
  final Color color;
  final IconData icon;
  final String cue;

  const _BreathPhase({
    required this.name,
    required this.duration,
    required this.color,
    required this.icon,
    required this.cue,
  });
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  int _selectedPatternIndex = 0;
  bool _isActive = false;
  int _currentPhaseIndex = 0;
  int _countdown = 4;
  int _cyclesCompleted = 0;
  Timer? _timer;
  late AnimationController _animController;

  static const List<_BreathingPattern> _patterns = [
    _BreathingPattern(
      title: '4-7-8 Relax',
      subtitle: 'Dr. Weil technique for nervous system reset',
      tag: 'ANXIETY & URGES',
      phases: [
        _BreathPhase(name: 'Inhale', duration: 4, color: AppColors.primary, icon: Icons.arrow_upward_rounded, cue: 'Inhale deeply through your nose'),
        _BreathPhase(name: 'Hold', duration: 7, color: AppColors.warning, icon: Icons.pause_rounded, cue: 'Hold your breath comfortably'),
        _BreathPhase(name: 'Exhale', duration: 8, color: AppColors.accent, icon: Icons.arrow_downward_rounded, cue: 'Exhale slowly through your mouth'),
      ],
    ),
    _BreathingPattern(
      title: '4-4-4-4 Box',
      subtitle: 'Navy SEAL protocol to regain tactical composure',
      tag: 'STRESS RESET',
      phases: [
        _BreathPhase(name: 'Inhale', duration: 4, color: AppColors.primary, icon: Icons.arrow_upward_rounded, cue: 'Inhale slowly through nose'),
        _BreathPhase(name: 'Hold', duration: 4, color: AppColors.warning, icon: Icons.pause_rounded, cue: 'Hold lungs full'),
        _BreathPhase(name: 'Exhale', duration: 4, color: AppColors.accent, icon: Icons.arrow_downward_rounded, cue: 'Exhale smoothly'),
        _BreathPhase(name: 'Hold', duration: 4, color: AppColors.streakOrange, icon: Icons.pause_circle_outline_rounded, cue: 'Hold empty lungs'),
      ],
    ),
    _BreathingPattern(
      title: '5-5 Coherent',
      subtitle: 'Heart-rate variability balance for calm focus',
      tag: 'HRV BALANCE',
      phases: [
        _BreathPhase(name: 'Inhale', duration: 5, color: AppColors.primary, icon: Icons.arrow_upward_rounded, cue: 'Smooth continuous inhale'),
        _BreathPhase(name: 'Exhale', duration: 5, color: AppColors.accent, icon: Icons.arrow_downward_rounded, cue: 'Smooth continuous exhale'),
      ],
    ),
  ];

  _BreathingPattern get _currentPattern => _patterns[_selectedPatternIndex];
  _BreathPhase get _currentPhase => _currentPattern.phases[_currentPhaseIndex];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _selectPattern(int index) {
    if (_isActive) _stopBreathing();
    setState(() {
      _selectedPatternIndex = index;
      _currentPhaseIndex = 0;
      _countdown = _patterns[index].phases[0].duration;
    });
  }

  void _startBreathing() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isActive = true;
      _currentPhaseIndex = 0;
      _cyclesCompleted = 0;
      _countdown = _currentPhase.duration;
    });
    _triggerPhaseAnimation();
    _startTimer();
  }

  void _stopBreathing() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _animController.stop();
    setState(() {
      _isActive = false;
      _currentPhaseIndex = 0;
      _countdown = _currentPhase.duration;
    });
  }

  void _triggerPhaseAnimation() {
    _animController.duration = Duration(seconds: _currentPhase.duration);
    if (_currentPhase.name == 'Inhale') {
      _animController.forward(from: 0.0);
    } else if (_currentPhase.name == 'Exhale') {
      _animController.reverse(from: 1.0);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    HapticFeedback.lightImpact();
    setState(() {
      if (_currentPhaseIndex < _currentPattern.phases.length - 1) {
        _currentPhaseIndex++;
      } else {
        _currentPhaseIndex = 0;
        _cyclesCompleted++;
      }
      _countdown = _currentPhase.duration;
    });
    _triggerPhaseAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final phase = _currentPhase;
    final progress = _isActive ? 1 - (_countdown / phase.duration) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'BOX & TACTICAL BREATHING',
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
        actions: [
          if (_isActive)
            TextButton(
              onPressed: _stopBreathing,
              child: const Text('STOP', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              // Pattern Selector Chips (visible when not active)
              if (!_isActive) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_patterns.length, (idx) {
                      final p = _patterns[idx];
                      final isSelected = idx == _selectedPatternIndex;
                      return GestureDetector(
                        onTap: () => _selectPattern(idx),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                p.tag,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primaryGlow : AppColors.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Center Breathing Orb Animation
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated breathing pulse circle
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          final scale = _isActive ? 0.85 + (_animController.value * 0.3) : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: phase.color.withOpacity(_isActive ? 0.12 : 0.06),
                                border: Border.all(
                                  color: phase.color.withOpacity(_isActive ? 0.6 : 0.2),
                                  width: _isActive ? 3 : 1.5,
                                ),
                                boxShadow: _isActive
                                    ? [
                                        BoxShadow(
                                          color: phase.color.withOpacity(0.25),
                                          blurRadius: 36,
                                          spreadRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isActive ? phase.icon : Icons.air_rounded,
                                      color: phase.color,
                                      size: 34,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isActive ? phase.name.toUpperCase() : 'READY',
                                      style: TextStyle(
                                        color: phase.color,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 2.0,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isActive ? '$_countdown' : '${_currentPattern.phases[0].duration}s',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Phase guidance prompt
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tips_and_updates_rounded, color: phase.color, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? phase.cue : _currentPattern.subtitle,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cycles completed badge
                      if (_isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat_rounded, color: AppColors.accent, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '$_cyclesCompleted Cycles Completed',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Bottom Control Button
              if (!_isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startBreathing,
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'START ${_currentPattern.title.toUpperCase()}',
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 6,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
