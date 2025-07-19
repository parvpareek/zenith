import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../database/database_helper.dart';
import '../services/audio_service.dart';
import '../services/preferences_service.dart';
import '../views/app_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize database factory for different platforms
      if (kIsWeb) {
        databaseFactory = databaseFactoryFfiWeb;
      } else {
        if (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      }
      
      // Initialize database
      await DatabaseHelper().database;
      
      // Initialize preferences service
      await PreferencesService.instance.initialize();

      // Initialize audio service
      await AudioService.instance.initialize();
      await AudioService.instance.scheduleDailyJournalReminder();
      
      // Add a minimum delay for splash screen visibility
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Navigate to main app
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppShell()),
        );
      }
    } catch (e) {
      print('Initialization error: $e');
      // Still navigate to app even if there's an error
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppShell()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/icon/splash_logo.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 32),
            
            // App Name
            const Text(
              'Zenith',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            
            // Tagline
            const Text(
              'Plan • Act • Reflect',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 56),
            
            // Loading indicator
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 