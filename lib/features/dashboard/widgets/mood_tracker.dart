import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme.dart';

class InteractiveMoodTracker extends StatefulWidget {
  const InteractiveMoodTracker({super.key});

  @override
  State<InteractiveMoodTracker> createState() => _InteractiveMoodTrackerState();
}

class _InteractiveMoodTrackerState extends State<InteractiveMoodTracker> {
  int? _selectedMood;
  _MoodData? _activeMoodData;

  final List<_MoodData> _moods = [
    _MoodData(
      value: 1,
      emoji: '😢',
      label: 'Struggling',
      color: AppColors.danger,
      quote: '“Rock bottom became the solid foundation on which I rebuilt my life.”',
      author: 'J.K. Rowling',
      actionTitle: 'Take 2-Min Reset',
      actionRoute: '/breathing',
      videoUrl: 'https://youtu.be/LWTp-vrTfx8',
      videoTitle: 'Watch: Dopamine Reset Guide',
    ),
    _MoodData(
      value: 2,
      emoji: '😕',
      label: 'Anxious',
      color: AppColors.warning,
      quote: '“You don\'t have to control your thoughts. You just have to stop letting them control you.”',
      author: 'Dan Millman',
      actionTitle: 'Emergency SOS',
      actionRoute: '/panic',
      videoUrl: 'https://youtu.be/tDBBDpZVX6Y',
      videoTitle: 'Watch: What Lust Does to the Brain',
    ),
    _MoodData(
      value: 3,
      emoji: '😐',
      label: 'Neutral',
      color: AppColors.textSecondary,
      quote: '“Small disciplines repeated with consistency every day lead to great achievements.”',
      author: 'John C. Maxwell',
      actionTitle: 'Write Reflection',
      actionRoute: '/journal',
      videoUrl: 'https://www.youtube.com/watch?v=lvgqcGrB5TY',
      videoTitle: 'Watch: Battle Against Impulses',
    ),
    _MoodData(
      value: 4,
      emoji: '😊',
      label: 'Focused',
      color: AppColors.accent,
      quote: '“He who conquers himself is the mightiest warrior.”',
      author: 'Confucius',
      actionTitle: 'Log Wins',
      actionRoute: '/journal',
      videoUrl: 'https://www.youtube.com/watch?v=lDF2t5D7Cmg',
      videoTitle: 'Watch: Staying Free Long-Term',
    ),
    _MoodData(
      value: 5,
      emoji: '⚡',
      label: 'Unstoppable',
      color: AppColors.primaryGlow,
      quote: '“The secret of change is to focus all of your energy not on fighting the old, but on building the new.”',
      author: 'Socrates',
      actionTitle: 'Review Progress',
      actionRoute: '/progress',
      videoUrl: null,
      videoTitle: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadMood();
  }

  Future<void> _loadMood() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final moodVal = prefs.getInt('mood_$today');
    if (moodVal != null) {
      final found = _moods.firstWhere((m) => m.value == moodVal, orElse: () => _moods[2]);
      setState(() {
        _selectedMood = moodVal;
        _activeMoodData = found;
      });
    }
  }

  Future<void> _selectMood(_MoodData mood) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setInt('mood_$today', mood.value);
    setState(() {
      _selectedMood = mood.value;
      _activeMoodData = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.primaryGlow, size: 18),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How are you feeling right now?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select to get instant tailored guidance & advice',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mood Choice Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _moods.map((mood) {
              final isSelected = _selectedMood == mood.value;
              return GestureDetector(
                onTap: () => _selectMood(mood),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? mood.color.withOpacity(0.18) : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? mood.color : AppColors.border,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(mood.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          color: isSelected ? mood.color : AppColors.textSecondary,
                          fontSize: 9.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          // Dynamic Interactive Advice & Motivation Box
          if (_activeMoodData != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _activeMoodData!.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: _activeMoodData!.color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'GUIDANCE FOR "${_activeMoodData!.label.toUpperCase()}"',
                        style: TextStyle(
                          color: _activeMoodData!.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeMoodData!.quote,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${_activeMoodData!.author}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Direct action button (e.g. Breathe or Panic)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, _activeMoodData!.actionRoute),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: _activeMoodData!.color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _activeMoodData!.actionTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_activeMoodData!.videoUrl != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final uri = Uri.parse(_activeMoodData!.videoUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.danger, size: 14),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Watch Guide',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.08, end: 0),
          ],
        ],
      ),
    );
  }
}

class _MoodData {
  final int value;
  final String emoji;
  final String label;
  final Color color;
  final String quote;
  final String author;
  final String actionTitle;
  final String actionRoute;
  final String? videoUrl;
  final String? videoTitle;

  _MoodData({
    required this.value,
    required this.emoji,
    required this.label,
    required this.color,
    required this.quote,
    required this.author,
    required this.actionTitle,
    required this.actionRoute,
    this.videoUrl,
    this.videoTitle,
  });
}
