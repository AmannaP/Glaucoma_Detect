import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

class PrescriptionsListScreen extends StatefulWidget {
  const PrescriptionsListScreen({super.key});

  @override
  State<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends State<PrescriptionsListScreen> {
  List<dynamic> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('patient_prescriptions');
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
        title: const Text("My Prescriptions"),
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
          Icon(Icons.description_outlined, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 20),
          const Text(
            "No prescriptions found",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          const SizedBox(height: 10),
          const Text(
            "Your doctor will send them here after consultation.",
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
            color: primaryGreen.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.picture_as_pdf, color: primaryGreen),
        ),
        title: Text(
          diagnosis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Issued on $date",
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_for_offline, color: primaryGreen),
          onPressed: () async {
            if (filePath.isNotEmpty && await File(filePath).exists()) {
              await OpenFile.open(filePath);
            } else {
              // PDF is missing (possibly received via cross-device sync)
              // Let's generate it now!
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Generating PDF document..."))
              );
              await _generatePdfOnDemand(item);
            }
          },
        ),
      ),
    );
  }

  Future<void> _generatePdfOnDemand(Map<String, dynamic> item) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Glaucoma Detect - Medical Prescription", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Patient: Prescription History", style: const pw.TextStyle(fontSize: 18)),
              pw.Text("Doctor: ${item['doctorName'] ?? 'Specialist'}", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Date: ${item['date']}", style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Diagnosis:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(item['diagnosis'] ?? "", style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Medication:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(item['medication'] ?? "Consult doctor", style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Instructions:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(item['instructions'] ?? "None", style: const pw.TextStyle(fontSize: 14)),
              pw.Spacer(),
              pw.Divider(),
              pw.Text("Electronically signed", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final String fileName = "prescription_${item['diagnosis'].toString().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // Update the filePath in shared prefs so we don't have to generate it again
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('patient_prescriptions');
      if (data != null) {
        List<dynamic> list = json.decode(data);
        for (var p in list) {
          if (p['date'] == item['date'] && p['diagnosis'] == item['diagnosis']) {
            p['filePath'] = file.path;
          }
        }
        await prefs.setString('patient_prescriptions', json.encode(list));
      }

      await OpenFile.open(file.path);
      _loadPrescriptions(); // Refresh UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF generation failed: $e")));
      }
    }
  }
}
