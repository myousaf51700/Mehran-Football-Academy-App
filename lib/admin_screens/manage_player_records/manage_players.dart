import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:mehran_football_academy/admin_screens/admin_dashboard.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'PlayerDetailScreen.dart';

class ManagePlayers extends StatefulWidget {
  const ManagePlayers({super.key});

  @override
  State<ManagePlayers> createState() => _ManagePlayersState();
}

class _ManagePlayersState extends State<ManagePlayers> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _players = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final response = await _supabase
          .from('players_records')
          .select('*')
          .neq('user_id', currentUser.id);

      setState(() {
        _players = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load players: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showMenuOptions(BuildContext context, Map<String, dynamic> player, Offset offset) async {
    final RenderBox overlay = Overlay.of(context)!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(offset, offset),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'view',
          child: Text('View'),
        ),
        PopupMenuItem<String>(
          value: 'make_admin',
          child: Text('Make Admin'),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Text('Delete'),
        ),
      ],
      elevation: 8.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.blueGrey.withOpacity(0.2), width: 1),
      ),
      color: Colors.white.withOpacity(0.95),
    );

    if (selected == null || !mounted) return;

    switch (selected) {
      case 'view':
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlayerDetailScreen(player: player),
            ),
          );
        }
        break;

      case 'make_admin':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Make Admin'),
            content: Text('Are you sure you want to make ${player['full_name'] ?? 'this player'} an admin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          setState(() => _isLoading = true);

          try {
            final userEmail = player['email'];
            if (userEmail == null || userEmail.isEmpty) {
              throw Exception('Missing email for this player');
            }

            final existingUserType = await _supabase
                .from('user_type')
                .select()
                .eq('email', userEmail)
                .maybeSingle();

            if (existingUserType == null) {
              await _supabase.from('user_type').insert({
                'email': userEmail,
                'role': 'admin',
                'user_id': player['user_id'],
              });
            } else {
              await _supabase
                  .from('user_type')
                  .update({'role': 'admin'})
                  .eq('email', userEmail);
            }

            await _fetchPlayers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${player['full_name'] ?? 'Player'} has been made an admin.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _errorMessage = 'Failed to make admin: $e');
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
        break;

      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: Text('Are you sure you want to delete ${player['full_name'] ?? 'this player'}? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          setState(() => _isLoading = true);

          try {
            final userId = player['user_id'];
            final userEmail = player['email'] ?? '';
            if (userId == null || userEmail.isEmpty) {
              throw Exception('Missing user ID or email');
            }

            // Call the Edge Function to delete the user
            final response = await http.post(
              Uri.parse('https://<your-project-ref>.supabase.co/functions/v1/delete-user'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer <your-supabase-anon-key>',
              },
              body: jsonEncode({'userId': userId, 'email': userEmail}),
            );

            final result = jsonDecode(response.body);
            if (response.statusCode != 200) {
              throw Exception(result['error'] ?? 'Failed to delete user');
            }

            await _fetchPlayers();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Player deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            String errorMessage = e.toString();
            if (errorMessage.contains('Forbidden')) {
              errorMessage = 'Only admins can delete players.';
            } else if (errorMessage.contains('No valid session')) {
              errorMessage = 'Session expired. Please log in again.';
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            }
            if (mounted) setState(() => _errorMessage = errorMessage);
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 26,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 10.0),
                    child: Text(
                      'Academy Players',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            _players.isEmpty
                ? const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No players found.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: player['profile_url'] != null &&
                            player['profile_url'].isNotEmpty
                            ? NetworkImage(player['profile_url'])
                            : const AssetImage('assets/profile.jpg')
                        as ImageProvider,
                        backgroundColor: Colors.grey[300],
                      ),
                      title: Text(
                        player['full_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            'Email: ${player['email'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                          Text(
                            'Contact: ${player['contact_number'] ?? 'N/A'}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                      trailing: GestureDetector(
                        onTapDown: (details) =>
                            _showMenuOptions(context, player, details.globalPosition),
                        child: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF42A5F5),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}