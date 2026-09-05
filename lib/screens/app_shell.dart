import 'package:flutter/material.dart';

import 'circle_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const pages = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    CircleScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111715),
            borderRadius: BorderRadius.circular(27),
            boxShadow: const [
              BoxShadow(color: Color(0x26112320), blurRadius: 28, offset: Offset(0, 12)),
            ],
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            height: 68,
            destinations: [
              _destination(Icons.home_rounded, Icons.home_outlined, 'Home'),
              _destination(Icons.explore_rounded, Icons.explore_outlined, 'TripVerse'),
              _destination(Icons.group_rounded, Icons.group_outlined, 'Circle'),
              _destination(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Inbox'),
              _destination(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _destination(IconData selected, IconData normal, String label) {
    return NavigationDestination(
      label: label,
      icon: Icon(normal, color: Colors.white70, size: 27),
      selectedIcon: Icon(selected, color: const Color(0xFF173D36), size: 27),
    );
  }
}
