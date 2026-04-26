import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';
import 'navigation_service.dart';
import '../screens/video_call.dart';

class MessagePollerService {
  MessagePollerService._internal();
  static final MessagePollerService _instance = MessagePollerService._internal();
  factory MessagePollerService() => _instance;

  Timer? _poller;
  final Set<int> _seenMessageIds = {};
  bool _isPolling = false;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    
    // Poll every 10 seconds
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
          for (var appt in appointments) {
            final int apptId = int.tryParse(appt['id'].toString()) ?? 0;
            if (!_seenAppointmentIds.contains(apptId)) {
              if (_seenAppointmentIds.isNotEmpty) {
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
    } catch (e) { /* background fail */ }
  }

  Future<void> _checkNewMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    final String userName = prefs.getString('user_name') ?? "";
    if (userId == null) return;

    // Fetch all specialists to check chats from
    List<String> chatPartners = [];
    try {
      final docResp = await http.get(Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=fetch_doctors'));
      if (docResp.statusCode == 200) {
        final docData = json.decode(docResp.body);
        if (docData['status'] == 'success') {
          for (var d in docData['doctors']) {
            if (d['name'] != userName) chatPartners.add(d['name']);
          }
        }
      }
    } catch (e) { /* fallback to recent chats logic or empty */ }

    // If I'm a doctor, I also need to check messages from patients I've interacted with.
    // For simplicity in this signaling demo, we poll all known doctors.
    
    for (final partnerName in chatPartners) {
      try {
        final url = Uri.parse(
          'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/messages.php?action=fetch&user_id=$userId&other_name=${Uri.encodeComponent(partnerName)}'
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
            final String content = latestMsg['message'] ?? "";

            if (senderId != userId && !_seenMessageIds.contains(msgId)) {
              if (_seenMessageIds.isNotEmpty) {
                // 1. CHECK FOR CALL SIGNAL
                if (content.startsWith("[CALL_REQUEST]")) {
                  _triggerIncomingCall(partnerName);
                } 
                // 2. CHECK FOR PRESCRIPTION SIGNAL
                else if (content.startsWith("[PRESCRIPTION_DATA]")) {
                  _handleIncomingPrescription(content, partnerName);
                }
                // 3. CHECK FOR REGULAR MESSAGE
                else if (!content.startsWith("[CALL_")) {
                  NotificationService().showMessageNotification(
                    senderName: partnerName,
                    messagePreview: content,
                  );
                }
              }
              _seenMessageIds.add(msgId);
            }
            
            for (var m in messages) _seenMessageIds.add(m['id']);
          }
        }
      } catch (e) { /* silently fail */ }
    }
  }

  Future<void> _handleIncomingPrescription(String content, String doctorName) async {
    try {
      final jsonStr = content.replaceFirst("[PRESCRIPTION_DATA]", "");
      final Map<String, dynamic> data = json.decode(jsonStr);
      
      // Generate the PDF locally on the patient's device
      // We need to import the same PDF logic here or move it to a service
      // For now, let's just save the metadata to history. 
      // The actual PDF generation can happen when they click 'Download' in PrescriptionsListScreen if missing.
      
      final prefs = await SharedPreferences.getInstance();
      final String? existingData = prefs.getString('patient_prescriptions');
      List<dynamic> prescriptions = existingData != null ? json.decode(existingData) : [];
      
      // Check if this prescription is already saved (by date and diagnosis)
      bool exists = prescriptions.any((p) => p['date'] == data['date'] && p['diagnosis'] == data['diagnosis']);
      
      if (!exists) {
        prescriptions.insert(0, {
          "date": data['date'],
          "diagnosis": data['diagnosis'],
          "medication": data['medication'],
          "instructions": data['instructions'],
          "doctorName": doctorName,
          "filePath": "", // Will be generated on demand or we can generate it now
        });
        await prefs.setString('patient_prescriptions', json.encode(prescriptions));
        
        NotificationService().showInfoNotification(
          title: "📄 New Prescription Received",
          body: "Doctor $doctorName has sent a prescription for ${data['diagnosis']}.",
        );
      }
    } catch (e) {
      debugPrint("Error handling prescription: $e");
    }
  }

  void _triggerIncomingCall(String remoteName) {
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            remoteName: remoteName,
            isIncoming: true,
          ),
        ),
      );
    }
  }
}
