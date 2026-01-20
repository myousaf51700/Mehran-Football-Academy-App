import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mehran_football_academy/my_media/my_media.dart';
import 'package:mehran_football_academy/players_screens/player_dashboard.dart';
import 'package:mehran_football_academy/players_screens/sport_data/sport_news/NewsHomeScreen.dart';
import 'package:mehran_football_academy/chat_module/chat_home_screen.dart';
import 'package:mehran_football_academy/my_components/my_drawers.dart';
class PlayerNavBar extends StatefulWidget {
  const PlayerNavBar({super.key});

  @override
  State<PlayerNavBar> createState() => _PlayerNavBarState();
}

class _PlayerNavBarState extends State<PlayerNavBar> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  final List<Type> _navBarScreens = [
    PlayerDashboard,
    MyMedia,
    Newshomescreen,
    ChatHomeScreen,
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      const PlayerDashboard(),
      const MyMedia(),
      const Newshomescreen(),
      const ChatHomeScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentScreenType = _navBarScreens[_selectedIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: currentScreenType == PlayerDashboard ? const PlayerDrawer() : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 55,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          child: GNav(
            gap: 4,
            duration: const Duration(milliseconds: 500),
            backgroundColor: Colors.white,
            color: Colors.black,
            activeColor: Colors.black,
            tabBackgroundColor: Colors.green.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            iconSize: 24,
            textStyle: const TextStyle(fontSize: 12),
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            tabs: const [
              GButton(icon: Icons.dashboard_outlined, text: 'Home'),
              GButton(icon: Icons.video_collection_outlined, text: 'Media'),
              GButton(icon: Icons.sports_soccer, text: 'News'),
              GButton(icon: Icons.chat_bubble_outline, text: 'Chats'),
            ],
          ),
        ),
      ),
    );
  }
}