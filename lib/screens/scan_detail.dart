import 'package:flutter/material.dart';
import 'dart:io';

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scanData;

  const ScanDetailScreen({super.key, required this.scanData});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    final isGlaucoma = scanData['has_glaucoma'] == true;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Scan Analysis"),
        backgroundColor: Colors.black,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF131C24),
              ),
              child: scanData['image_path'] != null && File(scanData['image_path']).existsSync()
                  ? Image.file(File(scanData['image_path']), fit: BoxFit.cover)
                  : const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGlaucoma ? "Glaucoma Detected" : "Healthy Eye",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isGlaucoma ? Colors.redAccent : Colors.green[700],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isGlaucoma ? Colors.red : Colors.green).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          scanData['date'] ?? 'No Date',
                          style: TextStyle(
                            color: isGlaucoma ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    "Analysis Report",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow("Diagnosis", isGlaucoma ? "Positive" : "Negative"),
                  _buildDetailRow("Type", scanData['glaucoma_type'] ?? "N/A"),
                  _buildDetailRow("Risk Score", isGlaucoma ? "High" : "Low"),
                  
                  const SizedBox(height: 30),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryGreen.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryGreen),
                            SizedBox(width: 10),
                            Text(
                              "What's next?",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isGlaucoma 
                            ? "We highly recommend scheduling a clinical examination with one of our top specialists immediately for a comprehensive check-up."
                            : "Your scan results appear normal. However, regular check-ups every 1-2 years are recommended for early detection of any changes.",
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  
                  if (isGlaucoma)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to Doctors tab
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Book a Consultation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
