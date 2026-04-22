import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    
    // Mock notifications for now
    final List<Map<String, String>> notifications = [
      {
        "title": "Welcome to Glaucoma Detect!",
        "body": "Start your journey to better eye health today.",
        "time": "Just now",
        "type": "info"
      },
      {
        "title": "New Scan Result available",
        "body": "Your recent eye scan analysis is complete. View it now in History.",
        "time": "2 hours ago",
        "type": "alert"
      },
      {
        "title": "Appointment Reminder",
        "body": "You have an appointment with Dr. Alice Green tomorrow at 10:00 AM.",
        "time": "Yesterday",
        "type": "reminder"
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text("No notifications yet", style: TextStyle(color: Colors.white70)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final note = notifications[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _getIconColor(note['type']!).withOpacity(0.1),
                    child: Icon(_getIcon(note['type']!), color: _getIconColor(note['type']!)),
                  ),
                  title: Text(
                    note['title']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(note['body']!, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(note['time']!, style: const TextStyle(color: Colors.white30, fontSize: 12)),
                    ],
                  ),
                );
              },
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
