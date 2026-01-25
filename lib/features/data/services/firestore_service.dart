
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<String>> getBarangays() async {
    try {
      final snapshot = await _db.collection('addresses').doc('address').get();
      if (snapshot.exists && snapshot.data()!.containsKey('barangay')) {
        final List<dynamic> barangayData = snapshot.data()!['barangay'];
        final List<String> barangays = barangayData.map((e) => e.toString()).toList();
        barangays.sort();
        return barangays;
      }
      return [];
    } catch (e) {
      print(e); // For debugging
      return [];
    }
  }

  Future<void> createUserDocument(String userId, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(userId).set(data);
    } catch (e) {
      print(e); // For debugging
      // Consider more robust error handling
    }
  }
}
