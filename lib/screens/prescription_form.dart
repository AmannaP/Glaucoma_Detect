import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PrescriptionFormScreen extends StatefulWidget {
  final String patientName;
  final String patientEmail;

  const PrescriptionFormScreen({
    super.key, 
    required this.patientName, 
    required this.patientEmail
  });

  @override
  State<PrescriptionFormScreen> createState() => _PrescriptionFormScreenState();
}

class _PrescriptionFormScreenState extends State<PrescriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  bool _isApproved = false;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Digital Prescription"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 30),
              _buildPatientInfoSection(),
              const SizedBox(height: 30),
              _buildFormFields(),
              const SizedBox(height: 30),
              _buildApprovalSection(),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF131C24),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_services_outlined, color: Color(0xFF00C853), size: 40),
          SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("OFFICIAL PRESCRIPTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Glaucoma Detect Network", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PATIENT DETAILS", style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 10),
        Text("Name: ${widget.patientName}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Email: ${widget.patientEmail}", style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField("Diagnosis", _diagnosisController, "e.g. Primary Open Angle Glaucoma", maxLines: 2),
        const SizedBox(height: 20),
        _buildTextField("Medication & Dosage", _medicationController, "e.g. Latanoprost - 1 drop daily in each eye", maxLines: 3),
        const SizedBox(height: 20),
        _buildTextField("Special Instructions", _instructionsController, "e.g. Apply before bedtime", maxLines: 2),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF131C24),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (value) => value == null || value.isEmpty ? "Required" : null,
        ),
      ],
    );
  }

  Widget _buildApprovalSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _isApproved ? const Color(0xFF00C853).withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _isApproved ? const Color(0xFF00C853).withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _isApproved,
            activeColor: const Color(0xFF00C853),
            onChanged: (val) => setState(() => _isApproved = val ?? false),
          ),
          const Expanded(
            child: Text(
              "I hereby certify this prescription and approve it with my digital signature.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _submitPrescription,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C853),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("GENERATE & SEND PDF", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please approve the prescription first.")));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generating PDF...")));

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Glaucoma Detect - Medical Prescription", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Patient: ${widget.patientName}", style: const pw.TextStyle(fontSize: 18)),
              pw.Text("Email: ${widget.patientEmail}", style: const pw.TextStyle(fontSize: 14)),
              pw.Text("Date: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 14)),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Diagnosis:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(_diagnosisController.text, style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Medication & Dosage:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(_medicationController.text, style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Additional Notes:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(_instructionsController.text.isNotEmpty ? _instructionsController.text : "None", style: const pw.TextStyle(fontSize: 14)),
              pw.Spacer(),
              pw.Divider(),
              pw.Text("Electronically signed", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final String fileName = "prescription_${widget.patientName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      // Also save to shared prefs for history view
      final prefs = await SharedPreferences.getInstance();
      final List<String> currentPrescriptions = prefs.getStringList('prescriptions') ?? [];
      currentPrescriptions.add("${DateTime.now().toString().split(' ')[0]} - ${_diagnosisController.text}");
      await prefs.setStringList('prescriptions', currentPrescriptions);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Prescription PDF Generated & Saved!"), backgroundColor: Color(0xFF00C853)),
        );
        Navigator.pop(context);
      }

      // Try to open the generated PDF
      await OpenFile.open(file.path);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating PDF: $e"), backgroundColor: Colors.red));
      }
    }
  }
}
