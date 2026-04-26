import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'messages.dart';
import '../services/notification_service.dart';
import 'prescription_form.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _doctorName = "Dr. Alice Green"; // Mock doctor name

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      // In a real app, we'd get the current doctor's name from login/prefs
      final response = await http.get(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/appointments.php?doctor_name=$_doctorName&date=${DateTime.now().toIso8601String().split('T')[0]}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Note: The backend returns busy_slots (times), not full appointment objects in this GET call
          // For the dashboard, we'd ideally have a better backend endpoint.
          // Let's simulate appointment objects for the UI demo.
          setState(() {
            _appointments = [
              {
                "id": 1,
                "patient_name": "John Doe",
                "patient_email": "john.doe@example.com",
                "time": "09:00 AM",
                "status": "pending",
                "reason": "Routine Checkup"
              },
              {
                "id": 2,
                "patient_name": "Jane Smith",
                "patient_email": "jane.smith@example.com",
                "time": "11:00 AM",
                "status": "pending",
                "reason": "Glaucoma Follow-up"
              }
            ];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAppointments,
          ),
        ],
      ),
      body: Padding(
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
                        return Card(
                          color: const Color(0xFF131C24),
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appt['patient_name'],
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(appt['reason'], style: const TextStyle(color: Colors.white54)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: primaryGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        appt['time'],
                                        style: const TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: Colors.white10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen(doctorName: appt['patient_name'])));
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                        label: const Text("Chat", style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.blueAccent, padding: EdgeInsets.zero),
                                      ),
                                    ),
                                    Flexible(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => PrescriptionFormScreen(
                                              patientName: appt['patient_name'],
                                              patientEmail: appt['patient_email'] ?? 'patient@example.com',
                                            )
                                          ));
                                        },
                                        icon: const Icon(Icons.medication_outlined, size: 16),
                                        label: const Text("Prescribe", style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.amberAccent, padding: EdgeInsets.zero),
                                      ),
                                    ),
                                    Flexible(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment marked as completed")));
                                        },
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: const Text("Complete", style: TextStyle(fontSize: 12)),
                                        style: TextButton.styleFrom(foregroundColor: primaryGreen, padding: EdgeInsets.zero),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

}
