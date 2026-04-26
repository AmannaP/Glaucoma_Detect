import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:open_file/open_file.dart';

class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() => _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends State<DoctorPrescriptionsScreen> {
  List<dynamic> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('doctor_prescriptions');
    if (data != null) {
      setState(() {
        _prescriptions = json.decode(data);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Issued Prescriptions"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: primaryGreen))
            : _prescriptions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final item = _prescriptions[index];
                      return _buildPrescriptionCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 20),
          const Text(
            "No prescriptions issued yet",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            "Records will appear here after you prescribe to a patient.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> item) {
    const primaryGreen = Color(0xFF00C853);
    final String date = item['date'] ?? "";
    final String diagnosis = item['diagnosis'] ?? "General Checkup";
    final String patientName = item['patientName'] ?? "Unknown Patient";
    final String filePath = item['filePath'] ?? "";

    return Card(
      color: const Color(0xFF131C24),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.blue),
        ),
        title: Text(
          patientName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diagnosis,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            Text(
              "Issued on $date",
              style: const TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, color: primaryGreen),
          onPressed: () async {
            if (filePath.isNotEmpty && await File(filePath).exists()) {
              await OpenFile.open(filePath);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("PDF file not found on this device."))
              );
            }
          },
        ),
      ),
    );
  }
}
