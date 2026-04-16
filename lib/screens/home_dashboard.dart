import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'recommendations.dart';

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    const accentGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello,",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const Text(
                        "Patient User",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: primaryGreen.withOpacity(0.1),
                        child: const Icon(Icons.person, color: primaryGreen),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Text("2", style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C24),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search doctors, clinics...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: Icon(Icons.tune, color: primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Feature Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryGreen, Color(0xFF008E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Medical Checks!",
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Check your eye health today with our AI assistant.",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Check Now"),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.health_and_safety, size: 80, color: Colors.white24),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Specialties
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text("Doctor Specialty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton(onPressed: () {}, child: const Text("See all", style: TextStyle(color: primaryGreen))),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSpecialtyItem(Icons.visibility, "Ophthalmology"),
                    _buildSpecialtyItem(Icons.science, "Optometry"),
                    _buildSpecialtyItem(Icons.biotech, "Surgery"),
                    _buildSpecialtyItem(Icons.medication, "General"),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Top Doctors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Top Doctors", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentGreen)),
                  TextButton(onPressed: () {}, child: const Text("See all", style: TextStyle(color: accentGreen))),
                ],
              ),
              const SizedBox(height: 15),
              // We can reuse a simplified version of RecommendationsScreen here or a grid
              const RecommendationsScreen(), // This will be updated to handle the new theme
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialtyItem(IconData icon, String label) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF131C24),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF00C853), size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
        ],
      ),
    );
  }
}
