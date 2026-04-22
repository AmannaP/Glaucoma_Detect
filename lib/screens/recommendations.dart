import 'package:flutter/material.dart';
import 'messages.dart';
import 'doctor_detail.dart';

class RecommendationsScreen extends StatelessWidget {
  final String searchQuery;
  const RecommendationsScreen({super.key, this.searchQuery = ""});

  final List<Map<String, dynamic>> doctors = const [
    {"name": "Dr. Alice Green", "specialty": "Glaucoma Specialist", "distance": "2.5 km", "rating": 4.8},
    {"name": "Dr. Bob White", "specialty": "Ophthalmologist", "distance": "5.0 km", "rating": 4.5},
    {"name": "Dr. Clara Reed", "specialty": "Optometrist", "distance": "8.2 km", "rating": 4.9},
  ];

  ];

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF00C853);

    final filteredDoctors = doctors.where((doc) {
      final name = doc['name'].toString().toLowerCase();
      final specialty = doc['specialty'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || specialty.contains(query);
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true, // Needed if used inside SingleChildScrollView of HomeDashboard
      physics: const NeverScrollableScrollPhysics(), // Needed if used inside SingleChildScrollView
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doc = filteredDoctors[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorDetailScreen(doctor: doc)));
          },
          child: Card(
            color: const Color(0xFF131C24),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: primaryGreen, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc['specialty'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
                        appBar: AppBar(title: Text(doc['name']), backgroundColor: Colors.black, foregroundColor: primaryGreen),
                        body: const MessagesScreen(),
                      )));
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
}
