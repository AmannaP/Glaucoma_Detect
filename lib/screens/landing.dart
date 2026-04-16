import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF00C853);
    const Color cardBg = Color(0xFF131C24);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Logo and Brand Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryGreen, width: 2),
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Glaucoma Detect',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'serif', // Trying to match the 'phygo' serif look
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Header
              const Text(
                'Services we offer',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Professional glaucoma screening and monitoring\nready at your fingertips',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Services List
              _buildPermissionItem(
                icon: Icons.remove_red_eye_outlined,
                title: 'AI Eye Scanning',
                subtitle: 'Automated detection using advanced neural networks',
                primaryColor: primaryGreen,
                cardBg: cardBg,
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.analytics_outlined,
                title: 'Progress Tracking',
                subtitle: 'Monitor your eye health journey over time',
                primaryColor: primaryGreen,
                cardBg: cardBg,
              ),
              const SizedBox(height: 16),
              _buildPermissionItem(
                icon: Icons.chat_bubble_outline,
                title: 'Doctor Consultations',
                subtitle: 'Connect with specialists for expert advice',
                primaryColor: primaryGreen,
                cardBg: cardBg,
              ),
              
              const SizedBox(height: 32),
              
              // Local Resources Section
              const Text(
                'Local Resources Used',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildResourceTag('On-device AI', primaryGreen),
                  const SizedBox(width: 8),
                  _buildResourceTag('Secure Local Storage', primaryGreen),
                  const SizedBox(width: 8),
                  _buildResourceTag('Offline Access', primaryGreen),
                ],
              ),
              
              const Spacer(),
              
              const SizedBox(height: 30),
              
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primaryColor,
    required Color cardBg,
  }) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResourceTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive, required Color color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 16 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}