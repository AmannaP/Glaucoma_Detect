import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../screens/messages.dart';
import 'navigation_service.dart';

/// Singleton notification service.
/// Handles:
///  - Immediate notifications (messages, info)
///  - Scheduled notifications (consultation reminders: -10min, start, end)
///  - In-app notification history via SharedPreferences
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const String _storageKey = 'persistent_notifications';
  
  // Real-time unread count
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  // Notification IDs  (use fixed IDs per type to avoid duplication)
  static const int _messageChannelId = 1000;
  static const int _reminderBaseId   = 2000; // +0 = created, +1 = 10min, +2 = start, +3 = end

  // Android channels
  static const AndroidNotificationChannel _msgChannel = AndroidNotificationChannel(
    'glaucoma_messages',
    'Message Alerts',
    description: 'New messages from doctors or patients',
    importance: Importance.high,
  );
  static const AndroidNotificationChannel _consultChannel = AndroidNotificationChannel(
    'glaucoma_consult',
    'Consultation Reminders',
    description: 'Reminders for upcoming consultations',
    importance: Importance.max,
  );

  /// Must be called once in main() before runApp.
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint("Could not set local timezone: $e");
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (response.payload != null) {
          final data = json.decode(response.payload!);
          if (data['type'] == 'chat' && data['doctorName'] != null) {
            NavigationService.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (_) => MessagesScreen(doctorName: data['doctorName']),
              ),
            );
          }
        }
      },
    );

    // Create the notification channels on Android
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_msgChannel);
    await androidPlugin?.createNotificationChannel(_consultChannel);

    // Request permission (Android 13+)
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // Initialize the notifier with current count
    unreadCountNotifier.value = await getUnreadCount();
  }

  // ─────────────────────────────────────────────────────────
  // Immediate Notifications
  // ─────────────────────────────────────────────────────────

  /// Show a new message notification (when user is NOT in the chat screen).
  Future<void> showMessageNotification({
    required String senderName,
    required String messagePreview,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'glaucoma_messages',
        'Message Alerts',
        channelDescription: 'New messages from doctors or patients',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(
      id: _messageChannelId,
      title: '💬 New message from $senderName',
      body: messagePreview,
      notificationDetails: details,
      payload: json.encode({
        "type": "chat",
        "doctorName": senderName,
      }),
    );
    await _addToHistory(
      title: 'New message from $senderName',
      body: messagePreview,
      type: 'message',
    );
  }

  /// Show an immediate info notification.
  Future<void> showInfoNotification({
    required String title,
    required String body,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'glaucoma_consult',
        'Consultation Reminders',
        channelDescription: 'Reminders for upcoming consultations',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.show(id: _messageChannelId + 1, title: title, body: body, notificationDetails: details);
    await _addToHistory(title: title, body: body, type: 'info');
  }

  // ─────────────────────────────────────────────────────────
  // Scheduled Notifications (Appointment Reminders)
  // ─────────────────────────────────────────────────────────

  /// Schedule all four consultation reminders for an appointment.
  /// [appointmentId] is used to generate unique notification IDs.
  /// [appointmentDateTime] must be the exact local DateTime of the appointment.
  /// [doctorOrPatientName] is the name of the other party.
  Future<void> scheduleConsultationReminders({
    required int appointmentId,
    required DateTime appointmentDateTime,
    required String doctorOrPatientName,
  }) async {
    final tz.TZDateTime apptTz = tz.TZDateTime.from(appointmentDateTime, tz.local);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 1. Immediately: Appointment Created
    await showInfoNotification(
      title: '📅 Appointment Confirmed',
      body: 'Your consultation with $doctorOrPatientName has been booked on '
            '${appointmentDateTime.day}/${appointmentDateTime.month}/${appointmentDateTime.year} '
            'at ${_formatHour(appointmentDateTime)}.',
    );

    // 2. 10 Minutes Before
    final tenMinBefore = apptTz.subtract(const Duration(minutes: 10));
    if (tenMinBefore.isAfter(now)) {
      await _scheduleNotification(
        id: _reminderBaseId + (appointmentId * 10) + 1,
        title: '⏰ Consultation in 10 minutes!',
        body: 'Your video call with $doctorOrPatientName starts soon. Get ready!',
        scheduledTime: tenMinBefore,
      );
    }

    // 3. At Appointment Start
    if (apptTz.isAfter(now)) {
      await _scheduleNotification(
        id: _reminderBaseId + (appointmentId * 10) + 2,
        title: '🎥 Consultation Starting Now',
        body: 'Your consultation with $doctorOrPatientName is starting. Tap to join.',
        scheduledTime: apptTz,
      );
    }

    // 4. Appointment End (assume 30-minute consultations)
    final endTime = apptTz.add(const Duration(minutes: 30));
    if (endTime.isAfter(now)) {
      await _scheduleNotification(
        id: _reminderBaseId + (appointmentId * 10) + 3,
        title: '✅ Consultation Ending',
        body: 'Your consultation with $doctorOrPatientName is ending. Please verify completion.',
        scheduledTime: endTime,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'glaucoma_consult',
        'Consultation Reminders',
        channelDescription: 'Reminders for upcoming consultations',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancel all scheduled reminders for a given appointment.
  Future<void> cancelConsultationReminders(int appointmentId) async {
    for (int i = 1; i <= 3; i++) {
      await _plugin.cancel(id: _reminderBaseId + (appointmentId * 10) + i);
    }
  }

  // ─────────────────────────────────────────────────────────
  // In-App Notification History (SharedPreferences)
  // ─────────────────────────────────────────────────────────

  Future<void> _addToHistory({
    required String title,
    required String body,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_storageKey);
    List<dynamic> notifications = existingData != null ? json.decode(existingData) : [];
    notifications.insert(0, {
      "title": title,
      "body": body,
      "time": DateTime.now().toIso8601String(),
      "type": type,
      "isRead": false,
    });
    // Keep max 50 notifications
    if (notifications.length > 50) notifications = notifications.sublist(0, 50);
    await prefs.setString(_storageKey, json.encode(notifications));
    
    // Update live notifier
    unreadCountNotifier.value = await getUnreadCount();
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_storageKey);
    if (existingData == null) return [];
    List<dynamic> decoded = json.decode(existingData);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<int> getUnreadCount() async {
    final all = await getNotifications();
    return all.where((n) => n['isRead'] == false).length;
  }

  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_storageKey);
    if (existingData == null) return;
    List<dynamic> notifications = json.decode(existingData);
    for (var note in notifications) {
      note['isRead'] = true;
    }
    await prefs.setString(_storageKey, json.encode(notifications));
    NotificationService().unreadCountNotifier.value = 0;
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    NotificationService().unreadCountNotifier.value = 0;
  }

  // ─────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────

  String _formatHour(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  /// Shorthand used by other screens (matches old static API).
  static Future<void> addNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    await NotificationService()._addToHistory(title: title, body: body, type: type);
  }
}
