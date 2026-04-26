import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'messages.dart';
import 'video_call.dart';
import 'prescription_form.dart';

class DoctorPortal extends StatefulWidget {
  const DoctorPortal({super.key});

  @override
  State<DoctorPortal> createState() => _DoctorPortalState();
}

class _DoctorPortalState extends State<DoctorPortal> {
  List<Map<String, dynamic>> _appointments = [
    {"patient": "Chika Amanna", "time": "10:30 AM", "date": "Today", "status": "pending"},
    {"patient": "John Doe", "time": "02:00 PM", "date": "Tomorrow", "status": "confirmed"},
  ];

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Colors.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvailabilityCard(),
          const SizedBox(height: 30),
          const Text("Upcoming Appointments", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ..._appointments.map((app) => _buildAppointmentItem(app)).toList(),
          const SizedBox(height: 30),
          const Text("Recent Chats", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildChatItem("Chika Amanna", "Doctor, I'm having eye pain..."),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Weekly Availability", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Icon(Icons.edit, color: Colors.blue, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["M", "T", "W", "T", "F", "S", "S"].map((day) => _buildDayItem(day, day != "S")).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, bool isAvailable) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isAvailable ? Colors.blue.withOpacity(0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: isAvailable ? Colors.blue : Colors.white12),
          ),
          child: Center(child: Text(day[0], style: TextStyle(color: isAvailable ? Colors.blue : Colors.white24, fontSize: 10))),
        ),
      ],
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> app) {
    return Card(
      color: const Color(0xFF131C24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(app['patient'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("${app['date']} at ${app['time']}", style: const TextStyle(color: Colors.white54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.blue),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(remoteName: app['patient'])));
              },
            ),
            IconButton(
              icon: const Icon(Icons.description, color: Colors.blue),
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => PrescriptionFormScreen(patientName: app['patient'], patientEmail: "patient@example.com")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(String name, String lastMsg) {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(lastMsg, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen(doctorName: name)));
      },
    );
  }
}
