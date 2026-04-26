import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  bool _isLoadingData = false;
  List<dynamic> _patientPrescriptions = [];
  Map<String, dynamic>? _selectedPrescription;
  List<dynamic> _doctors = [];
  List<dynamic> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadPrescriptions();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingData = true);
    await Future.wait([
      _fetchDoctors(),
      _fetchPharmacies(),
    ]);
    setState(() => _isLoadingData = false);
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await http.get(Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/auth.php?action=fetch_doctors'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _doctors = data['doctors'];
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch doctors error: $e");
    }
  }

  Future<void> _fetchPharmacies() async {
    try {
      final response = await http.get(Uri.parse('http://169.239.251.102:280/~chika.amanna/Glaucoma_Detect/backend/pharmacies.php?action=fetch'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _pharmacies = data['pharmacies'];
            _sortPharmacies();
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch pharmacies error: $e");
    }
  }

  Future<void> _loadPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('patient_prescriptions');
    if (data != null) {
      setState(() {
        _patientPrescriptions = json.decode(data);
      });
    }
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
        _sortPharmacies();
      });
    } catch (e) {
      debugPrint("Location error: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  void _sortPharmacies() {
    if (_currentPosition == null || _pharmacies.isEmpty) return;
    _pharmacies.sort((a, b) {
      double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, double.parse(a['lat'].toString()), double.parse(a['lng'].toString()));
      double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, double.parse(b['lat'].toString()), double.parse(b['lng'].toString()));
      return distA.compareTo(distB);
    });
  }

  void _showPrescriptionDialog(Map<String, dynamic> pharmacy) {
    _selectedPrescription = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF131C24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Order from ${pharmacy['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select a valid prescription to verify your order:",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 20),
                if (_patientPrescriptions.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No prescriptions found in your account.", style: TextStyle(color: Colors.white24)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _patientPrescriptions.length,
                      itemBuilder: (context, index) {
                        final item = _patientPrescriptions[index];
                        final isSelected = _selectedPrescription == item;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _selectedPrescription = item;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF00C853).withOpacity(0.1) : Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? const Color(0xFF00C853) : Colors.white10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.description, color: isSelected ? const Color(0xFF00C853) : Colors.white24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['diagnosis'] ?? "Prescription",
                                        style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "${item['doctorName']} • ${item['date']}",
                                        style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: _selectedPrescription == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      _handleOrderPlacement(pharmacy);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Verify & Order", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleOrderPlacement(Map<String, dynamic> pharmacy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131C24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00C853), size: 60),
            const SizedBox(height: 20),
            const Text(
              "Order Successful!",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Your medication from ${pharmacy['name']} is being prepared and will be delivered shortly.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Great!"),
              ),
            ),
          ],
        ),
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
    final filteredDoctors = _doctors.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      final specialty = doc['specialty'].toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();

    if (_isLoadingData && _doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }

    if (_doctors.isEmpty) {
      return const Center(child: Text("No doctors found.", style: TextStyle(color: Colors.white54)));
    }

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
                            Text(doc['distance'] ?? "Calculating...", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
    if (_isLoadingData && _pharmacies.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)));
    }

    if (_pharmacies.isEmpty) {
      return const Center(child: Text("No pharmacies found.", style: TextStyle(color: Colors.white54)));
    }

    // Limit to top 2 closest
    final topPharmacies = _pharmacies.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF00C853), size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Displaying top two closest pharmacies based on your location",
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topPharmacies.length,
            itemBuilder: (context, index) {
              final pharm = topPharmacies[index];
              bool isTopRecommendation = true; // Both are top now

        String distance = "Finding...";
        if (_currentPosition != null) {
          double meters = Geolocator.distanceBetween(
            _currentPosition!.latitude, 
            _currentPosition!.longitude, 
            double.parse(pharm['lat'].toString()), 
            double.parse(pharm['lng'].toString())
          );
          distance = "${(meters / 1000).toStringAsFixed(1)} km";
        }
        
        return GestureDetector(
          onTap: () => _showPrescriptionDialog(pharm),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: isTopRecommendation ? Border.all(color: const Color(0xFF00C853), width: 1.5) : null,
              boxShadow: isTopRecommendation ? [
                BoxShadow(color: const Color(0xFF00C853).withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
              ] : null,
            ),
            child: Card(
              color: const Color(0xFF131C24),
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Stack(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: (isTopRecommendation ? const Color(0xFF00C853) : Colors.blueAccent).withOpacity(0.1),
                      child: Icon(
                        isTopRecommendation ? Icons.verified : Icons.local_pharmacy, 
                        color: isTopRecommendation ? const Color(0xFF00C853) : Colors.blueAccent
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(pharm['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        if (isTopRecommendation)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text("RECOMMENDED", style: TextStyle(color: Color(0xFF00C853), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
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
