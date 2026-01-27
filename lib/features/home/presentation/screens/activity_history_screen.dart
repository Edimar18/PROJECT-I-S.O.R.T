import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityHistoryScreen extends StatelessWidget {
  final List<dynamic> activities;

  const ActivityHistoryScreen({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    // Parse and sort activities
    List<Map<String, dynamic>> parsedActivities = _parseActivities(activities);

    // Group activities by date
    Map<String, List<Map<String, dynamic>>> groupedActivities =
    _groupActivitiesByDate(parsedActivities);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity History',
          style: TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade200,
            height: 1,
          ),
        ),
      ),
      body: parsedActivities.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          _buildSummaryHeader(parsedActivities),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: groupedActivities.length,
              itemBuilder: (context, index) {
                final date = groupedActivities.keys.elementAt(index);
                final dateActivities = groupedActivities[date]!;
                return _buildDateSection(date, dateActivities);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _parseActivities(List<dynamic> activities) {
    List<Map<String, dynamic>> parsed = [];

    for (var activity in activities) {
      if (activity is Map<String, dynamic>) {
        parsed.add({
          'category': activity['category'] ?? 'unknown',
          'points': activity['points'] ?? 1,
          'timestamp': activity['timestamp'] ?? Timestamp.now(),
          'weight': activity['weight'] ?? 0.0,
        });
      } else if (activity is List && activity.length >= 3) {
        parsed.add({
          'category': (activity[0] as String).toLowerCase(),
          'points': activity[2] as int,
          'timestamp': activity[1] as Timestamp,
          'weight': 0.0,
        });
      }
    }

    // Sort by timestamp (most recent first)
    parsed.sort((a, b) {
      final timestampA = a['timestamp'] as Timestamp;
      final timestampB = b['timestamp'] as Timestamp;
      return timestampB.compareTo(timestampA);
    });

    return parsed;
  }

  Map<String, List<Map<String, dynamic>>> _groupActivitiesByDate(
      List<Map<String, dynamic>> activities) {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var activity in activities) {
      final timestamp = activity['timestamp'] as Timestamp;
      final date = timestamp.toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(activity);
    }

    return grouped;
  }

  String _formatDateHeader(String dateKey) {
    final date = DateTime.parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final activityDate = DateTime(date.year, date.month, date.day);

    if (activityDate == today) {
      return 'Today';
    } else if (activityDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(activityDate).inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            'No Activity Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start scanning items to see your history',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<Map<String, dynamic>> activities) {
    int totalScans = activities.length;
    int totalPoints = activities.fold(0, (sum, act) => sum + (act['points'] as int));
    double totalWeight =
    activities.fold(0.0, (sum, act) => sum + (act['weight'] as double));

    // Count by category
    Map<String, int> categoryCounts = {};
    for (var activity in activities) {
      final category = activity['category'] as String;
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    // Find most scanned category
    String topCategory = 'None';
    int maxCount = 0;
    categoryCounts.forEach((category, count) {
      if (count > maxCount) {
        maxCount = count;
        topCategory = category;
      }
    });

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            'Total Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                icon: Icons.qr_code_scanner,
                label: 'Total Scans',
                value: totalScans.toString(),
                color: const Color(0xFF1de9b6),
              ),
              _buildSummaryItem(
                icon: Icons.stars,
                label: 'Total Points',
                value: totalPoints.toString(),
                color: Colors.orangeAccent,
              ),
              _buildSummaryItem(
                icon: Icons.scale,
                label: 'Total Weight',
                value: '${totalWeight.toStringAsFixed(2)}kg',
                color: Colors.blueAccent,
              ),
            ],
          ),
          if (topCategory != 'None') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1de9b6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events,
                      color: Color(0xFF1de9b6), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Most Scanned: ${_capitalizeFirst(topCategory)} ($maxCount times)',
                    style: const TextStyle(
                      color: Color(0xFF1de9b6),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(
      String dateKey, List<Map<String, dynamic>> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
          child: Text(
            _formatDateHeader(dateKey),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityCard(activity);
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final String category = activity['category'] as String;
    final Timestamp timestamp = activity['timestamp'] as Timestamp;
    final int points = activity['points'] as int;
    final double weight = activity['weight'] as double;

    final iconAndColor = _getCategoryIconAndColor(category);
    final color = iconAndColor['color'] as Color;
    final icon = iconAndColor['icon'] as IconData;
    final displayName = _capitalizeFirst(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanned $displayName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    if (weight > 0) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.scale, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${weight.toStringAsFixed(2)}kg',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$points pt${points > 1 ? 's' : ''}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
}