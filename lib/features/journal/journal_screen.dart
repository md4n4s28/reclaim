import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/theme.dart';
import 'models/journal_entry.dart';
import 'journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<JournalEntry> _entries = [];
  bool _loading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList('journal_entries') ?? [];
    setState(() {
      _entries = entriesJson
          .map((e) => JournalEntry.fromJson(json.decode(e)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
    });
  }

  Future<void> _deleteEntry(String id) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    _entries.removeWhere((e) => e.id == id);
    await prefs.setStringList(
      'journal_entries',
      _entries.map((e) => json.encode(e.toJson())).toList(),
    );
    setState(() {});
  }

  List<JournalEntry> get _filteredEntries {
    if (_selectedFilter == 'victories') {
      return _entries.where((e) => e.mood >= 4).toList();
    } else if (_selectedFilter == 'struggles') {
      return _entries.where((e) => e.mood <= 2).toList();
    }
    return _entries;
  }

  void _openNewEntry({String? initialPrompt}) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JournalEntryScreen(),
      ),
    );
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'RECOVERY JOURNAL',
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
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGlow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGlow.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primaryGlow, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${_entries.length} ENTRIES',
                  style: const TextStyle(
                    color: AppColors.primaryGlow,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // Quick reflection starters
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'QUICK PROMPTS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _PromptPill(
                                label: '⚡ Urge Victory',
                                onTap: () => _openNewEntry(initialPrompt: 'How I beat my urge: '),
                              ),
                              _PromptPill(
                                label: '🌱 Gratitude',
                                onTap: () => _openNewEntry(initialPrompt: 'Today I am grateful for: '),
                              ),
                              _PromptPill(
                                label: '⚠️ Trigger Log',
                                onTap: () => _openNewEntry(initialPrompt: 'Trigger noticed: '),
                              ),
                              _PromptPill(
                                label: '🎯 Daily Win',
                                onTap: () => _openNewEntry(initialPrompt: 'My biggest win today: '),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter Chips Row
                        Row(
                          children: [
                            _FilterChip(
                              label: 'All (${_entries.length})',
                              isSelected: _selectedFilter == 'all',
                              onTap: () => setState(() => _selectedFilter = 'all'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Victories 😊',
                              isSelected: _selectedFilter == 'victories',
                              onTap: () => setState(() => _selectedFilter = 'victories'),
                            ),
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Struggles 🌧️',
                              isSelected: _selectedFilter == 'struggles',
                              onTap: () => setState(() => _selectedFilter = 'struggles'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Entries List
                if (_filteredEntries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onAdd: _openNewEntry),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = _filteredEntries[index];
                          return _EntryCard(
                            entry: entry,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => JournalEntryScreen(entry: entry),
                                ),
                              );
                              _loadEntries();
                            },
                            onDelete: () => _deleteEntry(entry.id),
                          ).animate().fadeIn(delay: Duration(milliseconds: index * 40)).slideY(begin: 0.04, end: 0);
                        },
                        childCount: _filteredEntries.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _openNewEntry(),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'WRITE NEW ENTRY',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: AppColors.primary.withOpacity(0.5),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
    );
  }
}

class _PromptPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Reflections Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Writing down your triggers and victories rewires neural pathways and reinforces self-discipline.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Write First Entry', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });

  String _getMoodLabel(int mood) {
    switch (mood) {
      case 1: return 'Rough';
      case 2: return 'Struggling';
      case 3: return 'Steady';
      case 4: return 'Good';
      case 5: return 'Victorious';
      default: return 'Steady';
    }
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1: return AppColors.danger;
      case 2: return AppColors.streakOrange;
      case 3: return AppColors.warning;
      case 4: return AppColors.primary;
      case 5: return AppColors.accent;
      default: return AppColors.primary;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final moodColor = _getMoodColor(entry.mood);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Mood Badge + Date + Options
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: moodColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    _getMoodLabel(entry.mood).toUpperCase(),
                    style: TextStyle(
                      color: moodColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(entry.date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '•  ${_formatTime(entry.date)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textMuted, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: const Text('Delete Entry?', style: TextStyle(color: AppColors.textPrimary)),
                        content: const Text(
                          'Are you sure you want to delete this journal entry?',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Thoughts preview
            if (entry.thoughts.isNotEmpty)
              Text(
                entry.thoughts,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

            // Gratitude snippet if present
            if (entry.gratitude.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: AppColors.accent, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      entry.gratitude,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Triggers tags preview
            if (entry.triggers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: entry.triggers.take(4).map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
