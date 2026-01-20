import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/add_player_emails.dart';
import 'package:mehran_football_academy/admin_screens/manage_stats/statistics_home.dart';
import 'package:mehran_football_academy/admin_screens/profile_screens/admin_profile.dart';
import 'package:mehran_football_academy/admin_screens/manage_fee/fee_home_screen.dart';
import 'package:mehran_football_academy/admin_screens/manage_player_records/manage_players.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/matches_records.dart';
import 'package:mehran_football_academy/auth_screens/login_screen.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:mehran_football_academy/players_screens/player_profile.dart';
import 'package:mehran_football_academy/players_screens/player_statistics.dart';
import 'package:mehran_football_academy/players_screens/playing_eleven.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../players_screens/fee_related_screens/fee_section_screen.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _fullName;
  String? _profileUrl;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load from cache first
    setState(() {
      _fullName = prefs.getString('admin_full_name');
      _profileUrl = prefs.getString('admin_profile_url');
      _email = prefs.getString('admin_email');
    });

    // If we have all cached data, return early
    if (_fullName != null && _profileUrl != null && _email != null) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('players_records')
          .select('full_name, profile_url')
          .eq('user_id', user.id)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first;
        final newFullName = data['full_name'] ?? 'Admin Name';
        final newProfileUrl = data['profile_url'];
        final newEmail = user.email ?? 'admin@example.com';

        // Update cache
        await prefs.setString('admin_full_name', newFullName);
        await prefs.setString('admin_profile_url', newProfileUrl ?? '');
        await prefs.setString('admin_email', newEmail);

        setState(() {
          _fullName = newFullName;
          _profileUrl = newProfileUrl;
          _email = newEmail;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load admin data: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_full_name');
    await prefs.remove('admin_profile_url');
    await prefs.remove('admin_email');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _fullName ?? 'Admin Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              _email ?? 'admin@example.com',
              style: const TextStyle(fontSize: 16),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.orange,
              backgroundImage: _profileUrl != null && _profileUrl!.isNotEmpty
                  ? NetworkImage(_profileUrl!)
                  : null,
              child: _profileUrl == null || _profileUrl!.isEmpty
                  ? const Text(
                'A',
                style: TextStyle(fontSize: 30, color: Colors.white),
              )
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.blue),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: const Text(
              'Personal Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => AdminProfile()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts, color: Colors.blue),
            title: const Text(
              'Manage Players',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => ManagePlayers()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment, color: Colors.blue),
            title: const Text(
              'Academy Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => StatisticsHome()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_soccer_sharp, color: Colors.blue),
            title: const Text(
              'Matches',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => MatchesRecords()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.blue),
            title: const Text(
              'Fee Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => FeeHomeScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.blue),
            title: const Text(
              'Add Players',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlayerEmails()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.blue),
            title: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            onTap: () async {
              try {
                await _authService.signOut();
                await _clearCache();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class PlayerDrawer extends StatefulWidget {
  const PlayerDrawer({super.key});

  @override
  State<PlayerDrawer> createState() => _PlayerDrawerState();
}

class _PlayerDrawerState extends State<PlayerDrawer> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _fullName;
  String? _profileUrl;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    final prefs = await SharedPreferences.getInstance();

    // Try to load from cache first
    setState(() {
      _fullName = prefs.getString('player_full_name');
      _profileUrl = prefs.getString('player_profile_url');
      _email = prefs.getString('player_email');
    });

    // If we have all cached data, return early
    if (_fullName != null && _profileUrl != null && _email != null) return;

    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      final response = await _supabase
          .from('players_records')
          .select('full_name, profile_url')
          .eq('user_id', user.id)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first;
        final newFullName = data['full_name'] ?? 'Player Name';
        final newProfileUrl = data['profile_url'];
        final newEmail = user.email ?? 'player@example.com';

        // Update cache
        await prefs.setString('player_full_name', newFullName);
        await prefs.setString('player_profile_url', newProfileUrl ?? '');
        await prefs.setString('player_email', newEmail);

        setState(() {
          _fullName = newFullName;
          _profileUrl = newProfileUrl;
          _email = newEmail;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load player data: $e')),
      );
    }
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('player_full_name');
    await prefs.remove('player_profile_url');
    await prefs.remove('player_email');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _fullName ?? 'Player Name',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(
              _email ?? 'player@example.com',
              style: const TextStyle(fontSize: 16),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.green,
              backgroundImage: _profileUrl != null && _profileUrl!.isNotEmpty
                  ? NetworkImage(_profileUrl!)
                  : null,
              child: _profileUrl == null || _profileUrl!.isEmpty
                  ? const Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              )
                  : null,
            ),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.black),
            title: const Text(
              'Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerProfile()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.black),
            title: const Text(
              'Fee Section',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              final user = _authService.getCurrentUser();
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in to access the Fee Section')),
                );
                Navigator.pushReplacementNamed(context, '/login');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FeeSectionScreen(userId: user.id),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.money, color: Colors.black),
            title: const Text(
              'Statistics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerStatistics()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_gymnastics, color: Colors.black),
            title: const Text(
              'Academy Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => PlayingEleven()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.sports_soccer_sharp, color: Colors.black),
            title: const Text(
              'Matches',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => MatchesRecords()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.black),
            title: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await _authService.signOut();
              await _clearCache();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}