import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/app_provider.dart';
import '../../core/bottom_nav.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, String>> _dailyVideos = [];

  final List<Map<String, String>> _allVideos = [
    {'title': 'How to Quit Porn Forever', 'author': 'Dr. Trish', 'url': 'https://www.youtube.com/watch?v=1'},
    {'title': 'The Huberman Lab on Dopamine', 'author': 'Andrew Huberman', 'url': 'https://www.youtube.com/watch?v=2'},
    {'title': 'Why You Lack Discipline', 'author': 'Hamza', 'url': 'https://www.youtube.com/watch?v=3'},
    {'title': 'The Great Porn Experiment', 'author': 'Gary Wilson', 'url': 'https://www.youtube.com/watch?v=4'},
    {'title': 'Dopamine Detox Guide', 'author': 'Better Than Yesterday', 'url': 'https://www.youtube.com/watch?v=5'},
    {'title': 'Overcoming Sexual Addiction', 'author': 'Terry Crews', 'url': 'https://www.youtube.com/watch?v=6'},
    {'title': 'Stop Watching Porn', 'author': 'Improvement Pill', 'url': 'https://www.youtube.com/watch?v=7'},
  ];

  @override
  void initState() {
    super.initState();
    // Shuffle and pick 4 random videos
    _allVideos.shuffle();
    _dailyVideos = _allVideos.take(4).toList();
    
    // Refresh usage stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshUsageStats();
    });
  }

  // Local state for mocked habits
  final Map<String, bool> _habits = {
    'Jogging (30m)': false,
    'Drink 4L Water': false,
    'Cold Shower': false,
    'Gym Session': false,
  };

  void _showRelapseDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 12),
            Text('Relapse Report', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Did you really relapse, or did you press this by mistake?\n\nIf you confirm, your current streak will be reset to 0 and today will be marked red.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mistake (Cancel)', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              provider.registerRelapse();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Relapse recorded. It\'s okay, keep pushing forward!'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('I Relapsed', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Journey & Progress'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StreakStatsRow(provider: provider),
            const SizedBox(height: 24),
            _buildCalendarSection(provider),
            const SizedBox(height: 24),
            _buildHabitsSection(),
            const SizedBox(height: 24),
            _buildScreenTimeSection(provider),
            const SizedBox(height: 24),
            _buildYouTubeSuggestions(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _buildCalendarSection(AppProvider provider) {
    final relapses = provider.relapses;
    
    // We treat all days prior to today as "clean" UNLESS they are in the relapse list.
    // For simplicity, we just mark relapse days red, and non-relapse days green if they are <= today.

    return GlowCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '📅 Activity Calendar'),
          const SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
              outsideTextStyle: const TextStyle(color: AppColors.textMuted),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (day.isAfter(DateTime.now())) return null; // Future days default
                
                // Do not mark days before installDate as clean
                final installDate = provider.installDate;
                if (installDate != null) {
                  final installDay = DateTime(installDate.year, installDate.month, installDate.day);
                  final targetDay = DateTime(day.year, day.month, day.day);
                  if (targetDay.isBefore(installDay)) return null;
                }

                final isRelapse = relapses.any((r) => isSameDay(r, day));
                
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isRelapse ? AppColors.danger.withOpacity(0.2) : AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRelapse ? AppColors.danger : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isRelapse ? AppColors.danger : AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final isRelapse = relapses.any((r) => isSameDay(r, day));
                return Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isRelapse ? AppColors.danger.withOpacity(0.2) : AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRelapse ? AppColors.danger : AppColors.accent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isRelapse ? AppColors.danger : AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, color: Colors.white24);
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppColors.accent, label: 'Clean'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.danger, label: 'Relapse'),
              const SizedBox(width: 16),
              _Legend(color: AppColors.primary, label: 'Selected'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('I Relapsed / Fapped'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger.withOpacity(0.1),
                foregroundColor: AppColors.danger,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
              onPressed: () => _showRelapseDialog(context, provider),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildHabitsSection() {
    return GlowCard(
      glowColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '✅ Daily Habits'),
          const SizedBox(height: 12),
          const Text(
            'Replace bad habits with powerful new ones.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          ..._habits.entries.map((e) => CheckboxListTile(
                title: Text(
                  e.key,
                  style: TextStyle(
                    color: e.value ? AppColors.textMuted : AppColors.textPrimary,
                    decoration: e.value ? TextDecoration.lineThrough : null,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: e.value,
                activeColor: AppColors.accent,
                checkColor: AppColors.background,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    _habits[e.key] = val ?? false;
                  });
                },
              )),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildScreenTimeSection(AppProvider provider) {
    if (!provider.hasUsagePermission) {
      return GlowCard(
        glowColor: AppColors.warning,
        child: Column(
          children: [
            const SectionTitle(title: '📱 Daily Phone Usage'),
            const SizedBox(height: 12),
            const Text(
              'Permission required to show actual screen time and digital wellbeing stats.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Grant Usage Permission',
              onTap: () => provider.requestUsagePermission(),
              color: AppColors.warning,
              icon: Icons.security_rounded,
            ),
          ],
        ),
      );
    }

    final usage = provider.dailyUsageMinutes;
    final hours = usage ~/ 60;
    final minutes = usage % 60;
    
    // Sort and get top 2 apps
    final sortedApps = provider.topApps.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topAppsLabel = sortedApps.take(2).map((e) {
      final name = e.key.split('.').last;
      final m = e.value ~/ 60000;
      return '${name.capitalize()} (${m}m)';
    }).join(', ');

    return GlowCard(
      glowColor: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '📱 Daily Phone Usage'),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smartphone_rounded, color: AppColors.warning, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${hours}h ${minutes}m', style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Actual usage tracked today', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (usage / 480).clamp(0.0, 1.0), // 8 hour goal
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text('Top apps: $topAppsLabel', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildYouTubeSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '🧠 Rewire Your Brain'),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dailyVideos.length,
            itemBuilder: (context, index) {
              final video = _dailyVideos[index];
              return GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(video['url']!);
                  try {
                    // Try to launch with external application (YouTube App)
                    final success = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!success && mounted) {
                      // Fallback: If external app fails, try platform default
                      await launchUrl(uri);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open video')),
                      );
                    }
                  }
                },
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 70,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: const Center(
                          child: Icon(Icons.play_circle_fill_rounded, color: AppColors.danger, size: 32),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video['title']!,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              video['author']!,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class _StreakStatsRow extends StatelessWidget {
  final AppProvider provider;
  const _StreakStatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Current Streak',
            value: '${provider.streakDays}',
            subtitle: 'Days Clean',
            color: AppColors.streakOrange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatBox(
            title: 'Longest Streak',
            value: '${provider.longestStreak}',
            subtitle: 'Personal Best',
            color: AppColors.primary,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
