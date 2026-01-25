
import 'package:flutter/material.dart';
import 'package:i_sort/features/authentication/services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => authService.signOut(),
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
