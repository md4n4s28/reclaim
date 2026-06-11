import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final List<String> _motivationalQuotes = [
    "Every minute you resist, you're rewiring your brain. Keep going!",
    "You are stronger than a 5-second urge.",
    "Don't trade your long-term goals for short-term gratification.",
    "A clean day today is a massive victory for tomorrow.",
    "Breathe. You have the power to choose your path.",
    "Remember why you started. Don't give up now.",
    "Your future self is thanking you for the choices you make today."
  ];

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Using basic initialization for simple local notifications
    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap here if needed
      },
    );

    // Request permissions for Android 13+
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showDailyMotivation() async {
    final random = Random();
    final quote = _motivationalQuotes[random.nextInt(_motivationalQuotes.length)];

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_motivation_channel',
      'Daily Motivation',
      channelDescription: 'Daily reminders to stay strong and focused.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      id: 0,
      title: 'Reclaim Your Focus 🛡️',
      body: quote,
      notificationDetails: platformDetails,
    );
  }

  // Set up periodic background motivation (for demo purposes, we will trigger manually or show one daily)
}
