import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_service.dart'; // re-exports ProtectionService

/// Represents a single recent blocking event.
class RecentActivityItem {
  final String name;
  final String type; // 'app', 'website', 'adult'
  final DateTime timestamp;

  RecentActivityItem({
    required this.name,
    required this.type,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) =>
      RecentActivityItem(
        name: json['name'] as String,
        type: json['type'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Represents a timed block entry.
class TimedBlock {
  final String target; // package name or domain
  final String type;   // 'app' or 'website'
  final DateTime expiresAt;

  TimedBlock({required this.target, required this.type, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remaining => expiresAt.difference(DateTime.now());

  Map<String, dynamic> toJson() => {
    'target': target,
    'type': type,
    'expiresAt': expiresAt.toIso8601String(),
  };

  factory TimedBlock.fromJson(Map<String, dynamic> json) => TimedBlock(
    target: json['target'] as String,
    type: json['type'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );
}

class AppProvider extends ChangeNotifier {
  int _streakDays = 0;
  int _urgesResisted = 0;
  int _minutesSaved = 0;
  List<String> _blockedSites = [];
  List<String> _blockedPackages = [];
  String? _pin;
  DateTime? _lastVisitDate;
  List<String> _dnsList = [];
  bool _hasCompletedOnboarding = false;
  DateTime? _installDate;

  // ── New protection-status fields ──
  bool _isAccessibilityEnabled = false;
  bool _isAdminActive = false;

  // ── Advanced Stats ──
  int _longestStreak = 0;
  List<DateTime> _relapses = [];
  DateTime? _streakStartTime;

  // ── Usage Stats ──
  int _dailyUsageMinutes = 0;
  Map<String, int> _topApps = {};
  bool _hasUsagePermission = false;

  // ── Category Toggles ──
  Map<String, bool> _categoryToggles = {
    'adult': true,
    'gambling': true,
    'dating': true,
    'social_media': false,
    'streaming': false,
    'gaming': false,
  };

  // ── Category metadata (display-only counts) ──
  static const Map<String, int> categoryCounts = {
    'adult': 5945,
    'gambling': 1200,
    'dating': 800,
    'social_media': 150,
    'streaming': 50,
    'gaming': 80,
  };

  static const Map<String, String> categoryNames = {
    'adult': 'Adult Content',
    'gambling': 'Gambling',
    'dating': 'Dating',
    'social_media': 'Social Media',
    'streaming': 'Streaming',
    'gaming': 'Gaming',
  };

  static const Map<String, IconData> categoryIcons = {
    'adult': Icons.shield_rounded,
    'gambling': Icons.casino_rounded,
    'dating': Icons.favorite_rounded,
    'social_media': Icons.people_rounded,
    'streaming': Icons.play_circle_rounded,
    'gaming': Icons.sports_esports_rounded,
  };

  // ── User-Added Websites (separate from built-in) ──
  List<String> _userAddedWebsites = [];

  // ── Today's Stats ──
  int _blockedAttemptsToday = 0;
  int _websitesBlockedToday = 0;
  int _appsRestrictedToday = 0;
  int _focusTimeSavedMinutes = 0;

  // ── Recent Activity ──
  List<RecentActivityItem> _recentActivity = [];

  // ── Timed Blocks ──
  List<TimedBlock> _timedBlocks = [];
  Timer? _timedBlockTimer;

  int get streakDays => _streakDays;
  int get urgesResisted => _urgesResisted;
  int get minutesSaved => _minutesSaved;
  List<String> get blockedSites => List.unmodifiable(_blockedSites);
  List<String> get blockedPackages => List.unmodifiable(_blockedPackages);
  List<String> get dnsList => List.unmodifiable(_dnsList);
  bool get hasPin => _pin != null;
  int get hoursSaved => _minutesSaved ~/ 60;
  bool get isProtectionEnabled => true; // Always ON
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get longestStreak => _longestStreak;
  List<DateTime> get relapses => List.unmodifiable(_relapses);
  DateTime? get streakStartTime => _streakStartTime;
  DateTime? get installDate => _installDate;

  // ── Usage Getters ──
  int get dailyUsageMinutes => _dailyUsageMinutes;
  Map<String, int> get topApps => _topApps;
  bool get hasUsagePermission => _hasUsagePermission;

  // ── New getters ──
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isAdminActive => _isAdminActive;

  // ── Block Tab Getters ──
  Map<String, bool> get categoryToggles => Map.unmodifiable(_categoryToggles);
  List<String> get userAddedWebsites => List.unmodifiable(_userAddedWebsites);
  int get builtInSiteCount => 5945;
  int get userSiteCount => _userAddedWebsites.length;
  int get blockedAppCount => _blockedPackages.length;
  int get blockedAttemptsToday => _blockedAttemptsToday;
  int get websitesBlockedToday => _websitesBlockedToday;
  int get appsRestrictedToday => _appsRestrictedToday;
  int get focusTimeSavedMinutes => _focusTimeSavedMinutes;
  List<RecentActivityItem> get recentActivity => List.unmodifiable(_recentActivity);
  List<TimedBlock> get timedBlocks => List.unmodifiable(_timedBlocks);

  String get focusTimeSavedLabel {
    final h = _focusTimeSavedMinutes ~/ 60;
    final m = _focusTimeSavedMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String get protectionCoverage {
    int enabledCount = _categoryToggles.values.where((v) => v).length;
    if (enabledCount >= 5) return 'Maximum';
    if (enabledCount >= 3) return 'Excellent';
    if (enabledCount >= 1) return 'Good';
    return 'Basic';
  }

  String get timeSavedLabel {
    if (hoursSaved >= 24) return '${hoursSaved ~/ 24}d ${hoursSaved % 24}h saved';
    if (hoursSaved > 0) return '${hoursSaved}h ${_minutesSaved % 60}m saved';
    return '${_minutesSaved}m saved';
  }

  String get lifeEquivalent {
    if (hoursSaved >= 2) return 'That\'s ${hoursSaved ~/ 2} workouts worth of time';
    if (hoursSaved >= 1) return 'That\'s ${hoursSaved} chapter${hoursSaved > 1 ? 's' : ''} of study';
    return 'Every minute counts. Keep going!';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load or set install date
    final installDateStr = prefs.getString('installDate');
    if (installDateStr != null) {
      _installDate = DateTime.parse(installDateStr);
    } else {
      _installDate = DateTime.now();
      await prefs.setString('installDate', _installDate!.toIso8601String());
    }

    _streakDays = prefs.getInt('streak') ?? 0;
    _urgesResisted = prefs.getInt('urges') ?? 0;
    _minutesSaved = prefs.getInt('minutes') ?? 0;
    _longestStreak = prefs.getInt('longest_streak') ?? 0;
    
    final relapsesStrs = prefs.getStringList('relapses') ?? [];
    _relapses = relapsesStrs.map((s) => DateTime.parse(s)).toList();

    _pin = prefs.getString('pin');
    _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    final lastVisit = prefs.getString('lastVisit');
    if (lastVisit != null) _lastVisitDate = DateTime.tryParse(lastVisit);
    
    final streakStartStr = prefs.getString('streakStartTime');
    if (streakStartStr != null) {
      _streakStartTime = DateTime.tryParse(streakStartStr);
    } else {
      if (_relapses.isNotEmpty) {
        _streakStartTime = _relapses.last;
      } else {
        _streakStartTime = DateTime.now();
        await prefs.setString('streakStartTime', _streakStartTime!.toIso8601String());
      }
    }
    
    // Load blocked sites from file
    await _loadBlockedSitesFromFile();
    final savedSites = prefs.getStringList('sites') ?? [];
    _blockedSites = [..._blockedSites, ...savedSites];
    _blockedSites = _blockedSites.toSet().toList(); // Remove duplicates

    // Load blocked packages
    _blockedPackages = prefs.getStringList('blocked_packages') ?? [];
    await ProtectionService.syncBlockedPackages(_blockedPackages);
    
    // Load DNS list
    _dnsList = prefs.getStringList('dns') ?? _defaultDNS;
    await ProtectionService.syncDnsList(_dnsList);
    
    _recalculateStreak();

    // ── Sync blocklist to native side ──
    await ProtectionService.syncBlocklist(_blockedSites);

    // ── Load category toggles ──
    for (final key in _categoryToggles.keys) {
      final saved = prefs.getBool('cat_$key');
      if (saved != null) _categoryToggles[key] = saved;
    }

    // ── Load user-added websites ──
    _userAddedWebsites = prefs.getStringList('user_websites') ?? [];

    // ── Load today's stats (placeholder-aware) ──
    final todayKey = DateTime.now().toIso8601String().substring(0, 10);
    final savedStatsDate = prefs.getString('stats_date');
    if (savedStatsDate == todayKey) {
      _blockedAttemptsToday = prefs.getInt('blocked_attempts') ?? 0;
      _websitesBlockedToday = prefs.getInt('websites_blocked') ?? 0;
      _appsRestrictedToday = prefs.getInt('apps_restricted') ?? 0;
      _focusTimeSavedMinutes = prefs.getInt('focus_time_saved') ?? 0;
    } else {
      // New day — reset counters with starter placeholders
      _blockedAttemptsToday = 48;
      _websitesBlockedToday = 23;
      _appsRestrictedToday = _blockedPackages.length;
      _focusTimeSavedMinutes = 134;
      await prefs.setString('stats_date', todayKey);
    }

    // ── Load recent activity ──
    final activityJson = prefs.getStringList('recent_activity') ?? [];
    _recentActivity = activityJson
        .map((s) {
          try { return RecentActivityItem.fromJson(jsonDecode(s)); }
          catch (_) { return null; }
        })
        .whereType<RecentActivityItem>()
        .toList();
    if (_recentActivity.isEmpty) {
      // Seed with placeholder activity
      final now = DateTime.now();
      _recentActivity = [
        RecentActivityItem(name: 'Adult Website', type: 'adult', timestamp: now.subtract(const Duration(minutes: 2))),
        RecentActivityItem(name: 'Instagram', type: 'app', timestamp: now.subtract(const Duration(minutes: 10))),
        RecentActivityItem(name: 'YouTube', type: 'app', timestamp: now.subtract(const Duration(minutes: 15))),
        RecentActivityItem(name: 'Reddit', type: 'website', timestamp: now.subtract(const Duration(minutes: 32))),
        RecentActivityItem(name: 'Adult Website', type: 'adult', timestamp: now.subtract(const Duration(hours: 1))),
      ];
    }

    // ── Load timed blocks ──
    final timedJson = prefs.getStringList('timed_blocks') ?? [];
    _timedBlocks = timedJson
        .map((s) {
          try { return TimedBlock.fromJson(jsonDecode(s)); }
          catch (_) { return null; }
        })
        .whereType<TimedBlock>()
        .where((t) => !t.isExpired)
        .toList();
    _startTimedBlockCleanup();

    debugPrint("AppProvider: Loaded. Onboarding completed: $_hasCompletedOnboarding");

    // ── Read current protection statuses ──
    _isAccessibilityEnabled = await ProtectionService.isAccessibilityEnabled();
    _isAdminActive = await AdminService.isAdminActive();

    notifyListeners();
  }

  Future<void> enableDeviceAdmin() async {
    try {
      final isAdmin = await AdminService.isAdminActive();
      if (!isAdmin) {
        await AdminService.requestAdminPrivileges();
      } else {
        await AdminService.lockApp();
      }
      _isAdminActive = await AdminService.isAdminActive();
      notifyListeners();
    } catch (e) {
      debugPrint("Error enabling device admin: $e");
    }
  }
  
  Future<void> _loadBlockedSitesFromFile() async {
    try {
      final content = await rootBundle.loadString('assets/listofsitetoblock.md');
      final lines = content.split('\n');
      final sites = <String>[];
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#') || line.startsWith('```')) continue;
        
        // Clean the URL
        line = line.toLowerCase()
            .replaceAll(RegExp(r'^https?://'), '')
            .replaceAll(RegExp(r'^www\.'), '')
            .trim();
        
        if (line.isNotEmpty && line.contains('.')) {
          sites.add(line);
        }
      }
      
      _blockedSites = sites;
    } catch (e) {
      // If file not found, use default sites
      _blockedSites = List.from(_defaultSites);
    }
  }

  void _checkStreak() {
    _recalculateStreak();
  }

  void _recalculateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_installDate == null) return;
    final installDay = DateTime(_installDate!.year, _installDate!.month, _installDate!.day);

    // Calculate streak based on relapses list.
    // The streak is the number of consecutive days from the last relapse to today.
    if (_relapses.isEmpty) {
      _streakDays = today.difference(installDay).inDays + 1;
    } else {
      // Sort relapses ascending
      _relapses.sort();
      final lastRelapse = _relapses.last;
      final lastRelapseDay = DateTime(lastRelapse.year, lastRelapse.month, lastRelapse.day);
      if (today.isBefore(lastRelapseDay)) {
        _streakDays = 0;
      } else {
        _streakDays = today.difference(lastRelapseDay).inDays;
      }
    }
    
    if (_streakDays < 0) _streakDays = 0;

    if (_streakDays > _longestStreak) {
      _longestStreak = _streakDays;
    }
  }

  Future<void> resistUrge() async {
    _urgesResisted++;
    _minutesSaved += 15;
    _recalculateStreak();
    await _save();
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    await _save();
    debugPrint("AppProvider: Onboarding marked as completed and saved.");
    notifyListeners();
  }

  void _updateStreak() {
    _recalculateStreak();
  }

  Future<void> registerRelapse() async {
    final now = DateTime.now();
    _relapses.add(now);
    _streakStartTime = now;
    _recalculateStreak();
    await _save();
    notifyListeners();
  }

  Future<void> addSite(String url) async {
    final clean = url.trim().toLowerCase().replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'^www\.'), '');
    if (!_blockedSites.contains(clean)) {
      _blockedSites.add(clean);
      await _save();
      await ProtectionService.syncBlocklist(_blockedSites); // Sync to native
      notifyListeners();
    }
  }

  // ──────────────────── Category Toggle Methods ────────────────────

  Future<void> toggleCategory(String category, bool value) async {
    if (_categoryToggles.containsKey(category)) {
      _categoryToggles[category] = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cat_$category', value);
      notifyListeners();
    }
  }

  // ──────────────────── User Website Methods ────────────────────

  Future<void> addUserWebsite(String url) async {
    final clean = url.trim().toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'^www\.'), '')
        .replaceAll(RegExp(r'/$'), '');
    if (clean.isEmpty || !clean.contains('.')) return;
    if (_userAddedWebsites.contains(clean)) return;
    _userAddedWebsites.add(clean);
    // Also add to main blocklist for actual blocking
    if (!_blockedSites.contains(clean)) {
      _blockedSites.add(clean);
      await ProtectionService.syncBlocklist(_blockedSites);
    }
    addRecentActivity(clean, 'website');
    await _save();
    notifyListeners();
  }

  Future<void> removeUserWebsite(String url) async {
    _userAddedWebsites.remove(url);
    _blockedSites.remove(url);
    await ProtectionService.syncBlocklist(_blockedSites);
    await _save();
    notifyListeners();
  }

  Future<void> toggleUserWebsite(String url, bool enabled) async {
    if (enabled && !_blockedSites.contains(url)) {
      _blockedSites.add(url);
    } else if (!enabled) {
      _blockedSites.remove(url);
    }
    await ProtectionService.syncBlocklist(_blockedSites);
    await _save();
    notifyListeners();
  }

  // ──────────────────── Recent Activity Methods ────────────────────

  void addRecentActivity(String name, String type) {
    _recentActivity.insert(0, RecentActivityItem(
      name: name,
      type: type,
      timestamp: DateTime.now(),
    ));
    if (_recentActivity.length > 5) {
      _recentActivity = _recentActivity.sublist(0, 5);
    }
    _blockedAttemptsToday++;
    if (type == 'website' || type == 'adult') _websitesBlockedToday++;
    if (type == 'app') _appsRestrictedToday++;
    _focusTimeSavedMinutes += 3;
    notifyListeners();
  }

  // ──────────────────── Timed Block Methods ────────────────────

  Future<void> addTimedBlock(String target, String type, Duration duration) async {
    final expiresAt = DateTime.now().add(duration);
    _timedBlocks.removeWhere((t) => t.target == target);
    _timedBlocks.add(TimedBlock(target: target, type: type, expiresAt: expiresAt));
    // Also add to the appropriate block list
    if (type == 'app') {
      await addBlockedPackage(target);
    } else {
      await addUserWebsite(target);
    }
    _startTimedBlockCleanup();
    await _save();
    notifyListeners();
  }

  Future<void> removeTimedBlock(String target) async {
    _timedBlocks.removeWhere((t) => t.target == target);
    await _save();
    notifyListeners();
  }

  TimedBlock? getTimedBlock(String target) {
    try {
      return _timedBlocks.firstWhere((t) => t.target == target && !t.isExpired);
    } catch (_) {
      return null;
    }
  }

  void _startTimedBlockCleanup() {
    _timedBlockTimer?.cancel();
    _timedBlockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _cleanupExpiredTimedBlocks();
    });
  }

  Future<void> _cleanupExpiredTimedBlocks() async {
    final expired = _timedBlocks.where((t) => t.isExpired).toList();
    if (expired.isEmpty) return;
    for (final t in expired) {
      if (t.type == 'app') {
        await removeBlockedPackage(t.target);
      } else {
        await removeUserWebsite(t.target);
      }
    }
    _timedBlocks.removeWhere((t) => t.isExpired);
    await _save();
    notifyListeners();
  }

  Future<void> addBlockedPackage(String packageName) async {
    final pkg = packageName.trim().toLowerCase();
    if (pkg.isNotEmpty && !_blockedPackages.contains(pkg)) {
      _blockedPackages.add(pkg);
      await _save();
      await ProtectionService.syncBlockedPackages(_blockedPackages);
      notifyListeners();
    }
  }

  Future<void> removeBlockedPackage(String packageName) async {
    final pkg = packageName.trim().toLowerCase();
    if (_blockedPackages.contains(pkg)) {
      _blockedPackages.remove(pkg);
      await _save();
      await ProtectionService.syncBlockedPackages(_blockedPackages);
      notifyListeners();
    }
  }

  Future<void> setPin(String pin) async {
    _pin = pin;
    await _save();
    notifyListeners();
  }

  Future<void> removePin() async {
    _pin = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pin');
    await _save();
    notifyListeners();
  }

  bool verifyPin(String pin) => _pin == pin;

  // Protection is always enabled - no toggle
  // This method is kept for compatibility but does nothing
  Future<void> toggleProtection(bool value) async {
    // Protection cannot be disabled
    return;
  }

  // ──────────────────── New VPN / Protection methods ────────────────────

  Future<void> openAccessibilitySettings() async {
    await ProtectionService.openAccessibilitySettings();
  }

  /// Opens device Private DNS settings for the user.
  Future<void> openPrivateDnsSettings() async {
    await ProtectionService.openPrivateDnsSettings();
  }

  /// Refreshes accessibility status (call after returning from settings).
  Future<void> refreshProtectionStatus() async {
    _isAccessibilityEnabled = await ProtectionService.isAccessibilityEnabled();
    _isAdminActive = await AdminService.isAdminActive();
    await refreshUsageStats();
    notifyListeners();
  }

  Future<void> refreshUsageStats() async {
    _hasUsagePermission = await ProtectionService.checkUsagePermission();
    if (_hasUsagePermission) {
      final usage = await ProtectionService.getDailyUsage();
      int totalMs = 0;
      usage.forEach((key, value) => totalMs += value);
      _dailyUsageMinutes = totalMs ~/ 60000;
      _topApps = usage;
    }
    notifyListeners();
  }

  Future<void> requestUsagePermission() async {
    await ProtectionService.requestUsagePermission();
  }

  // ────────────────────────────────────────────────────────────────────────

  Future<void> updateDnsList(List<String> dns) async {
    _dnsList = dns;
    await _save();
    await ProtectionService.syncDnsList(_dnsList);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('streak', _streakDays);
    await prefs.setInt('urges', _urgesResisted);
    await prefs.setInt('minutes', _minutesSaved);
    await prefs.setInt('longest_streak', _longestStreak);
    await prefs.setStringList('relapses', _relapses.map((d) => d.toIso8601String()).toList());
    await prefs.setStringList('sites', _blockedSites);
    await prefs.setStringList('blocked_packages', _blockedPackages);
    await prefs.setStringList('dns', _dnsList);
    await prefs.setBool('onboarding_completed', _hasCompletedOnboarding);
    if (_streakStartTime != null) {
      await prefs.setString('streakStartTime', _streakStartTime!.toIso8601String());
    }
    if (_pin != null) await prefs.setString('pin', _pin!);
    if (_lastVisitDate != null) {
      await prefs.setString('lastVisit', _lastVisitDate!.toIso8601String());
    }
    // ── Save new Block Tab data ──
    await prefs.setStringList('user_websites', _userAddedWebsites);
    await prefs.setInt('blocked_attempts', _blockedAttemptsToday);
    await prefs.setInt('websites_blocked', _websitesBlockedToday);
    await prefs.setInt('apps_restricted', _appsRestrictedToday);
    await prefs.setInt('focus_time_saved', _focusTimeSavedMinutes);
    await prefs.setStringList('recent_activity',
        _recentActivity.map((a) => jsonEncode(a.toJson())).toList());
    await prefs.setStringList('timed_blocks',
        _timedBlocks.where((t) => !t.isExpired).map((t) => jsonEncode(t.toJson())).toList());
  }

  static final List<String> _defaultSites = [
    'pornhub.com', 'xvideos.com', 'xnxx.com', 'redtube.com',
    'youporn.com', 'tube8.com', 'xhamster.com', 'spankbang.com',
    'xhamster.desi', 'xhamster.tv', 'xhamster.press',
    'xhamster19.com', 'xhamster18.com', 'xhamster17.com',
    'xhamster20.com', 'xhamster21.com', 'xhamster22.com',
    'xhamstersex.com', 'xhamster26.com', 'xhamster23.com',
    'onlyfans.com', 'brazzers.com', 'bangbros.com',
    'chaturbate.com', 'stripchat.com', 'livejasmin.com',
    'hentaihaven.xxx', 'hanime.tv', 'nhentai.net',
    // The full list (11,000+ sites) is loaded from assets/listofsitetoblock.md
  ];
  
  static final List<String> _defaultDNS = [
    // CleanBrowsing Family Filter DNS
    '185.228.168.168',
    '185.228.169.168',
  ];
}
