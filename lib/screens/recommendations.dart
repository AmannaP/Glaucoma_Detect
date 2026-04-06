import 'package:flutter/material.dart';
import 'messages.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  final List<Map<String, dynamic>> doctors = const [
    {"name": "Dr. Alice Green", "specialty": "Glaucoma Specialist", "distance": "2.5 km", "rating": 4.8},
    {"name": "Dr. Bob White", "specialty": "Ophthalmologist", "distance": "5.0 km", "rating": 4.5},
    {"name": "Dr. Clara Reed", "specialty": "Optometrist", "distance": "8.2 km", "rating": 4.9},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctors.length,
      itemBuilder: (context, index) {
        final doc = doctors[index];
        return Card(
          color: const Color(0xFF131C24),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF006400),
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(doc['specialty'], style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Color(0xFF006400)),
                          const SizedBox(width: 4),
                          Text(doc['distance'], style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(doc['rating'].toString(), style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF00CED1)),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(doc['name'])),
                      body: const MessagesScreen(),
                    )));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
