
import 'package:flutter/material.dart';
import 'package:i_sort/features/authentication/services/auth_service.dart';

class AppHomeScreen extends StatelessWidget {
  const AppHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('I-SORT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome, Eco-Warrior!'),
      ),
    );
  }
}
