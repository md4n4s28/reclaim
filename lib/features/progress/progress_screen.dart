import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
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
  bool _isWeekFormat = false; // toggle between Compact Month vs 2-Week view

  final List<Map<String, String>> _allVideos = [
    {
      'title': 'Dopamine Detox Guide',
      'author': 'Evolve Daily',
      'url': 'https://youtu.be/LWTp-vrTfx8',
      'videoId': 'LWTp-vrTfx8',
      'duration': '14m',
    },
    {
      'title': 'Battle Against Impulses',
      'author': 'New Gen Army',
      'url': 'https://www.youtube.com/watch?v=lvgqcGrB5TY',
      'videoId': 'lvgqcGrB5TY',
      'duration': '12m',
    },
    {
      'title': 'Get Free from Addiction',
      'author': 'David Diga',
      'url': 'https://www.youtube.com/watch?v=lDF2t5D7Cmg',
      'videoId': 'lDF2t5D7Cmg',
      'duration': '22m',
    },
    {
      'title': 'What Lust Does to Brain',
      'author': 'Psych2Go',
      'url': 'https://youtu.be/tDBBDpZVX6Y',
      'videoId': 'tDBBDpZVX6Y',
      'duration': '8m',
    },
  ];

  final Map<String, bool> _habits = {
    'Morning Exercise': false,
    'Drink 3L Water': false,
    'Cold Shower': false,
    'Evening Journal': false,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().refreshUsageStats();
    });
  }

  void _showCustomDateDialog(BuildContext context, AppProvider provider, DateTime date) {
    final isRelapse = provider.relapses.any((r) => isSameDay(r, date));
    final formattedDate = "${date.day}/${date.month}/${date.year}";

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isRelapse ? AppColors.danger.withOpacity(0.15) : AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRelapse ? Icons.event_busy_rounded : Icons.event_available_rounded,
                        color: isRelapse ? AppColors.danger : AppColors.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Timeline: $formattedDate',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isRelapse ? 'Marked as Relapse Day' : 'Marked as Clean Day',
                          style: TextStyle(
                            color: isRelapse ? AppColors.danger : AppColors.accent,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!isRelapse)
                  _TimelineOptionTile(
                    icon: Icons.cancel_rounded,
                    iconColor: AppColors.danger,
                    title: 'Mark this day as Relapse',
                    subtitle: 'Missed logging? Record a past relapse on $formattedDate',
                    onTap: () {
                      provider.registerRelapse(customDate: date);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Marked $formattedDate as relapse.'),
                          backgroundColor: AppColors.danger,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                else
                  _TimelineOptionTile(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.accent,
                    title: 'Remove Relapse for this day',
                    subtitle: 'Mistake? Mark $formattedDate back as clean',
                    onTap: () {
                      provider.removeRelapse(date);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Restored $formattedDate as clean.'),
                          backgroundColor: AppColors.accent,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),
                _TimelineOptionTile(
                  icon: Icons.flag_rounded,
                  iconColor: AppColors.primaryGlow,
                  title: 'Start Streak from $formattedDate',
                  subtitle: 'Set this day as your new clean journey timeline',
                  onTap: () {
                    provider.setStreakStartDate(date);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sobriety journey starts from $formattedDate!'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImmediateRelapseDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 10),
            Text('Relapse Report', style: TextStyle(color: AppColors.textPrimary, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Did you relapse today?\n\nThis will record today as a relapse in your calendar and reset the live streak clock.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
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
                  content: Text('Relapse recorded. Take a breath and restart stronger!'),
                  backgroundColor: AppColors.danger,
                ),
              );
            },
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
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
        title: const Text(
          'Journey & Progress',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: _isWeekFormat ? 'Show Month' : 'Show 2-Week Compact',
            onPressed: () => setState(() => _isWeekFormat = !_isWeekFormat),
            icon: Icon(
              _isWeekFormat ? Icons.calendar_view_month_rounded : Icons.view_week_rounded,
              color: AppColors.primaryGlow,
              size: 20,
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) => ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            // 1. Ultra-Compact 4-Metric Grid (Streak, Longest, Urges, Time Saved)
            _CompactMetricsGrid(provider: provider),
            const SizedBox(height: 12),

            // 2. High-Density Sobriety Calendar
            _buildCompactCalendar(provider),
            const SizedBox(height: 12),

            // 3. Compact 7-Day Relapse Density Bar
            _buildCompactWeeklyBar(provider),
            const SizedBox(height: 12),

            // 4. Two-Column Row: Habit Checklist & Screen Time Monitor
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCompactHabits()),
                const SizedBox(width: 10),
                Expanded(child: _buildCompactScreenTime(provider)),
              ],
            ),
            const SizedBox(height: 12),

            // 5. Compact Masterclasses Horizontal Strip
            _buildCompactVideoStrip(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _buildCompactCalendar(AppProvider provider) {
    final relapses = provider.relapses;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: AppColors.primaryGlow, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Sobriety Log',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              // Compact Legend in Header
              const Row(
                children: [
                  _MiniDot(color: AppColors.accent, label: 'Clean'),
                  SizedBox(width: 8),
                  _MiniDot(color: AppColors.danger, label: 'Relapse'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Space-Efficient Calendar
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _isWeekFormat ? CalendarFormat.twoWeeks : CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            rowHeight: 34,
            daysOfWeekHeight: 18,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textSecondary, size: 18),
              rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
              headerPadding: EdgeInsets.zero,
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
              weekendStyle: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              outsideTextStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryGlow, width: 1.5),
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (day.isAfter(DateTime.now())) return null;

                final installDate = provider.installDate;
                if (installDate != null) {
                  final installDay = DateTime(installDate.year, installDate.month, installDate.day);
                  final targetDay = DateTime(day.year, day.month, day.day);
                  if (targetDay.isBefore(installDay)) return null;
                }

                final isRelapse = relapses.any((r) => isSameDay(r, day));

                return Container(
                  margin: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isRelapse ? AppColors.danger.withOpacity(0.18) : AppColors.accent.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRelapse ? AppColors.danger : AppColors.accent,
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isRelapse ? AppColors.danger : AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final isRelapse = relapses.any((r) => isSameDay(r, day));
                return Container(
                  margin: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    color: isRelapse ? AppColors.danger.withOpacity(0.2) : AppColors.accent.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRelapse ? AppColors.danger : AppColors.accent,
                      width: 1.8,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isRelapse ? AppColors.danger : AppColors.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              if (!selectedDay.isAfter(DateTime.now())) {
                HapticFeedback.lightImpact();
                _showCustomDateDialog(context, provider, selectedDay);
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 10),

          // Compact Action Bar (Quick Timeline Edit + Relapse Today)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final now = DateTime.now();
                    _showCustomDateDialog(context, provider, now);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'Edit Date / Start',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showImmediateRelapseDialog(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.5)),
                    ),
                    child: const Center(
                      child: Text(
                        'Record Relapse',
                        style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactWeeklyBar(AppProvider provider) {
    // Center the 7-day strip around the current viewed day (_selectedDay or _focusedDay)
    final anchorDay = _selectedDay ?? _focusedDay;
    // Monday of the anchorDay's week
    final monday = anchorDay.subtract(Duration(days: anchorDay.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    int cleanCount = 0;
    int relapseCount = 0;

    for (final d in days) {
      if (d.isAfter(now)) continue;
      final isRelapse = provider.relapses.any((r) => isSameDay(r, d));
      if (isRelapse) {
        relapseCount++;
      } else {
        cleanCount++;
      }
    }

    final totalPastDays = cleanCount + relapseCount;
    final cleanPercent = totalPastDays > 0 ? ((cleanCount / totalPastDays) * 100).round() : 100;
    final is100Clean = relapseCount == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week of ${monday.day}/${monday.month} Status',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (is100Clean ? AppColors.accent : AppColors.danger).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (is100Clean ? AppColors.accent : AppColors.danger).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  is100Clean ? '100% Clean Week ✨' : '$relapseCount Relapse ($cleanPercent% Clean)',
                  style: TextStyle(
                    color: is100Clean ? AppColors.accent : AppColors.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = days[i];
              final isFuture = d.isAfter(now);
              final isRelapse = provider.relapses.any((r) => isSameDay(r, d));
              final isToday = isSameDay(d, now);
              final isSelected = isSameDay(d, _selectedDay);

              final color = isFuture
                  ? AppColors.textMuted.withOpacity(0.3)
                  : (isRelapse ? AppColors.danger : AppColors.accent);

              return GestureDetector(
                onTap: () {
                  if (!isFuture) {
                    setState(() {
                      _selectedDay = d;
                      _focusedDay = d;
                    });
                    HapticFeedback.lightImpact();
                    _showCustomDateDialog(context, provider, d);
                  }
                },
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isFuture ? AppColors.surface : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryGlow
                              : (isToday ? Colors.white : (isFuture ? AppColors.border : color)),
                          width: (isSelected || isToday) ? 1.6 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isFuture
                              ? Icons.more_horiz_rounded
                              : (isRelapse ? Icons.close_rounded : Icons.check_rounded),
                          color: isFuture ? AppColors.textMuted : color,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isToday ? Colors.white : (isSelected ? AppColors.primaryGlow : AppColors.textMuted),
                        fontSize: 10,
                        fontWeight: (isToday || isSelected) ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        color: isFuture ? AppColors.textMuted.withOpacity(0.5) : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHabits() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: AppColors.accent, size: 14),
              SizedBox(width: 4),
              Text(
                'Daily Habits',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._habits.entries.map((e) {
            return GestureDetector(
              onTap: () => setState(() => _habits[e.key] = !(e.value)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: [
                    Icon(
                      e.value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                      color: e.value ? AppColors.accent : AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        e.key,
                        style: TextStyle(
                          color: e.value ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 10.5,
                          decoration: e.value ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactScreenTime(AppProvider provider) {
    final usage = provider.dailyUsageMinutes;
    final h = usage ~/ 60;
    final m = usage % 60;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: AppColors.warning, size: 14),
              SizedBox(width: 4),
              Text(
                'Screen Time',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (provider.hasUsagePermission) ...[
            Text(
              '${h}h ${m}m',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            const Text(
              'Monitored today',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (usage / 480).clamp(0.0, 1.0),
                backgroundColor: AppColors.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                minHeight: 4,
              ),
            ),
          ] else ...[
            const Text(
              'Track live usage',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => provider.requestUsagePermission(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Enable',
                    style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactVideoStrip() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recovery Masterclasses',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(
              'Expert Insights',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 125,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _allVideos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final video = _allVideos[index];
              final videoId = video['videoId'] ?? '';
              final thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final uri = Uri.parse(video['url']!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 125,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        // YouTube Thumbnail Image
                        Positioned.fill(
                          child: Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.videocam_rounded, color: AppColors.textMuted, size: 28),
                            ),
                          ),
                        ),
                        // Dark Gradient for readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.15),
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Play Icon Pill in Center-Top
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  video['duration'] ?? 'Video',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Video Info at Bottom
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                video['title']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                video['author']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CompactMetricsGrid extends StatelessWidget {
  final AppProvider provider;
  const _CompactMetricsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TinyStat(
            label: 'Streak',
            value: '${provider.streakDays}d',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.streakOrange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TinyStat(
            label: 'Best',
            value: '${provider.longestStreak}d',
            icon: Icons.military_tech_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TinyStat(
            label: 'Urges',
            value: '${provider.urgesResisted}',
            icon: Icons.shield_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _TinyStat(
            label: 'Saved',
            value: provider.focusTimeSavedLabel,
            icon: Icons.hourglass_top_rounded,
            color: AppColors.primaryGlow,
          ),
        ),
      ],
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TinyStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 13),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniDot extends StatelessWidget {
  final Color color;
  final String label;
  const _MiniDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _TimelineOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TimelineOptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
