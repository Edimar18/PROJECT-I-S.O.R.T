
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
          'todaysActivityLog': [],
          'lastUpdate': Timestamp.fromDate(now),
        });
      }
    }
  }

  bool _isNewDay(DateTime lastUpdate, DateTime now) {
    return now.year > lastUpdate.year || now.month > lastUpdate.month || now.day > lastUpdate.day;
  }
}
