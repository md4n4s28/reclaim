import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_service.dart'; // re-exports ProtectionService

class AppProvider extends ChangeNotifier {
  int _streakDays = 0;
  int _urgesResisted = 0;
  int _minutesSaved = 0;
  List<String> _blockedSites = [];
  String? _pin;
  DateTime? _lastVisitDate;
  List<String> _dnsList = [];
  bool _hasCompletedOnboarding = false;

  // ── New protection-status fields ──
  bool _isVpnRunning = false;
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

  int get streakDays => _streakDays;
  int get urgesResisted => _urgesResisted;
  int get minutesSaved => _minutesSaved;
  List<String> get blockedSites => List.unmodifiable(_blockedSites);
  List<String> get dnsList => List.unmodifiable(_dnsList);
  bool get hasPin => _pin != null;
  int get hoursSaved => _minutesSaved ~/ 60;
  bool get isProtectionEnabled => true; // Always ON
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  int get longestStreak => _longestStreak;
  List<DateTime> get relapses => List.unmodifiable(_relapses);
  DateTime? get streakStartTime => _streakStartTime;

  // ── Usage Getters ──
  int get dailyUsageMinutes => _dailyUsageMinutes;
  Map<String, int> get topApps => _topApps;
  bool get hasUsagePermission => _hasUsagePermission;

  // ── New getters ──
  bool get isVpnRunning => _isVpnRunning;
  bool get isAccessibilityEnabled => _isAccessibilityEnabled;
  bool get isAdminActive => _isAdminActive;

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
    
    // Load DNS list
    _dnsList = prefs.getStringList('dns') ?? _defaultDNS;
    await ProtectionService.syncDnsList(_dnsList);
    
    _checkStreak();

    // ── Sync blocklist to native side ──
    await ProtectionService.syncBlocklist(_blockedSites);

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
    final now = DateTime.now();
    if (_lastVisitDate == null) {
      _lastVisitDate = now;
      return;
    }
    final diff = now.difference(_lastVisitDate!).inDays;
    if (diff >= 2) _streakDays = 0; // missed a day
  }

  Future<void> resistUrge() async {
    _urgesResisted++;
    _minutesSaved += 15;
    _updateStreak();
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
    final now = DateTime.now();
    if (_lastVisitDate == null ||
        now.difference(_lastVisitDate!).inDays >= 1) {
      _streakDays++;
      if (_streakDays > _longestStreak) {
        _longestStreak = _streakDays;
      }
      _lastVisitDate = now;
    }
  }

  Future<void> registerRelapse() async {
    final now = DateTime.now();
    _relapses.add(now);
    _streakStartTime = now;
    _streakDays = 0; // Reset streak
    await _save();
    notifyListeners();
  }

  Future<void> addSite(String url) async {
    final clean = url.trim().toLowerCase().replaceAll(RegExp(r'^https?://'), '');
    if (!_blockedSites.contains(clean)) {
      _blockedSites.add(clean);
      await _save();
      await ProtectionService.syncBlocklist(_blockedSites); // Sync to native
      notifyListeners();
    }
  }

  Future<void> setPin(String pin) async {
    _pin = pin;
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

  /// Starts the VPN and refreshes the running state.
  /// DISABLED - VPN causes internet breakage. Using Accessibility Service instead.
  Future<void> startVpn() async {
    debugPrint("AppProvider: ⚠️ VPN disabled - Using Accessibility Service for protection");
    // VPN is disabled to prevent internet breakage
    // await ProtectionService.startVpn();
    // _isVpnRunning = await ProtectionService.isVpnRunning();
    notifyListeners();
  }

  /// Opens device accessibility settings for the user to enable the service.
  Future<void> openAccessibilitySettings() async {
    await ProtectionService.openAccessibilitySettings();
  }

  /// Opens device Private DNS settings for the user.
  Future<void> openPrivateDnsSettings() async {
    await ProtectionService.openPrivateDnsSettings();
  }

  /// Refreshes VPN + accessibility status (call after returning from settings).
  Future<void> refreshProtectionStatus() async {
    // _isVpnRunning = await ProtectionService.isVpnRunning(); // Disabled to simplify
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
    await prefs.setStringList('dns', _dnsList);
    await prefs.setBool('onboarding_completed', _hasCompletedOnboarding);
    if (_streakStartTime != null) {
      await prefs.setString('streakStartTime', _streakStartTime!.toIso8601String());
    }
    if (_pin != null) await prefs.setString('pin', _pin!);
    if (_lastVisitDate != null) {
      await prefs.setString('lastVisit', _lastVisitDate!.toIso8601String());
    }
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
    // AdGuard DNS - Standard
    '94.140.14.14',
    '94.140.15.15',
    // Cloudflare - Standard
    '1.1.1.1',
    '1.0.0.1',
    // Quad9
    '9.9.9.9',
    '149.112.112.112',
    // OpenDNS
    '208.67.222.222',
    '208.67.220.220',
  ];
}
