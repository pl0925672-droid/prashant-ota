import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import 'package:prashant/features/home/presentation/screens/home_screen.dart';
import 'package:prashant/features/study/presentation/screens/study_screen.dart';
import 'package:prashant/features/social/presentation/screens/social_screen.dart';
import 'package:prashant/features/wellbeing/presentation/screens/wellbeing_screen.dart';
import 'package:prashant/features/profile/presentation/screens/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StudyScreen(),
    const SocialScreen(),
    const WellbeingScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Basic Upgrader setup for stability
    final upgrader = Upgrader(
      debugDisplayAlways: false,
      durationUntilAlertAgain: const Duration(hours: 1),
    );

    return UpgradeAlert(
      upgrader: upgrader,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer), label: 'Study'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Social'),
            NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
