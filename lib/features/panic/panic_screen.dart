import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
        title: const Text('EMERGENCY MODE', style: TextStyle(color: AppColors.panicRed, fontWeight: FontWeight.w900, letterSpacing: 2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            const Text(
              "You are in control. This urge will pass. Do not give in to 5 seconds of pleasure for days of regret.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.4),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),
            const _GroundingChecklist(),
            const SizedBox(height: 40),
            const _ActionGrid(),
            const SizedBox(height: 30),
            const _IResistedButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _GroundingChecklist extends StatefulWidget {
  const _GroundingChecklist();

  @override
  State<_GroundingChecklist> createState() => _GroundingChecklistState();
}

class _GroundingChecklistState extends State<_GroundingChecklist> {
  final List<bool> _checked = List.filled(5, false);

  final List<Map<String, dynamic>> _steps = [
    {'number': '5', 'text': 'Things you can SEE', 'icon': Icons.visibility_rounded, 'color': AppColors.primary},
    {'number': '4', 'text': 'Things you can FEEL', 'icon': Icons.pan_tool_rounded, 'color': AppColors.accent},
    {'number': '3', 'text': 'Things you can HEAR', 'icon': Icons.hearing_rounded, 'color': AppColors.warning},
    {'number': '2', 'text': 'Things you can SMELL', 'icon': Icons.local_florist_rounded, 'color': AppColors.streakOrange},
    {'number': '1', 'text': 'Thing you can TASTE', 'icon': Icons.restaurant_rounded, 'color': AppColors.danger},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '5-4-3-2-1 GROUNDING',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        const Text(
          'Find these things in your room right now and check them off to bring your mind back to reality.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 20),
        ..._steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isChecked = _checked[index];
          final color = step['color'] as Color;

          return GestureDetector(
            onTap: () {
              setState(() {
                _checked[index] = !_checked[index];
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isChecked ? color.withOpacity(0.1) : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isChecked ? color.withOpacity(0.5) : AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      step['text'] as String,
                      style: TextStyle(
                        color: isChecked ? color : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: isChecked ? FontWeight.w700 : FontWeight.w600,
                        decoration: isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Icon(
                    isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    color: isChecked ? color : AppColors.textMuted,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 100))).slideX(begin: 0.1, end: 0),
          );
        }),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('IMMEDIATE ACTIONS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _ActionCard(icon: Icons.water_drop_rounded, title: 'Cold Water', subtitle: 'Splash face', color: AppColors.primary)),
            const SizedBox(width: 16),
            Expanded(child: _ActionCard(icon: Icons.fitness_center_rounded, title: 'Push-ups', subtitle: 'Do 15 now', color: AppColors.warning)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _ActionCard(icon: Icons.directions_walk_rounded, title: 'Walk', subtitle: 'Leave room', color: AppColors.accent)),
            const SizedBox(width: 16),
            Expanded(child: _ActionCard(icon: Icons.phone_rounded, title: 'Call Friend', subtitle: 'Accountability', color: AppColors.streakOrange, isPhone: true)),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isPhone;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isPhone = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isPhone) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add emergency contact in Settings')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _IResistedButton extends StatelessWidget {
  const _IResistedButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await context.read<AppProvider>().resistUrge();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('💪 Victory Logged! You are getting stronger.'),
              backgroundColor: AppColors.accent,
            ),
          );
          Navigator.pop(context);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF059669)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: const Center(
          child: Text(
            'I SURVIVED THIS URGE',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
  }
}