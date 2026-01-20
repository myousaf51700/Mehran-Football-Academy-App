import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mehran_football_academy/admin_screens/admin_dashboard.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/admin_media.dart';
import 'package:mehran_football_academy/chat_module/chat_home_screen.dart';
import 'package:mehran_football_academy/my_components/my_drawers.dart';
import 'package:mehran_football_academy/my_components/admin_fab_menu.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/make_announcement.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/admin_uploads.dart';
import '../admin_screens/uploading_module/schedule_match.dart';
import '../players_screens/sport_data/sport_news/NewsHomeScreen.dart';

class AdminNavBar extends StatefulWidget {
  const AdminNavBar({super.key});

  @override
  State<AdminNavBar> createState() => _AdminNavBarState();
}

class _AdminNavBarState extends State<AdminNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboard(),
    const AdminMedia(),
    const Newshomescreen(),
    const ChatHomeScreen(),
  ];

  final List<Type> _navBarScreens = [
    AdminDashboard,
    AdminMedia,
    Newshomescreen,
    ChatHomeScreen,
  ];

  void _onFileTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UploadImage()),
    );
  }

  void _onAnnouncementTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MakeAnnouncement()),
    );
  }

  void _onMatchTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScheduleMatch()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentScreenType = _screens[_selectedIndex].runtimeType;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: currentScreenType == AdminDashboard ? const AdminDrawer() : null,
      body: _screens[_selectedIndex],
      bottomNavigationBar: _navBarScreens.contains(currentScreenType)
          ? Container(
        height: 55,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          child: GNav(
            gap: 4, // Reduced gap for a more compact look
            duration: const Duration(milliseconds: 500),
            backgroundColor: Colors.white,
            color: Colors.black,
            activeColor: Colors.black,
            tabBackgroundColor: Colors.green.shade100, // Lighter shade for a subtle effect
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding for smaller circle
            iconSize: 24, // Adjust icon size to match WhatsApp
            textStyle: const TextStyle(fontSize: 12), // Smaller text to fit the compact design
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
      )
          : null,
      floatingActionButton: currentScreenType == AdminDashboard
          ? AdminFabMenu(
        onFileTap: _onFileTap,
        onAnnouncementTap: _onAnnouncementTap,
        onMatchTap: _onMatchTap,
      )
          : null,
    );
  }
}