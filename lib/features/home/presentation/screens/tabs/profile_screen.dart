
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:i_sort/features/authentication/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
          final int rank = (userData['rank'] ?? 0).toInt();
          final double totalPoints = (userData['totalPoints'] ?? 0.0).toDouble();
          final double totalWasteScanned = (userData['totalWasteScanned'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildProfileHeader(nickname),
                const SizedBox(height: 30),
                _buildStats(totalPoints, totalWasteScanned, rank),
                const SizedBox(height: 40),
                _buildSettings(context, userData),
                const SizedBox(height: 30),
                _buildSignOutButton(context),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String nickname) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, size: 50, color: Color(0xFF1de9b6)),
        ),
        const SizedBox(height: 12),
        Text(nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildStats(double totalPoints, double totalWasteScanned, int rank) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total Points', totalPoints.toInt().toString()),
        _buildStatItem('Total Waste Scanned', '${totalWasteScanned.toStringAsFixed(1)}kg'),
        _buildStatItem('Rank', '#$rank'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      width: 110, // Increased width
      padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  Widget _buildSettings(BuildContext context, Map<String, dynamic> userData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
          const SizedBox(height: 10),
          _buildSettingsItem(context, icon: Icons.person_outline, title: 'Account Information', onTap: () => _showAccountInfo(context, userData)),
          const Divider(),
          _buildSettingsItem(context, icon: Icons.info_outline, title: 'About Us', onTap: () => _showAboutUs(context)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showAccountInfo(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nickname: ${userData['nickname'] ?? 'N/A'}'),
            Text('Email: ${userData['email'] ?? 'N/A'}'),
            Text('Address: ${userData['address'] ?? 'N/A'}'),
            Text('Contact: ${userData['contactNumber'] ?? 'N/A'}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _showAboutUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Us'),
        content: const Text('I-SORT is a project dedicated to promoting proper waste segregation and recycling.'),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () => AuthService().signOut(),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.red.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
