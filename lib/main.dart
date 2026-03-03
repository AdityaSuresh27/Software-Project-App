///**
/// ClassFlow - Academic Student Planner Application
/// 
/// A comprehensive academic management system designed to help students 
/// efficiently organize, track, and manage their coursework, events, 
/// schedules, and attendance.
/// 
/// Key Features:
/// - Unified event management (classes, exams, assignments, deadlines, etc.)
/// - Weekly course timetable with auto-generated calendar events
/// - Visual calendar and hour-by-hour timeline views
/// - Attendance tracking and risk prediction with 75% threshold alerts
/// - Gamification elements (achievements, streaks, notifications)
/// - Voice notes and attachment support for events
/// - Dark/Light theme support
/// - Customizable priorities, categories, and reminders
/// - Notification system for upcoming events and deadlines
/// 
/// Architecture:
/// - Frontend: Flutter widgets with Material Design 3
/// - State Management: Provider pattern for reactive UI updates
/// - Data Persistence: SharedPreferences for local storage
/// - Backend: DataProvider service for all data operations
/// - Authentication: Email/password with OTP verification
/// 
/// Main Entry Points:
/// - Splash Screen: Animated app intro with data loading
/// - Auth Screen: User login/signup with avatar customization
/// - Main Navigation: Bottom navigation connecting 5 primary screens
///   1. Home: Dashboard with today's overview
///   2. Calendar: Monthly calendar view
///   3. Timeline: Hour-by-hour schedule
///   4. Events: Complete event list with filtering
///   5. Profile: User settings and preferences

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'frontend/splash_screen.dart';
import 'frontend/theme.dart';
import 'frontend/theme_provider.dart';
import 'frontend/font_provider.dart';
import 'backend/data_provider.dart';
import 'backend/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().initialize();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const ClassFlowApp(),
    ),
  );
}

/// Global navigator key for notification deep linking without BuildContext
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// ClassFlowApp - Root widget for the entire application
/// 
/// Configures theme, routing, and Material 3 design system.
/// Responds to theme mode changes from ThemeProvider.

class ClassFlowApp extends StatelessWidget {
  const ClassFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, FontProvider>(
      builder: (context, themeProvider, fontProvider, child) {
        // Select theme based on font choice
        late ThemeData lightTheme;
        late ThemeData darkTheme;
        
        if (fontProvider.isMinimalistic) {
          // Poppins - Minimalistic
          lightTheme = AppTheme.minimalisticLightTheme;
          darkTheme = AppTheme.minimalisticDarkTheme;
        } else {
          // Inter - Original/Modern
          lightTheme = AppTheme.lightTheme;
          darkTheme = AppTheme.darkTheme;
        }
        
        return MaterialApp(
          title: 'ClassFlow',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          navigatorKey: navigatorKey,
        );
      },
    );
  }
}