import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';

class FocusCard extends StatefulWidget {
  const FocusCard({super.key});

  @override
  State<FocusCard> createState() => _FocusCardState();
}

class _FocusCardState extends State<FocusCard> {
  String _focus = "I will stay disciplined today";
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFocus();
  }

  Future<void> _loadFocus() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedFocus = prefs.getString('focus_$today');
    if (savedFocus != null) {
      setState(() => _focus = savedFocus);
    }
  }

  Future<void> _saveFocus(String focus) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('focus_$today', focus);
    setState(() => _focus = focus);
  }

  void _showEditDialog() {
    _controller.text = _focus;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('🎯 Set Today\'s Focus',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: _controller,
          maxLength: 100,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'What\'s your intention today?',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _saveFocus(_controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showEditDialog,
      child: GlowCard(
        glowColor: AppColors.primary,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.track_changes_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🎯 Today\'s Focus',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(_focus,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded,
                color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
