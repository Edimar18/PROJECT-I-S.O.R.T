
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:i_sort/features/data/services/firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        return 'Invalid email or password. Please try again.';
      }
      return e.message;
    }
  }

  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String nickname,
    required DateTime dateOfBirth,
    required String address,
    required String contactNumber,
  }) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        final int age = DateTime.now().difference(dateOfBirth).inDays ~/ 365;
        await _firestoreService.createUserDocument(user.uid, {
          'nickname': nickname,
          'email': email,
          'dateOfBirth': Timestamp.fromDate(dateOfBirth),
          'age': age,
          'address': address,
          'contactNumber': contactNumber,
          'timeCreated': FieldValue.serverTimestamp(),
          'currentPoints': 0.0,
          'totalPoints': 0.0,
          'totalWasteScanned': 0.0,
          'currentDayScannedPapers': 0.0,
          'currentDayScannedPlastics': 0.0,
          'currentDayScannedMetals': 0.0,
          'currentDayScannedCardboard': 0.0,
          'currentDayScannedGlass': 0.0,
          'currentDayScannedTrash': 0.0,
          'todaysActivityLog': [],
        });
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'An account already exists with this email.';
      }
      return e.message;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
