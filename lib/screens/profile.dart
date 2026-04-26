import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'doctor_dashboard.dart';

import 'notifications.dart';
import 'scan_history.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "Loading...";
  String _email = "Loading...";
  String _role = "patient";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('user_name') ?? "User";
      _email = prefs.getString('user_email') ?? "user@example.com";
      _role = prefs.getString('user_role') ?? "patient";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    
    return Material(
      color: Colors.black,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: primaryGreen.withOpacity(0.1),
              child: const Icon(Icons.person, size: 60, color: primaryGreen),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_email, style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (_role == 'doctor' ? Colors.blue : primaryGreen).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(_role.toUpperCase(), style: TextStyle(color: _role == 'doctor' ? Colors.blue : primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          _buildSettingOption(Icons.lock_outline, 'Privacy Settings', () {}),
          _buildSettingOption(Icons.notifications_none, 'Notifications', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          if (_role == 'patient') ...[
            _buildSettingOption(Icons.description_outlined, 'My Prescriptions', () {
              // Navigate to prescriptions list
            }),
            _buildSettingOption(Icons.history, 'Scan History', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanHistoryScreen()));
            }),
          ] else ...[
            _buildSettingOption(Icons.business_center_outlined, 'Practice Settings', () {}),
            _buildSettingOption(Icons.schedule, 'Manage Availability', () {}),
          ],
          _buildSettingOption(Icons.help_outline, 'Help & Support', () {}),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text("Log Out"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.redAccent, width: 1),
              ),
            ),
          ),
        ),
      ],
    ),
   );
  }

  Widget _buildSettingOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF00C853)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
    );
  }
}
