import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'messages.dart';
import 'doctor_detail.dart';

class RecommendationsScreen extends StatefulWidget {
  final String searchQuery;
  const RecommendationsScreen({super.key, this.searchQuery = ""});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> doctors = const [
    {"name": "Dr. Alice Green", "specialty": "Glaucoma Specialist", "distance": "2.5 km", "rating": 4.8},
    {"name": "Dr. Bob White", "specialty": "Ophthalmologist", "distance": "5.0 km", "rating": 4.5},
    {"name": "Dr. Clara Reed", "specialty": "Optometrist", "distance": "8.2 km", "rating": 4.9},
  ];

  final List<Map<String, dynamic>> pharmacies = [
    {"name": "City Pharma", "address": "123 Green St", "rating": 4.8},
    {"name": "Health Plus", "address": "456 Blue Ave", "rating": 4.5},
    {"name": "Eye Care Pharmacy", "address": "789 Health Rd", "rating": 4.7},
    {"name": "St. Luke's Pharmacy", "address": "321 Oak Blvd", "rating": 4.3},
    {"name": "MedDirect", "address": "654 Pine Ln", "rating": 4.6},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      print("Location error: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showPrescriptionDialog(Map<String, dynamic> pharmacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C24),
        title: Text("Prescription Required", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To purchase medication from ${pharmacy['name']}, you must upload your doctor's official prescription form.",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.description, color: Color(0xFF00C853)),
                  SizedBox(width: 10),
                  Text("dr_alice_prescription.pdf", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Prescription verified! Your order is being prepared."))
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C853), foregroundColor: Colors.black),
            child: const Text("Verify & Order"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.black,
            child: TabBar(
              indicatorColor: primaryGreen,
              labelColor: primaryGreen,
              unselectedLabelColor: Colors.white54,
              tabs: const [
                Tab(text: "Doctors"),
                Tab(text: "Pharmacies"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDoctorList(),
                _buildPharmacyList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    final filteredDoctors = doctors.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      final specialty = doc['specialty'].toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doc = filteredDoctors[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)));
          },
          child: Card(
            color: const Color(0xFF131C24),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
                    child: const Icon(Icons.person, color: Color(0xFF00C853), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white)),
                        Text(doc['specialty'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(doc['distance'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(doc['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF1976D2)),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => MessagesScreen(doctorName: doc['name'])));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPharmacyList() {
    return Column(
      children: [
        if (_isLoadingLocation)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(color: Color(0xFF00C853), backgroundColor: Colors.transparent),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharm = pharmacies[index];
              // Simulate distance based on location
              String distance = _currentPosition != null ? "${(index + 0.5).toStringAsFixed(1)} km" : "Finding...";
              
              return GestureDetector(
                onTap: () => _showPrescriptionDialog(pharm),
                child: Card(
                  color: const Color(0xFF131C24),
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(Icons.local_pharmacy, color: Colors.blueAccent),
                    ),
                    title: Text(pharm['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Text("${pharm['address']} • $distance", style: const TextStyle(color: Colors.white70)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(pharm['rating'].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
