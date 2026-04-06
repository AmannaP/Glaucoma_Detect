import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (history.isEmpty) {
      return const Center(child: Text("No scan history yet."));
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        final isGlaucoma = item['has_glaucoma'] == true;
        return Card(
          color: const Color(0xFF131C24),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              isGlaucoma ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: isGlaucoma ? Colors.redAccent : const Color(0xFF006400),
              size: 32,
            ),
            title: Text(
              isGlaucoma ? 'Glaucoma Detected' : 'Healthy Eye',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: Text(
              isGlaucoma ? 'Type: ${item['glaucoma_type']}\nDate: ${item['date']}' : 'No defects found.\nDate: ${item['date']}',
              style: const TextStyle(color: Colors.white70),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
