import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFF006400),
          child: Icon(Icons.person, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'Patient User',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const Center(
          child: Text(
            'patient@example.com',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        const SizedBox(height: 40),
        _buildSettingOption(Icons.lock_outline, 'Privacy Settings'),
        _buildSettingOption(Icons.notifications_none, 'Notifications'),
        _buildSettingOption(Icons.history, 'Download Records'),
        _buildSettingOption(Icons.help_outline, 'Help & Support'),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {},
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingOption(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF006400)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () {},
    );
  }
}
