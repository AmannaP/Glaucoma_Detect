import 'package:flutter/material.dart';

void main() {
  runApp(const SphygoApp());
}

class SphygoApp extends StatelessWidget {
  const SphygoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E12), // Deep dark background
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo and Brand Name Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00CED1), width: 3),
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00CED1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'phygo',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Detect Eye Problem, early.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),

            // Central Scanning Illustration
            Center(
              child: Stack(
                alignment: MainAxisAlignment.center,
                children: [
                  // Outer Container
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: const Color(0xFF131C24),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // Concentric Circles and Eye Icon
                  const Icon(
                    Icons.remove_red_eye_outlined,
                    size: 60,
                    color: Color(0xFF00CED1),
                  ),
                  // Animated/Static Rings
                  ...List.generate(3, (index) => Container(
                    width: 100 + (index * 40.0),
                    height: 100 + (index * 40.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF00CED1).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  )),
                  // The small red alert dot
                  Positioned(
                    top: 80,
                    right: 80,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(isActive: true),
                _buildDot(isActive: false),
                _buildDot(isActive: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF00CED1) : Colors.white24,
        shape: BoxShape.circle,
      ),
    );
  }
}