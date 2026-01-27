import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../activity_history_screen.dart';

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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User data not found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nickname = userData['nickname'] ?? 'User';
          final double totalPoints =
          (userData['totalPoints'] ?? 0.0).toDouble();
          final double dailyPoints =
          (userData['currentPoints'] ?? 0.0).toDouble();

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
                  _buildRecentActivity(
                      context,
                      userData['todaysActivityLog'] as List<dynamic>? ?? []),
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

  String _formatTotalScore(double score) {
    final int scoreInt = score.toInt();
    if (scoreInt >= 10000) {
      return '${(scoreInt / 1000).floor()}k+';
    }
    return scoreInt.toString();
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
                Text('${_getGreeting()}, ',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                Text(nickname,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333))),
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
              const Icon(Icons.check_circle,
                  color: Color(0xFF1de9b6), size: 18),
              const SizedBox(width: 6),
              Text('TOTAL SCORE: ${_formatTotalScore(totalPoints)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12)),
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
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.grey.shade200),
                ),
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 15,
                  backgroundColor: Colors.transparent,
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1de9b6)),
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('DAILY CAP',
                          style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${dailyPoints.toInt()}',
                              style: const TextStyle(
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333))),
                          Text('/ ${dailyCap.toInt()}',
                              style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1de9b6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dailyPoints >= dailyCap
                              ? 'Daily goal reached! 🎉'
                              : '${(dailyCap - dailyPoints).toInt()} pts to goal!',
                          style: const TextStyle(
                              color: Color(0xFF1de9b6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            dailyPoints > 0
                ? 'Great job! You\'ve reduced \nyour carbon footprint by ${(dailyPoints * 0.75).toStringAsFixed(0)}% today.'
                : 'Start scanning to reduce your\ncarbon footprint today!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteCategories(Map<String, dynamic> userData) {
    final categories = {
      'Plastic': {
        'icon': Icons.local_drink,
        'value': userData['currentDayScannedPlastics'] ?? 0.0,
        'color': Colors.blueAccent
      },
      'Paper': {
        'icon': Icons.article,
        'value': userData['currentDayScannedPapers'] ?? 0.0,
        'color': Colors.greenAccent
      },
      'Metal': {
        'icon': Icons.build,
        'value': userData['currentDayScannedMetals'] ?? 0.0,
        'color': Colors.orangeAccent
      },
      'Cardboard': {
        'icon': Icons.inventory_2,
        'value': userData['currentDayScannedCardboard'] ?? 0.0,
        'color': Colors.brown
      },
      'Glass': {
        'icon': Icons.wine_bar,
        'value': userData['currentDayScannedGlass'] ?? 0.0,
        'color': Colors.lightBlueAccent
      },
      'Organic': {
        'icon': Icons.eco,
        'value': userData['currentDayScannedOrganic'] ?? 0.0,
        'color': Colors.green
      },
      'Trash': {
        'icon': Icons.delete,
        'value': userData['currentDayScannedTrash'] ?? 0.0,
        'color': Colors.black54
      },
    };

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.entries.map((entry) {
          final color = entry.value['color'] as Color;
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
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
                  child: Icon(entry.value['icon'] as IconData,
                      color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(entry.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('${(entry.value['value'] as double).toStringAsFixed(2)}kg',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp.toDate());

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} secs ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp.toDate());
    }
  }

  Map<String, dynamic> _getCategoryIconAndColor(String category) {
    switch (category.toLowerCase()) {
      case 'plastic':
        return {'icon': Icons.local_drink, 'color': Colors.blueAccent};
      case 'paper':
        return {'icon': Icons.article, 'color': Colors.greenAccent};
      case 'metal':
        return {'icon': Icons.build, 'color': Colors.orangeAccent};
      case 'cardboard':
        return {'icon': Icons.inventory_2, 'color': Colors.brown};
      case 'glass':
        return {'icon': Icons.wine_bar, 'color': Colors.lightBlueAccent};
      case 'organic':
        return {'icon': Icons.eco, 'color': Colors.green};
      case 'trash':
        return {'icon': Icons.delete, 'color': Colors.black54};
      default:
        return {'icon': Icons.recycling, 'color': Colors.teal};
    }
  }

  String _getCategoryDisplayName(String category) {
    // Capitalize first letter
    return category[0].toUpperCase() + category.substring(1);
  }

  void _navigateToActivityHistory(BuildContext context, List<dynamic> activities) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityHistoryScreen(activities: activities),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, List<dynamic> activities) {
    // Handle empty activity log
    if (activities.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333))),
              TextButton(
                onPressed: null, // Disabled when no activities
                child: Text('View All',
                    style: TextStyle(color: Colors.grey.shade400)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'No activity yet',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Start scanning to track your progress!',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Parse activity log - handle new format with Maps
    List<Map<String, dynamic>> parsedActivities = [];

    for (var activity in activities) {
      if (activity is Map<String, dynamic>) {
        // New format: {category: "glass", points: 1, timestamp: Timestamp, weight: 0.25}
        parsedActivities.add({
          'category': activity['category'] ?? 'unknown',
          'points': activity['points'] ?? 1,
          'timestamp': activity['timestamp'] ?? Timestamp.now(),
          'weight': activity['weight'] ?? 0.0,
        });
      } else if (activity is List && activity.length >= 3) {
        // Old format: [description, timestamp, points]
        parsedActivities.add({
          'category': (activity[0] as String).toLowerCase(),
          'points': activity[2] as int,
          'timestamp': activity[1] as Timestamp,
          'weight': 0.0,
        });
      }
    }

    // Sort by timestamp (most recent first)
    parsedActivities.sort((a, b) {
      final timestampA = a['timestamp'] as Timestamp;
      final timestampB = b['timestamp'] as Timestamp;
      return timestampB.compareTo(timestampA);
    });

    // Get total count and take only the latest 5 for preview
    final totalCount = parsedActivities.length;
    final latestActivities = parsedActivities.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333))),
            TextButton(
              onPressed: () => _navigateToActivityHistory(context, activities),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All',
                      style: const TextStyle(color: Color(0xFF1de9b6))),
                  if (totalCount > 5) ...[
                    const SizedBox(width: 4),
                    Text('(${totalCount})',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestActivities.length,
          itemBuilder: (context, index) {
            final activity = latestActivities[index];
            final String category = activity['category'] as String;
            final Timestamp timestamp = activity['timestamp'] as Timestamp;
            final int points = activity['points'] as int;
            final double weight = activity['weight'] as double;

            final iconAndColor = _getCategoryIconAndColor(category);
            final color = iconAndColor['color'] as Color;
            final icon = iconAndColor['icon'] as IconData;
            final displayName = _getCategoryDisplayName(category);

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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scanned $displayName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    _formatTimestamp(timestamp),
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                  if (weight > 0) ...[
                                    const Text(' • ',
                                        style: TextStyle(color: Colors.grey)),
                                    Text(
                                      '${weight.toStringAsFixed(2)}kg',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+$points pt${points > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
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