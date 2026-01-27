import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          'currentDayScannedPapers': 0.0,
          'currentDayScannedPlastics': 0.0,
          'currentDayScannedMetals': 0.0,
          'currentDayScannedCardboard': 0.0,
          'currentDayScannedGlass': 0.0,
          'currentDayScannedTrash': 0.0,
          'currentDayScannedOrganic': 0.0,
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

    // Determine which field to update based on category
    String categoryField = 'currentDayScanned${_capitalizeFirst(category)}';
    if (category == 'organic') {
      categoryField = 'currentDayScannedOrganic';
    }

    // Create activity log entry
    final activityEntry = {
      'category': category,
      'weight': weight,
      'timestamp': Timestamp.now(),
      'points': 1,
    };

    // Update user data
    await userDocRef.update({
      'currentPoints': FieldValue.increment(1),
      'totalPoints': FieldValue.increment(1),
      categoryField: FieldValue.increment(weight),
      'todaysActivityLog': FieldValue.arrayUnion([activityEntry]),
      'lastUpdate': Timestamp.now(),
    });

    print('Scan recorded: $category, weight: $weight kg, +1 point');
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