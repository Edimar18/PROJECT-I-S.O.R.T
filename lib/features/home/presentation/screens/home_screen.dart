
import 'package:flutter/material.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/dashboard_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/scan_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/profile_screen.dart';
import 'package:i_sort/features/home/presentation/screens/tabs/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ScanScreen(),
    // A placeholder for the scan button, which won't be a screen
    SizedBox.shrink(), 
    StatsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // The scan button
      // Handle scan action
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () { /* Handle scan action */ },
        backgroundColor: const Color(0xFF1de9b6),
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
          _buildNavItem(icon: Icons.bar_chart_outlined, index: 3, label: 'Stats'),
          _buildNavItem(icon: Icons.person_outline, index: 4, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index, required String label}) {
    final isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(icon, color: isSelected ? const Color(0xFF1de9b6) : Colors.grey),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}
