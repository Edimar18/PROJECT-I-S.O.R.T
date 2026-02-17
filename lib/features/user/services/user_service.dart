import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const double DAILY_POINTS_CAP = 20.0;

  Future<void> checkAndResetDailyData() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final DocumentReference userDocRef = _db.collection('users').doc(user.uid);
    final DocumentSnapshot userDoc = await userDocRef.get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final Timestamp? lastUpdate = data['lastUpdate'] as Timestamp?;
      final now = DateTime.now();

      if (lastUpdate == null || _isNewDay(lastUpdate.toDate(), now)) {
        await userDocRef.update({
          'currentPoints': 0.0,
          'currentDayScannedCardboard': 0.0,  // Keep
          'currentDayScannedEwaste': 0.0,     // ADD (note: Ewaste, not E-waste)
          'currentDayScannedGlass': 0.0,      // Keep
          'currentDayScannedMedical': 0.0,    // ADD
          'currentDayScannedMetal': 0.0,      // Keep (was Metals, now Metal)
          'currentDayScannedPaper': 0.0,      // Keep (was Papers, now Paper)
          'currentDayScannedPlastic': 0.0,    // Keep (was Plastics, now Plastic)

          // REMOVE these:
          // 'currentDayScannedOrganic': 0.0,
          // 'currentDayScannedTrash': 0.0,

          'scannedCountCardboard': 0,
          'scannedCountEwaste': 0,      // ADD
          'scannedCountGlass': 0,
          'scannedCountMedical': 0,     // ADD
          'scannedCountMetal': 0,
          'scannedCountPaper': 0,
          'scannedCountPlastic': 0,

          // REMOVE these:
          // 'scannedCountOrganic': 0,
          // 'scannedCountTrash': 0,

          'diversityBonusEarned': false,
          'todaysActivityLog': [],
          'lastUpdate': Timestamp.fromDate(now),
        });
      }
    }
  }

  bool _isNewDay(DateTime lastUpdate, DateTime now) {
    return now.year > lastUpdate.year ||
        now.month > lastUpdate.month ||
        now.day > lastUpdate.day;
  }

  Future<void> recordScan(String category, double weight) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final DocumentReference userDocRef = _db.collection('users').doc(user.uid);

    // Check and reset daily data first
    await checkAndResetDailyData();

    // Get current user data
    final userSnapshot = await userDocRef.get();
    final userData = userSnapshot.data() as Map<String, dynamic>;

    final double currentPoints = (userData['currentPoints'] ?? 0).toDouble();
    final Map<String, dynamic> scannedCounts = {
      'cardboard': (userData['scannedCountCardboard'] ?? 0),
      'e-waste': (userData['scannedCountEwaste'] ?? 0),    // ADD
      'glass': (userData['scannedCountGlass'] ?? 0),
      'medical': (userData['scannedCountMedical'] ?? 0),   // ADD
      'metal': (userData['scannedCountMetal'] ?? 0),
      'paper': (userData['scannedCountPaper'] ?? 0),
      'plastic': (userData['scannedCountPlastic'] ?? 0),

      // REMOVE:
      // 'organic': (userData['scannedCountOrganic'] ?? 0),
      // 'trash': (userData['scannedCountTrash'] ?? 0),
    };

    // Determine which field to update based on category
    String categoryField = 'currentDayScanned${_capitalizeFirst(category)}';
    String capitalized = _capitalizeFirst(category);

// SPECIAL CASE for e-waste (has hyphen):
    if (category == 'e-waste') {
      categoryField = 'currentDayScannedEwaste';
      capitalized = 'Ewaste';
    }

    String totalCategoryField = 'totalScanned$capitalized';
    String countField = 'scannedCount$capitalized';


    // Check if user has reached daily cap
    bool hasReachedCap = currentPoints >= DAILY_POINTS_CAP;

    // Calculate points to add
    int pointsToAdd = 0;
    int bonusPoints = 0;

    if (!hasReachedCap) {
      pointsToAdd = 1; // Normal scan point
    }

    // Check for diversity bonus (2 of each type)
    scannedCounts[category] = (scannedCounts[category] ?? 0) + 1;
    bool earnedDiversityBonus = _checkDiversityBonus(userData, scannedCounts);

    if (earnedDiversityBonus) {
      bonusPoints = 5;
    }

    // Create activity log entry
    final activityEntry = {
      'category': category,
      'weight': weight,
      'timestamp': Timestamp.now(),
      'points': pointsToAdd,
      'bonusPoints': bonusPoints,
      'cappedScan': hasReachedCap && bonusPoints == 0,
    };

    // Prepare update data
    Map<String, dynamic> updateData = {
      categoryField: FieldValue.increment(weight),
      totalCategoryField: FieldValue.increment(weight),
      'totalWasteScanned': FieldValue.increment(weight),
      countField: FieldValue.increment(1),
      'todaysActivityLog': FieldValue.arrayUnion([activityEntry]),
      'lastUpdate': Timestamp.now(),
    };

    // Add points if not capped
    if (pointsToAdd > 0) {
      updateData['currentPoints'] = FieldValue.increment(pointsToAdd);
      updateData['totalPoints'] = FieldValue.increment(pointsToAdd);
    }

    // Add bonus points (not affected by cap)
    if (bonusPoints > 0) {
      updateData['currentPoints'] = FieldValue.increment(bonusPoints);
      updateData['totalPoints'] = FieldValue.increment(bonusPoints);
      updateData['diversityBonusEarned'] = true;
    }

    // Update user data
    await userDocRef.update(updateData);

    print('Scan recorded: $category, weight: $weight kg, points: $pointsToAdd, bonus: $bonusPoints, capped: $hasReachedCap');
  }

  bool _checkDiversityBonus(Map<String, dynamic> userData, Map<String, dynamic> newCounts) {
    // Check if user already earned the bonus today
    if (userData['diversityBonusEarned'] == true) {
      return false;
    }

    // Check if all categories have at least 2 scans
    bool allCategoriesScanned = true;
    for (var count in newCounts.values) {
      if (count < 2) {
        allCategoriesScanned = false;
        break;
      }
    }

    return allCategoriesScanned;
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot userDoc =
    await _db.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return null;
  }
}