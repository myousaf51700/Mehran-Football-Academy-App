import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/players_screens/player_stats/stats_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlayerStatistics extends StatefulWidget {
  const PlayerStatistics({super.key});

  @override
  State<PlayerStatistics> createState() => _PlayerStatisticsState();
}

class _PlayerStatisticsState extends State<PlayerStatistics> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? playerStats;
  Map<String, dynamic>? playerProfile;
  bool isLoading = true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedStats = prefs.getString('player_stats');
    final cachedProfile = prefs.getString('player_profile');

    if (cachedStats != null && cachedProfile != null) {
      setState(() {
        playerStats = jsonDecode(cachedStats);
        playerProfile = jsonDecode(cachedProfile);
        isLoading = false;
      });
    } else {
      await _fetchPlayerData();
    }
  }

  Future<void> _fetchPlayerData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch player statistics
      final statsResponse = await _supabase
          .from('player_statistics')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      // Fetch player profile (full name and profile URL)
      final profileResponse = await _supabase
          .from('players_records')
          .select('full_name, profile_url')
          .eq('user_id', user.id)
          .single();

      if (statsResponse != null) {
        // Cache the data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('player_stats', jsonEncode(statsResponse));
        await prefs.setString('player_profile', jsonEncode(profileResponse));

        setState(() {
          playerStats = statsResponse;
          playerProfile = profileResponse;
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No statistics found for this player')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching stats: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white60, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            key: _refreshIndicatorKey,
            onRefresh: _fetchPlayerData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Player Profile Section
                    if (playerProfile != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: playerProfile!['profile_url'] != null &&
                              playerProfile!['profile_url'].isNotEmpty
                              ? NetworkImage(playerProfile!['profile_url'])
                              : const AssetImage('assets/profile.jpg') as ImageProvider,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          playerProfile!['full_name'] ?? 'Unknown Player',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Rubik',
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          playerStats?['position'] ?? 'Position: N/A',
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    // Loading Indicator or Stats
                    isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                        : playerStats == null
                        ? Center(
                      child: Text(
                        'No statistics available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontFamily: 'Rubik',
                        ),
                      ),
                    )
                        : Column(
                      children: [
                        // Key Statistics Grid
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Key Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildStatCard(
                              title: 'Goals',
                              value: playerStats!['total_goals'].toString(),
                              icon: Icons.sports_soccer,
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrangeAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            _buildStatCard(
                              title: 'Assists',
                              value: playerStats!['total_assists'].toString(),
                              icon: Icons.handshake,
                              gradient: const LinearGradient(
                                colors: [Colors.green, Colors.greenAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            _buildStatCard(
                              title: 'Matches',
                              value: playerStats!['matches_played'].toString(),
                              icon: Icons.event,
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.blueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            _buildStatCard(
                              title: 'Minutes',
                              value: playerStats!['minutes_played'].toString(),
                              icon: Icons.timer,
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Disciplinary Stats
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Disciplinary Record (Cards)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Red Cards',
                                value: playerStats!['red_card_received'].toString(),
                                icon: Icons.rectangle,
                                iconColor: Colors.red,
                                gradient: const LinearGradient(
                                  colors: [Colors.grey, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Yellow Cards',
                                value: playerStats!['yellow_card_received'].toString(),
                                icon: Icons.rectangle,
                                iconColor: Colors.yellow,
                                gradient: const LinearGradient(
                                  colors: [Colors.grey, Colors.white],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Position-Specific Stats
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Position-Specific Stats',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPositionSpecificCard(
                          position: playerStats!['position'],
                          stats: playerStats!['position_specific_stats'],
                          gradient: const LinearGradient(
                            colors: [Colors.grey, Colors.white12],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    required LinearGradient gradient,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Rubik',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionSpecificCard({
    required String position,
    required Map<String, dynamic> stats,
    required LinearGradient gradient,
  }) {
    final calculator = StatsCalculator(playerStats!);
    final positionStats = calculator.getPositionSpecificStats(position, stats);

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$position Statistics'.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'RubikMedium',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: positionStats.map((stat) {
                final isTitle = stat['value']!.isEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            stat['title']!,
                            style: TextStyle(
                              fontFamily: isTitle ? 'RubikMedium' : 'RubikRegular',
                              fontWeight: FontWeight.bold,
                              fontSize: isTitle ? 20 : 16,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          if (!isTitle)
                            Flexible(
                              child: Text(
                                stat['value']!,
                                style: const TextStyle(
                                  fontFamily: 'RubikRegular',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isTitle) const SizedBox(height: 1),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}