import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notes = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = notes;
        _isLoading = false;
      });
      NotificationService.markAllAsRead();
    }
  }

  String _formatTime(String isoTime) {
    final dateTime = DateTime.parse(isoTime);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return "Just now";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await NotificationService.clearNotifications();
              _loadNotifications();
            },
          )
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 60, color: Colors.white24),
                        SizedBox(height: 16),
                        Text("No notifications yet", style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final note = _notifications[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: _getIconColor(note['type']!).withOpacity(0.1),
                          child: Icon(_getIcon(note['type']!), color: _getIconColor(note['type']!)),
                        ),
                        title: Text(
                          note['title']!,
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: note['isRead'] == true ? FontWeight.normal : FontWeight.bold
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(note['body']!, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(_formatTime(note['time']!), style: const TextStyle(color: Colors.white30, fontSize: 12)),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'alert': return Icons.warning_amber_rounded;
      case 'reminder': return Icons.event_note;
      default: return Icons.notifications_none;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'alert': return Colors.redAccent;
      case 'reminder': return Colors.blueAccent;
      default: return const Color(0xFF00C853);
    }
  }
}
