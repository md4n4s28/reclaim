import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/app_provider.dart';

class PanicScreen extends StatefulWidget {
  const PanicScreen({super.key});

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnim;
  int _phase = 0; // 0=inhale, 1=hold, 2=exhale
  int _cycleCount = 0;

  static const _phaseLabels = ['Inhale', 'Hold', 'Exhale'];
  static const _phaseColors = [AppColors.primary, AppColors.warning, AppColors.accent];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnim = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
    _runPhase();
  }

  Future<void> _runPhase() async {
    while (mounted) {
      // Inhale
      setState(() => _phase = 0);
      await _breathController.forward(from: 0).orCancel.catchError((_) {});
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));

      // Hold
      setState(() => _phase = 1);
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;

      // Exhale
      setState(() => _phase = 2);
      await _breathController.reverse().orCancel.catchError((_) {});
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 100));

      setState(() => _cycleCount++);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panic Mode'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _BreathingCircle(
              animation: _breathAnim,
              phase: _phaseLabels[_phase],
              color: _phaseColors[_phase],
              cycles: _cycleCount,
            ),
            const SizedBox(height: 32),
            const _GroundingSection(),
            const SizedBox(height: 20),
            const _QuickActionsSection(),
            const SizedBox(height: 20),
            const _IResisted(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BreathingCircle extends StatelessWidget {
  final Animation<double> animation;
  final String phase;
  final Color color;
  final int cycles;

  const _BreathingCircle({
    required this.animation,
    required this.phase,
    required this.color,
    required this.cycles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Breathe with the circle',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: animation,
          builder: (_, __) {
            final size = 160.0 * animation.value;
            return SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow rings
                  for (int i = 0; i < 3; i++)
                    Transform.scale(
                      scale: (animation.value + i * 0.08).clamp(0.0, 1.5),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.08 - i * 0.02),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  // Main breathing circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.15),
                      border: Border.all(color: color.withOpacity(0.6), width: 2),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            phase,
                            key: ValueKey(phase),
                            style: TextStyle(
                              color: color,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('4-4-4',
                            style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (cycles > 0)
          Text(
            '$cycles cycle${cycles > 1 ? 's' : ''} completed 🎉',
            style: const TextStyle(color: AppColors.accent, fontSize: 13),
          ).animate().fadeIn(),
      ],
    );
  }
}

class _GroundingSection extends StatelessWidget {
  const _GroundingSection();

  static const _items = [
    ['👁️', 'Name 5 things you can see right now'],
    ['🦶', 'Feel your feet firmly on the ground'],
    ['🧊', 'Splash cold water on your face'],
    ['🚶', 'Stand up and move your body'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Grounding Techniques',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        for (int i = 0; i < _items.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(_items[i][0], style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_items[i][1],
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideX(begin: 0.1, end: 0),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static const _actions = [
    ['💪', 'Do 10\nPush-ups', 0xFF58A6FF],
    ['🚶', 'Walk\n2 minutes', 0xFF3FB950],
    ['💧', 'Drink\ncold water', 0xFFD29922],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Actions',
            style: TextStyle(
                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < _actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Color(_actions[i][2] as int).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(_actions[i][2] as int).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(_actions[i][0] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        _actions[i][1] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(_actions[i][2] as int),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _IResisted extends StatelessWidget {
  const _IResisted();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AppProvider>().resistUrge();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💪 Urge resisted! You\'re getting stronger.'),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.accent.withOpacity(0.2), AppColors.primary.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withOpacity(0.4)),
        ),
        child: const Column(
          children: [
            Text('✅ I Resisted This Urge',
                style: TextStyle(
                    color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Tap to log your victory and return',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
