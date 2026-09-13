import 'package:flutter/material.dart';

import 'ai_chat_screen.dart';
import 'biography_screen.dart';
import 'category_screen.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'market_screen.dart';

/// Top-level scaffold holding the 6-item bottom navigation bar:
/// Home, Monitor, Market, AI, Category, Biography.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigate: _goTo),
      const DashboardScreen(),
      const MarketScreen(),
      const AiChatScreen(),
      const CategoryScreen(),
      const BiographyScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _goTo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor_heart), label: 'Monitor'),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Category'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Biography'),
        ],
      ),
    );
  }
}
