import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme.dart';
import 'models/journal_entry.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntry? entry;

  const JournalEntryScreen({super.key, this.entry});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _thoughtsController = TextEditingController();
  final _gratitudeController = TextEditingController();
  int _mood = 3;
  int _urgeIntensity = 5;
  final List<String> _selectedTriggers = [];
  
  final List<String> _commonTriggers = [
    'Stress', 'Boredom', 'Loneliness', 'Anxiety',
    'Social Media', 'Late Night', 'Tired', 'Angry',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _thoughtsController.text = widget.entry!.thoughts;
      _gratitudeController.text = widget.entry!.gratitude;
      _mood = widget.entry!.mood;
      _urgeIntensity = widget.entry!.urgeIntensity;
      _selectedTriggers.addAll(widget.entry!.triggers);
    }
  }

  Future<void> _saveEntry() async {
    final entry = JournalEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: widget.entry?.date ?? DateTime.now(),
      mood: _mood,
      triggers: _selectedTriggers,
      thoughts: _thoughtsController.text,
      gratitude: _gratitudeController.text,
      urgeIntensity: _urgeIntensity,
    );

    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('journal_entries') ?? [];
    final entries = entriesJson.map((e) => JournalEntry.fromJson(json.decode(e))).toList();
    
    if (widget.entry != null) {
      entries.removeWhere((e) => e.id == entry.id);
    }
    entries.add(entry);
    
    await prefs.setStringList(
      'journal_entries',
      entries.map((e) => json.encode(e.toJson())).toList(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New Entry' : 'Edit Entry'),
        actions: [
          TextButton(
            onPressed: _saveEntry,
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MoodSelector(
            mood: _mood,
            onChanged: (v) => setState(() => _mood = v),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 20),
          _UrgeIntensitySlider(
            intensity: _urgeIntensity,
            onChanged: (v) => setState(() => _urgeIntensity = v.toInt()),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),
          _TriggerSelector(
            triggers: _commonTriggers,
            selected: _selectedTriggers,
            onChanged: (trigger) {
              setState(() {
                if (_selectedTriggers.contains(trigger)) {
                  _selectedTriggers.remove(trigger);
                } else {
                  _selectedTriggers.add(trigger);
                }
              });
            },
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 20),
          _TextField(
            controller: _thoughtsController,
            label: '💭 Your Thoughts',
            hint: 'What\'s on your mind? How are you feeling?',
            maxLines: 5,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 20),
          _TextField(
            controller: _gratitudeController,
            label: '🙏 Gratitude',
            hint: 'What are you grateful for today?',
            maxLines: 3,
          ).animate().fadeIn(delay: 500.ms),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _thoughtsController.dispose();
    _gratitudeController.dispose();
    super.dispose();
  }
}

class _MoodSelector extends StatelessWidget {
  final int mood;
  final ValueChanged<int> onChanged;

  const _MoodSelector({required this.mood, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final moods = [
      (emoji: '😢', label: 'Bad', value: 1),
      (emoji: '😕', label: 'Low', value: 2),
      (emoji: '😐', label: 'Okay', value: 3),
      (emoji: '😊', label: 'Good', value: 4),
      (emoji: '😄', label: 'Great', value: 5),
    ];

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
          const Text('How are you feeling?',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: moods.map((m) {
              final isSelected = mood == m.value;
              return GestureDetector(
                onTap: () => onChanged(m.value),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(m.emoji,
                            style: TextStyle(fontSize: isSelected ? 28 : 24)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(m.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        )),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _UrgeIntensitySlider extends StatelessWidget {
  final int intensity;
  final ValueChanged<double> onChanged;

  const _UrgeIntensitySlider({
    required this.intensity,
    required this.onChanged,
  });

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Urge Intensity',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              Text('$intensity/10',
                  style: TextStyle(
                      color: _getIntensityColor(intensity),
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _getIntensityColor(intensity),
              inactiveTrackColor: AppColors.border,
              thumbColor: _getIntensityColor(intensity),
              overlayColor: _getIntensityColor(intensity).withOpacity(0.2),
            ),
            child: Slider(
              value: intensity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Low', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text('High', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int intensity) {
    if (intensity <= 3) return AppColors.accent;
    if (intensity <= 6) return AppColors.warning;
    return AppColors.danger;
  }
}

class _TriggerSelector extends StatelessWidget {
  final List<String> triggers;
  final List<String> selected;
  final ValueChanged<String> onChanged;

  const _TriggerSelector({
    required this.triggers,
    required this.selected,
    required this.onChanged,
  });

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
          const Text('Triggers',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: triggers.map((trigger) {
              final isSelected = selected.contains(trigger);
              return GestureDetector(
                onTap: () => onChanged(trigger),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.warning.withOpacity(0.2)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.warning : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    trigger,
                    style: TextStyle(
                      color: isSelected ? AppColors.warning : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _TextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

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
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
