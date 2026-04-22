import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentHistoryScreen extends StatefulWidget {
  const AppointmentHistoryScreen({super.key});

  @override
  State<AppointmentHistoryScreen> createState() => _AppointmentHistoryScreenState();
}

class _AppointmentHistoryScreenState extends State<AppointmentHistoryScreen> {
  List<dynamic> upcomingAppointments = [];
  List<dynamic> pastAppointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception("User not logged in");
      }

      final response = await http.get(
        Uri.parse('http://169.239.251.102:280/~chika.amanna/glaucoma_backend/appointments.php?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> allAppointments = data['appointments'];
          final now = DateTime.now();
          
          setState(() {
            upcomingAppointments = allAppointments.where((app) {
              DateTime appDate = DateTime.parse(app['date']);
              return appDate.isAfter(now) || appDate.isAtSameMomentAs(DateTime(now.year, now.month, now.day));
            }).toList();

            pastAppointments = allAppointments.where((app) {
              DateTime appDate = DateTime.parse(app['date']);
              return appDate.isBefore(DateTime(now.year, now.month, now.day));
            }).toList();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("My Appointments"),
          backgroundColor: Colors.black,
          foregroundColor: primaryGreen,
          bottom: const TabBar(
            indicatorColor: primaryGreen,
            labelColor: primaryGreen,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: isLoading 
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : TabBarView(
              children: [
                _buildAppointmentList(upcomingAppointments, isUpcoming: true),
                _buildAppointmentList(pastAppointments, isUpcoming: false),
              ],
            ),
      ),
    );
  }

  Widget _buildAppointmentList(List<dynamic> appointments, {required bool isUpcoming}) {
    if (appointments.isEmpty) {
      return Center(
        child: Text(
          isUpcoming ? "No upcoming appointments" : "No past appointments",
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final app = appointments[index];
        return Card(
          color: const Color(0xFF131C24),
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isUpcoming ? Colors.green : Colors.grey).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUpcoming ? Icons.calendar_today : Icons.history,
                    color: isUpcoming ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['doctor_name'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        app['specialty'],
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            "${app['date']} at ${app['time']}",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isUpcoming)
                  const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }
}
