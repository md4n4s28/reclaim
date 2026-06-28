import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_provider.dart';
import 'core/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/panic/panic_screen.dart';
import 'features/block/block_screen.dart';
import 'features/progress/progress_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/advanced_protection_screen.dart';
import 'features/journal/journal_screen.dart';
import 'features/breathing/breathing_screen.dart';
import 'features/block/app_blocker_screen.dart';
import 'core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..load()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ReclaimApp(),
    ),
  );
}

class ReclaimApp extends StatelessWidget {
  const ReclaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Reclaim',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          initialRoute: '/',
          routes: {
            '/': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/panic': (_) => const PanicScreen(),
            '/block': (_) => const BlockScreen(),
            '/progress': (_) => const ProgressScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/advanced_protection': (_) => const AdvancedProtectionScreen(),
            '/journal': (_) => const JournalScreen(),
            '/breathing': (_) => const BreathingScreen(),
            '/app_blocker': (_) => const AppBlockerScreen(),
          },
        );
      },
    );
  }
}
