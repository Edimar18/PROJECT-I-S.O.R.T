
import 'package:flutter/material.dart';
import 'package:i_sort/features/home/presentation/screens/qr_scanner_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/dashboard_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/scan_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/profile_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/stats_screen.dart';
import 'package:i_sort/features/user/services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _userService.checkAndResetDailyData();
  }

  // Simplified the list of screens. The placeholder is no longer needed.
  static const List<Widget> _screens = <Widget>[
    DashboardScreen(), // Index 0
    ScanScreen(),      // Index 1
    StatsScreen(),     // Index 2
    ProfileScreen(),   // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This now correctly selects the screen based on the index.
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const QrScannerScreen()));
        },
        backgroundColor: const Color(0xFF1de9b6),
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(icon: Icons.home_filled, index: 0, label: 'Home'),
          _buildNavItem(icon: Icons.camera_alt_outlined, index: 1, label: 'Scan'),
          const SizedBox(width: 48), // The space for the FAB
          // Corrected the indices for Stats and Profile
          _buildNavItem(icon: Icons.bar_chart_outlined, index: 2, label: 'Stats'),
          _buildNavItem(icon: Icons.person_outline, index: 3, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF1de9b6) : Colors.grey),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF1de9b6) : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
