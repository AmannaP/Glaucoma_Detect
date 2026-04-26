import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _storageKey = 'persistent_notifications';

  static Future<void> addNotification({
    required String title,
    required String body,
    required String type, // 'info', 'alert', 'reminder'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_storageKey);
    List<dynamic> notifications = existingData != null ? json.decode(existingData) : [];

    final newNotification = {
      "title": title,
      "body": body,
      "time": DateTime.now().toIso8601String(),
      "type": type,
      "isRead": false,
    };

    notifications.insert(0, newNotification); // Add to top
    await prefs.setString(_storageKey, json.encode(notifications));
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingData = prefs.getString(_storageKey);
    if (existingData == null) return [];
    
    List<dynamic> decoded = json.decode(existingData);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
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
  }
}
