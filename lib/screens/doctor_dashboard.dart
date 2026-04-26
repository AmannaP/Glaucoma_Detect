import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'messages.dart';
import 'prescription_form.dart';
import 'video_call.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _doctorName = "Doctor";

  @override
  void initState() {
    super.initState();
    _fetchDoctorData();
    _fetchAppointments();
  }

  Future<void> _fetchDoctorData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _doctorName = prefs.getString('user_name') ?? "Doctor";
    });
  }

  Future<void> _fetchAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final doctorId = prefs.getInt('user_id');
    final doctorName = prefs.getString('user_name') ?? "Doctor";
    
    if (doctorId == null) return;

    try {
      final url = Uri.parse(
          'http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/appointments.php?action=doctor_dashboard&doctor_name=${Uri.encodeComponent(doctorName)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _appointments = data['appointments'] ?? [];
            _isLoading = false;
          });
        } else {
           setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Doctor Portal"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome, $_doctorName",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                "Here are your appointments for today.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: primaryGreen))
                  : _appointments.isEmpty 
                    ? const Center(child: Text("No appointments today", style: TextStyle(color: Colors.white30)))
                    : ListView.builder(
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final appt = _appointments[index];
                          return _buildAppointmentCard(appt);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    const primaryGreen = Color(0xFF00C853);
    final patientName = appt['patient_name'] ?? "Unknown Patient";
    final patientEmail = appt['patient_email'] ?? "";
    final time = appt['time'] ?? "";
    final date = appt['date'] ?? "";

    return Card(
      color: const Color(0xFF131C24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: primaryGreen.withOpacity(0.1),
                child: const Icon(Icons.person, color: primaryGreen),
              ),
              title: Text(patientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text("$date at $time", style: const TextStyle(color: Colors.white54)),
            ),
            const Divider(color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.chat_bubble_outline, "Chat", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen(doctorName: patientName)));
                }),
                _buildActionButton(Icons.medical_services_outlined, "Prescribe", () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrescriptionFormScreen(
                      patientName: patientName,
                      patientEmail: patientEmail,
                    ),
                  ));
                }),
                _buildActionButton(Icons.videocam_outlined, "Video Call", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VideoCallScreen(remoteName: patientName)));
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00C853), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
