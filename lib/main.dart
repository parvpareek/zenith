import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'config/app_theme.dart';
import 'database/database_helper.dart';
import 'widgets/splash_screen.dart';

// Utility function to clear all data except tags
Future<void> clearAllDataExceptTags() async {
  final dbHelper = DatabaseHelper();
  await dbHelper.clearAllDataExceptTags();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data
  tz.initializeTimeZones();
  
  runApp(
    const ProviderScope(
      child: ZenithApp(),
    ),
  );
}

class ZenithApp extends ConsumerWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Zenith - Minimalist Productivity',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
} 