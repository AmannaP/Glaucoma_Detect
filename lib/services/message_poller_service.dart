import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class MessagePollerService {
  MessagePollerService._internal();
  static final MessagePollerService _instance = MessagePollerService._internal();
  factory MessagePollerService() => _instance;

  Timer? _poller;
  final Set<int> _seenMessageIds = {};
  bool _isPolling = false;

  final List<String> _doctors = [
    "Dr. Alice Green",
    "Dr. Bob White",
    "Dr. Clara Reed",
  ];

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    
    // Poll every 10 seconds (less aggressive than chat screen)
    _poller = Timer.periodic(const Duration(seconds: 10), (_) {
       _checkNewMessages();
       _checkNewAppointments();
    });
    _checkNewMessages(); 
    _checkNewAppointments();
  }

  void stopPolling() {
    _poller?.cancel();
    _isPolling = false;
  }

  final Set<int> _seenAppointmentIds = {};

  Future<void> _checkNewAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final String role = prefs.getString('user_role') ?? 'patient';
    if (role != 'doctor') return;

    final String doctorName = prefs.getString('user_name') ?? "";
    if (doctorName.isEmpty) return;

    try {
      final url = Uri.parse(
        'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/appointments.php?action=doctor_dashboard&doctor_name=${Uri.encodeComponent(doctorName)}'
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> appointments = data['appointments'] ?? [];
          if (appointments.isEmpty) return;

          for (var appt in appointments) {
            final int apptId = int.tryParse(appt['id'].toString()) ?? 0;
            if (!_seenAppointmentIds.contains(apptId)) {
              if (_seenAppointmentIds.isNotEmpty) {
                // Notify doctor of new appointment
                NotificationService().showInfoNotification(
                  title: "🗓️ New Consultation Scheduled",
                  body: "Patient ${appt['patient_name']} has booked an appointment for ${appt['date']} at ${appt['time']}.",
                );
              }
              _seenAppointmentIds.add(apptId);
            }
          }
        }
      }
    } catch (e) {
      // Background fail
    }
  }

  Future<void> _checkNewMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    if (userId == null) return;

    for (final doctorName in _doctors) {
      try {
        final url = Uri.parse(
          'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=fetch&user_id=$userId&other_name=${Uri.encodeComponent(doctorName)}'
        );
        final response = await http.get(url);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            final List<dynamic> messages = data['messages'] ?? [];
            if (messages.isEmpty) continue;

            final latestMsg = messages.last;
            final int msgId = latestMsg['id'];
            final int senderId = latestMsg['sender_id'];

            // Only notify if:
            // 1. It's from the other person
            // 2. We haven't seen this ID in this session
            // 3. This isn't the first time we're seeing ANY messages (avoid notification flood on startup)
            if (senderId != userId && !_seenMessageIds.contains(msgId)) {
              if (_seenMessageIds.isNotEmpty) {
                NotificationService().showMessageNotification(
                  senderName: doctorName,
                  messagePreview: latestMsg['message'] ?? "New message",
                );
              }
              _seenMessageIds.add(msgId);
            }
            
            // Populate seen IDs on first run
            for (var m in messages) {
               _seenMessageIds.add(m['id']);
            }
          }
        }
      } catch (e) {
        // Silently fail for background polling
      }
    }
  }
}
