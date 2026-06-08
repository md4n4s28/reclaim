import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

class MoodTracker extends StatefulWidget {
  const MoodTracker({super.key});

  @override
  State<MoodTracker> createState() => _MoodTrackerState();
}

class _MoodTrackerState extends State<MoodTracker> {
  int? _selectedMood;
  final List<_Mood> _moods = [
    _Mood(emoji: '😢', label: 'Struggling', value: 1, color: AppColors.danger),
    _Mood(emoji: '😕', label: 'Difficult', value: 2, color: AppColors.warning),
    _Mood(emoji: '😐', label: 'Okay', value: 3, color: Colors.grey),
    _Mood(emoji: '😊', label: 'Good', value: 4, color: AppColors.accent),
    _Mood(emoji: '😄', label: 'Great', value: 5, color: AppColors.primary),
  ];

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  Future<void> _loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final mood = prefs.getInt('mood_$today');
    if (mood != null) {
      setState(() => _selectedMood = mood);
    }
  }

  Future<void> _saveMood(int mood) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('mood_$today', mood);
    setState(() => _selectedMood = mood);
  }

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mood_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💭 How are you feeling?',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text('Track your daily mood',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return GestureDetector(
                onTap: () => _saveMood(mood.value),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mood.color.withOpacity(0.2)
                            : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? mood.color
                              : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          mood.emoji,
                          style: TextStyle(
                            fontSize: isSelected ? 28 : 24,
                          ),
                        ),
                      ),
                    )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 200.ms,
                        ),
                    const SizedBox(height: 4),
                    Text(
                      mood.label,
                      style: TextStyle(
                        color: isSelected
                            ? mood.color
                            : AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Mood {
  final String emoji;
  final String label;
  final int value;
  final Color color;

  _Mood({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });
}
