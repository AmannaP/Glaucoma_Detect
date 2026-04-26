import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_detail.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('scan_history');
    if (historyString != null) {
      final List<dynamic> decoded = json.decode(historyString);
      setState(() {
        history = decoded.cast<Map<String, dynamic>>().reversed.toList();
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: primaryGreen)),
      );
    }

    if (history.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.white.withOpacity(0.2)),
              const SizedBox(height: 16),
              const Text(
                "No scan history yet.",
                style: TextStyle(color: Colors.white60, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          final isGlaucoma = item['has_glaucoma'] == true;
          return Card(
            color: const Color(0xFF131C24),
            elevation: 1,
            shadowColor: Colors.black.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ScanDetailScreen(scanData: item)));
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isGlaucoma ? Colors.red : Colors.green).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGlaucoma ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: isGlaucoma ? Colors.redAccent : Colors.green[700],
                  size: 28,
                ),
              ),
              title: Text(
                isGlaucoma ? 'Glaucoma Detected' : 'Healthy Eye',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
              ),
              subtitle: Text(
                isGlaucoma ? 'Type: ${item['glaucoma_type']}\nDate: ${item['date']}' : 'No defects found.\nDate: ${item['date']}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}
