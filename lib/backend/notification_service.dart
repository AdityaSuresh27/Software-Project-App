// notification_service.dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';
import '../frontend/event_action_dialog.dart';
import '../backend/data_provider.dart';
import 'package:provider/provider.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final Map<int, Timer> _timers = {};
  bool _initialized = false;

  // Use @mipmap/ic_launcher (bitmap PNGs) instead of @drawable/ic_notification
  // (VectorDrawable XML). Many physical devices / OEM ROMs silently fail to
  // inflate vector drawables as notification small icons, causing the entire
  // notification pipeline to break without any visible error.
  static const String _icon = '@mipmap/ic_launcher';

  /// Request notification permission AND eagerly initialize the plugin.
  /// Call this once the Flutter Activity is fully attached
  /// (e.g. from a widget's initState via addPostFrameCallback).
  Future<void> requestPermission() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}

    // Eagerly initialize here — this code path is proven to execute
    // on both emulator and physical devices.
    await _ensureInitialized();
  }

  /// Initializes the plugin + timezone. Safe to call multiple times.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Falls back to UTC — acceptable.
    }

    const androidSettings = AndroidInitializationSettings(_icon);
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
    } catch (e) {
      debugPrint('NotificationService: initialize() failed: $e');
      return; // Don't mark as initialized so next call retries.
    }

    _initialized = true;

    // Pre-create channel so Android knows about it before any notification.
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'classflow_reminders',
          'Event Reminders',
          description: 'Reminders for your events and tasks',
          importance: Importance.max,
        ),
      );
    } catch (e) {
      debugPrint('NotificationService: createChannel failed: $e');
    }
  }

  void _onNotificationTap(NotificationResponse details) {
    final eventId = details.payload;
    if (eventId == null || eventId.isEmpty) return;
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    final dataProvider = Provider.of<DataProvider>(ctx, listen: false);
    try {
      final event = dataProvider.events.firstWhere((e) => e.id == eventId);
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => EventActionDialog(event: event),
      );
    } catch (_) {}
  }

  NotificationDetails _buildDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'classflow_reminders',
        'Event Reminders',
        channelDescription: 'Reminders for your events and tasks',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
        icon: _icon,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: 'classflow_events',
      ),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _ensureInitialized();
    if (!_initialized) return; // Plugin failed, can't proceed.

    final details = _buildDetails(body);

    // PRIMARY: AlarmManager-based scheduling via zonedSchedule.
    // This survives app process death — critical on physical devices where
    // the OS aggressively kills background apps (unlike the emulator).
    try {
      final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('NotificationService: zonedSchedule failed: $e');
    }

    // SECONDARY: In-app Timer as fallback for when the app IS alive.
    _timers[id]?.cancel();
    final delay = scheduledDate.difference(DateTime.now());
    _timers[id] = Timer(delay, () {
      _timers.remove(id);
      _plugin.show(id, title, body, details, payload: payload).catchError((e) {
        debugPrint('NotificationService: show() failed: $e');
      });
    });
  }

  Future<void> cancelNotification(int id) async {
    _timers[id]?.cancel();
    _timers.remove(id);
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAllNotifications() async {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}