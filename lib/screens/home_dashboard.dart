import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications.dart';
import 'profile.dart';
import 'scan_screen.dart';
import 'recommendations.dart';
import 'messages.dart';
import '../services/notification_service.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _userName = "User";
  String _userRole = "patient";
  String _userEmail = "";
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCount();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? "User";
        _userRole = prefs.getString('user_role') ?? "patient";
        _userEmail = prefs.getString('user_email') ?? "";
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    final notes = await NotificationService.getNotifications();
    if (mounted) {
      setState(() {
        _unreadCount = notes.where((n) => n['isRead'] == false).length;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _allDoctors = [
    {"name": "Dr. Alice Green", "specialty": "Glaucoma Specialist", "email": "alice.green@glaucoma.com"},
    {"name": "Dr. Bob White", "specialty": "Ophthalmologist", "email": "bob.white@glaucoma.com"},
    {"name": "Dr. Clara Reed", "specialty": "Optometrist", "email": "clara.reed@glaucoma.com"},
  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);
    const accentGreen = Color(0xFF00E676);

    List<Map<String, String>> filteredDoctors = _allDoctors.where((doc) {
      final nameMatch = doc['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final specialtyMatch = doc['specialty']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final isNotMe = doc['email'] != _userEmail;
      return (nameMatch || specialtyMatch) && isNotMe;
    }).toList();

    return SafeArea(
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
                    Text(
                      _userName,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService().unreadCountNotifier,
                  builder: (context, unreadCount, _) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: primaryGreen.withOpacity(0.1),
                            child: const Icon(Icons.notifications, color: primaryGreen),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text(
                                  unreadCount.toString(), 
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  }
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
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search doctors, clinics...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Feature Banner (Patient Only)
            if (_userRole == 'patient') ...[
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
            ],

            // Specialties
            const Text("Doctor Specialty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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

            // Top Doctors Label
            const Text("Our Specialists", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentGreen)),
            const SizedBox(height: 15),
            
            // Filtered Doctor List
            ...filteredDoctors.map((doc) => _buildDoctorPreview(doc['name']!, doc['specialty']!)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorPreview(String name, String specialty) {
    return Card(
      color: const Color(0xFF131C24),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
          child: const Icon(Icons.person, color: Color(0xFF00C853)),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(specialty, style: const TextStyle(color: Colors.white54)),
        trailing: IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00C853)),
          onPressed: () {
             Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen(doctorName: name)));
          },
        ),
        onTap: () {
          // Open Appointment Booking
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsScreen()));
        },
      ),
    );
  }

  Widget _buildSpecialtyItem(IconData icon, String label) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
          Icon(icon, color: const Color(0xFF00C853), size: 28),
          const SizedBox(height: 10),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
