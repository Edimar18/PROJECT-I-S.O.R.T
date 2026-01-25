
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nickname = userData['nickname'] ?? 'User';
          final double totalPoints = (userData['totalPoints'] ?? 0.0).toDouble();
          final double dailyPoints = (userData['currentPoints'] ?? 0.0).toDouble();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(nickname, totalPoints),
                  const SizedBox(height: 30),
                  _buildDailyCap(dailyPoints),
                  const SizedBox(height: 30),
                  _buildWasteCategories(userData),
                  const SizedBox(height: 30),
                  _buildRecentActivity(userData['todaysActivityLog'] as List<dynamic>),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildHeader(String nickname, double totalPoints) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF1de9b6)),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_getGreeting()}, ', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF1de9b6), size: 18),
              const SizedBox(width: 6),
              Text('TOTAL SCORE: ${totalPoints.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyCap(double dailyPoints) {
    const double dailyCap = 20.0;
    final double progress = dailyPoints / dailyCap;

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0, // Full circle background
                  strokeWidth: 15,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1de9b6)),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('DAILY CAP', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${dailyPoints.toInt()}', style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                          Text('/ ${dailyCap.toInt()}', style: const TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${(dailyCap - dailyPoints).toInt()} pts to goal!', style: const TextStyle(color: Color(0xFF1de9b6), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Great job! You\'ve reduced \nyour carbon footprint by 15% today.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteCategories(Map<String, dynamic> userData) {
    final categories = {
      'Plastic': {'icon': Icons.local_drink, 'value': userData['currentDayScannedPlastics'] ?? 0.0, 'color': Colors.blueAccent},
      'Paper': {'icon': Icons.article, 'value': userData['currentDayScannedPapers'] ?? 0.0, 'color': Colors.greenAccent},
      'Metal': {'icon': Icons.build, 'value': userData['currentDayScannedMetals'] ?? 0.0, 'color': Colors.orangeAccent},
      'Cardboard': {'icon': Icons.inventory_2, 'value': userData['currentDayScannedCardboard'] ?? 0.0, 'color': Colors.brown},
      'Glass': {'icon': Icons.wine_bar, 'value': userData['currentDayScannedGlass'] ?? 0.0, 'color': Colors.lightBlueAccent},
      'Trash': {'icon': Icons.delete, 'value': userData['currentDayScannedTrash'] ?? 0.0, 'color': Colors.black54},
    };

    return SizedBox(
      height: 120,
      child: ListView( 
        scrollDirection: Axis.horizontal,       
        children: categories.entries.map((entry) {
          final color = entry.value['color'] as Color;
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(entry.value['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${(entry.value['value'] as double).toStringAsFixed(1)}kg', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentActivity(List<dynamic> activities) {
    // Dummy data for UI design
    final dummyActivities = [
      {'description': 'Recycled PET Bottles', 'details': 'Smart Bin #4 • 2 mins ago', 'points': 2, 'icon': Icons.recycling, 'color': Colors.green},
      {'description': 'Scanned Smart Bin', 'details': 'Poblacion Area • 1 hour ago', 'points': 5, 'icon': Icons.qr_code_scanner, 'color': Colors.blueAccent},
      {'description': 'Weekly Challenge', 'details': 'Completed • Yesterday', 'points': 10, 'icon': Icons.emoji_events, 'color': Colors.orangeAccent},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: Color(0xFF1de9b6)))),
          ],
        ),
        const SizedBox(height: 12),
        dummyActivities.isEmpty
            ? const Text('No recent activity.')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dummyActivities.length,
                itemBuilder: (context, index) {
                  final activity = dummyActivities[index];
                  final color = activity['color'] as Color;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(activity['icon'] as IconData, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(activity['description'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(activity['details'] as String, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('+${activity['points']} pts', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }
}
