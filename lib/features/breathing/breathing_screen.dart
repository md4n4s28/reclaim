import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  bool _isActive = false;
  int _currentPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale
  int _countdown = 4;
  int _cyclesCompleted = 0;
  Timer? _timer;

  final List<_Phase> _phases = [
    _Phase(name: 'Inhale', duration: 4, color: AppColors.primary, icon: Icons.arrow_upward_rounded),
    _Phase(name: 'Hold', duration: 7, color: AppColors.warning, icon: Icons.pause_rounded),
    _Phase(name: 'Exhale', duration: 8, color: AppColors.accent, icon: Icons.arrow_downward_rounded),
  ];

  void _startBreathing() {
    setState(() {
      _isActive = true;
      _currentPhase = 0;
      _countdown = _phases[0].duration;
    });
    _startTimer();
  }

  void _stopBreathing() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
      _currentPhase = 0;
      _countdown = 4;
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _nextPhase();
        }
      });
    });
  }

  void _nextPhase() {
    if (_currentPhase < _phases.length - 1) {
      setState(() {
        _currentPhase++;
        _countdown = _phases[_currentPhase].duration;
      });
    } else {
      setState(() {
        _cyclesCompleted++;
        _currentPhase = 0;
        _countdown = _phases[0].duration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final phase = _phases[_currentPhase];
    final progress = _isActive
        ? 1 - (_countdown / phase.duration)
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🧘 Breathing Exercise'),
        actions: [
          if (_isActive)
            TextButton(
              onPressed: _stopBreathing,
              child: const Text('Stop', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (!_isActive) ...[
                const _Instructions().animate().fadeIn(),
                const SizedBox(height: 32),
              ],
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 140,
                        lineWidth: 20,
                        percent: progress,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(phase.icon, color: phase.color, size: 48)
                                .animate(target: _isActive ? 1 : 0)
                                .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.2, 1.2),
                                  duration: 1000.ms,
                                )
                                .then()
                                .scale(
                                  begin: const Offset(1.2, 1.2),
                                  end: const Offset(1, 1),
                                  duration: 1000.ms,
                                ),
                            const SizedBox(height: 16),
                            Text(
                              _isActive ? phase.name : 'Ready',
                              style: TextStyle(
                                color: _isActive ? phase.color : AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isActive ? '$_countdown' : '4-7-8',
                              style: TextStyle(
                                color: _isActive ? phase.color : AppColors.textSecondary,
                                fontSize: 64,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                        progressColor: phase.color,
                        backgroundColor: AppColors.border,
                        circularStrokeCap: CircularStrokeCap.round,
                        animation: false,
                      ),
                      const SizedBox(height: 48),
                      if (_isActive) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat_rounded,
                                  color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                '$_cyclesCompleted Cycles Completed',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (!_isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _startBreathing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Breathing',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _Phase {
  final String name;
  final int duration;
  final Color color;
  final IconData icon;

  _Phase({
    required this.name,
    required this.duration,
    required this.color,
    required this.icon,
  });
}

class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '4-7-8 Breathing Technique',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _InstructionStep(
            number: '1',
            text: 'Inhale through your nose for 4 seconds',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _InstructionStep(
            number: '2',
            text: 'Hold your breath for 7 seconds',
            color: AppColors.warning,
          ),
          const SizedBox(height: 12),
          _InstructionStep(
            number: '3',
            text: 'Exhale slowly through your mouth for 8 seconds',
            color: AppColors.accent,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This technique helps calm your nervous system and reduce urges.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;
  final Color color;

  const _InstructionStep({
    required this.number,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
