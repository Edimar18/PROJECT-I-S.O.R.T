import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:i_sort/features/authentication/services/auth_service.dart';
// Import the update service and dialog
import '../../../../user/services/update_service.dart';
import '../../widgets/update_widget.dart';

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
          final int rank = (userData['rank'] ?? 0).toInt();
          final double totalPoints = (userData['totalPoints'] ?? 0.0).toDouble();
          final double totalWasteScanned =
          (userData['totalWasteScanned'] ?? 0.0).toDouble();

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
                const SizedBox(height: 20),
                _buildCheckUpdateButton(context),
                const SizedBox(height: 20),
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
        Text(nickname,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildStats(double totalPoints, double totalWasteScanned, int rank) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('Total Points', totalPoints.toInt().toString()),
        _buildStatItem('Total Waste Scanned',
            '${totalWasteScanned.toStringAsFixed(1)}kg'),
        _buildStatItem('Rank', rank > 0 ? '#$rank' : 'Unranked'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333))),
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
          const Text('Settings',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333))),
          const SizedBox(height: 10),
          _buildSettingsItem(context,
              icon: Icons.person_outline,
              title: 'Account Information',
              onTap: () => _showAccountInfo(context, userData)),
          const Divider(),
          _buildSettingsItem(context,
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () => _showAboutUs(context)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildCheckUpdateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _checkForUpdates(context),
        icon: const Icon(Icons.system_update_outlined),
        label: const Text('Check for Updates'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: const Color(0xFF1de9b6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1de9b6)),
        ),
      ),
    );

    // Uncomment when you have the UpdateService implemented

    final updateService = UpdateService();
    final updateInfo = await updateService.checkForUpdates();

    // Close loading dialog
    if (context.mounted) Navigator.of(context).pop();

    if (updateInfo['error'] != null) {
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking updates: ${updateInfo['error']}')),
        );
      }
      return;
    }

    if (!updateInfo['hasUpdate']) {
      // No updates available
      if (context.mounted) {
        _showNoUpdateDialog(context);
      }
      return;
    }

    // Show update dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UpdateDialog(
          updateInfo: updateInfo,
          onUpdate: (downloadModel, downloadApp, modelUrl, appUrl) async {
            // MODIFICATION: Pass the new URL parameters to your _performUpdate method
            await _performUpdate(
                context, updateInfo, downloadModel, downloadApp, modelUrl, appUrl);
          },
        ),
      );
    }


    // Temporary - Remove this when implementing UpdateService
    /*
    await Future.delayed(const Duration(seconds: 1));
    if (context.mounted) {
      Navigator.of(context).pop();
      _showNoUpdateDialog(context);
    }
     */
  }

  Future<void> _performUpdate(
      BuildContext context,
      Map<String, dynamic> updateInfo,
      bool downloadModel,
      bool downloadApp,
      String? modelUrl,
      String? appUrl,
      ) async {
    // Uncomment when you have UpdateService implemented

    final updateService = UpdateService();

    try {
      if (downloadModel) {
        final modelData = updateInfo['modelData'] as Map<String, dynamic>;
        final success = await updateService.downloadAndUpdateModel(
          modelData['download_link'],
          updateInfo['latestModelVersion'],
          (progress) {
            // Update progress in dialog
            print('Model download progress: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );

        if (!success) {
          throw Exception('Failed to update model');
        }
      }

      if (downloadApp) {
        final appData = updateInfo['appData'] as Map<String, dynamic>;
        await updateService.downloadAndInstallApp(
          appData['download_link'],
          (progress) {
            // Update progress in dialog
            print('App download progress: ${(progress * 100).toStringAsFixed(0)}%');
          },
        );
        // App will restart after installation
        return;
      }

      // Close dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update completed successfully!'),
            backgroundColor: Color(0xFF1de9b6),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }

  }

  void _showNoUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1de9b6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF1de9b6),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('You\'re Up to Date!'),
          ],
        ),
        content: const Text(
          'You have the latest version of the app and AI model.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAccountInfo(BuildContext context, Map<String, dynamic> userData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Account Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nickname', userData['nickname'] ?? 'N/A'),
            _buildInfoRow('Email', userData['email'] ?? 'N/A'),
            _buildInfoRow('Address', userData['address'] ?? 'N/A'),
            _buildInfoRow('Contact', userData['contactNumber'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showAboutUs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'About I-S.O.R.T.',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Text(
            '''I-S.O.R.T. (Iskolar Smart Operations for Recycling & Tracking) is a student-led initiative by the ISDA Cluster C scholar-leaders of Cagayan de Oro City.

Our Mission:
We bridge the gap between awareness and behavior using AI-powered mentorship to transform disposal into a lifelong learning experience.

The Story:
Grounded through the City Education Development Office, we recognized a critical "Segregation Gap" in CDO. This project serves as a catalyst for environmental change.

Intelligent. Sustainable. Scholar-led.''',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF1de9b6), fontWeight: FontWeight.bold),
            ),
          )
        ],
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
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text('Sign Out',
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}