import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  static AudioService get instance => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _initializeNotifications();
    _isInitialized = true;
  }

  Future<void> _initializeNotifications() async {
    // Request notification permissions
    await _requestNotificationPermissions();
    
    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _requestNotificationPermissions() async {
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> playTimerCompleteSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/timer_complete.wav'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> showTimerCompleteNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'timer_complete',
      'Timer Complete',
      channelDescription: 'Notifications for timer completion with sound',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      sound: RawResourceAndroidNotificationSound('timer_complete'),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'timer_complete.wav',
      interruptionLevel: InterruptionLevel.critical,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    
    // Play sound first
    await playTimerCompleteSound();
    
    // Then show notification
    await _notificationsPlugin.show(
      0,
      'Focus Session Complete!',
      'Great job! Time to reflect on your session.',
      platformChannelSpecifics,
    );
  }

  Future<void> showRunningTimerNotification(String remainingTime, String goal) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'timer_running',
      'Focus Timer',
      channelDescription: 'Ongoing focus timer notification',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      enableVibration: false,
      ongoing: true,
      autoCancel: false,
      showProgress: false,
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics = 
        DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    
    await _notificationsPlugin.show(
      2,
      'Focus Timer Running - $remainingTime',
      goal,
      platformChannelSpecifics,
    );
  }

  Future<void> cancelRunningTimerNotification() async {
    await _notificationsPlugin.cancel(2);
  }

  Future<void> scheduleDailyJournalReminder() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = 
        AndroidNotificationDetails(
      'daily_journal',
      'Daily Journal',
      channelDescription: 'Daily journal reminder at 10:00 PM',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosPlatformChannelSpecifics = 
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );
    
    // Schedule daily notification at 10:00 PM
    await _notificationsPlugin.zonedSchedule(
      1,
      'Daily Journal Reminder',
      'Take a moment to reflect on your day and journal your thoughts.',
      _nextInstanceOfTime(22, 0), // 10:00 PM
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
} 