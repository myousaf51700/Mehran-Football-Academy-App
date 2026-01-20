import 'dart:async';
import 'dart:convert'; // For deep copying
import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/manage_stats/stats_detailed_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsHome extends StatefulWidget {
  const StatisticsHome({super.key});

  @override
  State<StatisticsHome> createState() => _StatisticsHomeState();
}

class _StatisticsHomeState extends State<StatisticsHome> {
  List<Map<String, dynamic>> _allPlayers = [];
  List<Map<String, dynamic>> _editedPlayers = [];
  List<Map<String, dynamic>> _filteredPlayers = []; // New list for filtered players
  bool _isLoading = false;
  bool _isEditing = false;
  String? _errorMessage;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _incrementTimer;
  Timer? _decrementTimer;
  final TextEditingController _searchController = TextEditingController(); // Controller for search input

  final List<String> _positions = [
    'All Players',
    'Playing Eleven',
    'Striker',
    'Midfielder',
    'Defender',
    'Goalkeeper',
  ];

  @override
  void initState() {
    super.initState();
    _fetchAllPlayers();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
        _filterPlayers(_searchController.text); // Reapply filter when switching tabs
      });
    });

    // Add listener for search input
    _searchController.addListener(() {
      _filterPlayers(_searchController.text);
    });
  }

  Future<void> _fetchAllPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.from('player_statistics').select();
      print('Fetched players: $response');
      setState(() {
        _allPlayers = List<Map<String, dynamic>>.from(response);
        // Create a deep copy of _allPlayers for _editedPlayers
        _editedPlayers = _allPlayers.map((player) => jsonDecode(jsonEncode(player)) as Map<String, dynamic>).toList();
        _filteredPlayers = List<Map<String, dynamic>>.from(_allPlayers); // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load players: $e';
        _isLoading = false;
      });
    }
  }

  // Method to filter players based on search query
  void _filterPlayers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlayers = List<Map<String, dynamic>>.from(_allPlayers);
      } else {
        _filteredPlayers = _allPlayers
            .where((player) =>
        player['full_name']
            ?.toString()
            .toLowerCase()
            .contains(query.toLowerCase()) ??
            false)
            .toList();
      }
    });
  }

  Future<void> _updatePlayingElevenStatus(String playerId, bool newStatus) async {
    final user = Supabase.instance.client.auth.currentUser;
    print('Authenticated user: $user');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Authenticated user ID: ${user.id}, Updating player with ID: $playerId, new playing_eleven status: $newStatus');
    try {
      final response = await Supabase.instance.client
          .from('player_statistics')
          .update({'playing_eleven': newStatus})
          .eq('id', playerId)
          .select();

      if (response.isEmpty) {
        throw Exception('No rows updated. Check if the player ID exists: $playerId');
      }

      await _fetchAllPlayers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Player added to Playing Eleven' : 'Player removed from Playing Eleven',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error during update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updatePlayerRecords() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      int updatedCount = 0;
      for (int i = 0; i < _editedPlayers.length; i++) {
        final editedPlayer = _editedPlayers[i];
        final originalPlayer = _allPlayers[i];

        // Compare common attributes
        Map<String, dynamic> updateData = {};
        if ((editedPlayer['matches_played'] as int? ?? 0) != (originalPlayer['matches_played'] as int? ?? 0)) {
          updateData['matches_played'] = editedPlayer['matches_played'];
        }
        if ((editedPlayer['minutes_played'] as int? ?? 0) != (originalPlayer['minutes_played'] as int? ?? 0)) {
          updateData['minutes_played'] = editedPlayer['minutes_played'];
        }
        if ((editedPlayer['red_card_received'] as int? ?? 0) != (originalPlayer['red_card_received'] as int? ?? 0)) {
          updateData['red_card_received'] = editedPlayer['red_card_received'];
        }
        if ((editedPlayer['yellow_card_received'] as int? ?? 0) != (originalPlayer['yellow_card_received'] as int? ?? 0)) {
          updateData['yellow_card_received'] = editedPlayer['yellow_card_received'];
        }
        if ((editedPlayer['total_goals'] as int? ?? 0) != (originalPlayer['total_goals'] as int? ?? 0)) {
          updateData['total_goals'] = editedPlayer['total_goals'];
        }
        if ((editedPlayer['total_assists'] as int? ?? 0) != (originalPlayer['total_assists'] as int? ?? 0)) {
          updateData['total_assists'] = editedPlayer['total_assists'];
        }

        // Compare position-specific stats
        final editedStats = (editedPlayer['position_specific_stats'] as Map<String, dynamic>?) ?? {};
        final originalStats = (originalPlayer['position_specific_stats'] as Map<String, dynamic>?) ?? {};
        Map<String, dynamic> updatedStats = {};

        // Check for changes in position-specific stats
        editedStats.forEach((key, value) {
          final originalValue = originalStats[key];
          if ((value as int? ?? 0) != (originalValue as int? ?? 0)) {
            updatedStats[key] = value;
          }
        });

        // Check for keys that exist in originalStats but not in editedStats
        originalStats.forEach((key, value) {
          if (!editedStats.containsKey(key) && value != null) {
            updatedStats[key] = 0; // Reset to 0 if the key was removed
          }
        });

        if (updatedStats.isNotEmpty) {
          updateData['position_specific_stats'] = editedStats; // Update the entire map
        }

        print('Player ${editedPlayer['id']}: updateData=$updateData');

        if (updateData.isNotEmpty) {
          if (editedPlayer['id'] == null) {
            throw Exception('Player ID is null for edited player at index $i');
          }

          final response = await Supabase.instance.client
              .from('player_statistics')
              .update(updateData)
              .eq('id', editedPlayer['id'])
              .select();

          print('Update response for player ${editedPlayer['id']}: $response');

          if (response.isEmpty) {
            throw Exception('No rows updated for player ID ${editedPlayer['id']}. Check if the ID exists in the table.');
          }

          updatedCount++;
        }
      }

      if (updatedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No changes detected to update.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _fetchAllPlayers();
        setState(() {
          _isEditing = false;
          _currentPage = 1; // Move to "Playing Eleven" tab
        });
        _pageController.jumpToPage(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated $updatedCount player records successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error during bulk update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update records: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startIncrement(Map<String, dynamic> player, String key, {bool isMinutesPlayed = false, String? subKey}) {
    _incrementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        int incrementValue = isMinutesPlayed ? 5 : 1;
        if (subKey != null) {
          final map = (player[key] as Map<String, dynamic>?) ?? {};
          int currentValue = (map[subKey] as int?) ?? 0;
          map[subKey] = currentValue + incrementValue;
          player[key] = map;
          print('Incremented $subKey to ${map[subKey]} for player ${player['id']}');
        } else {
          player[key] = (player[key] as int? ?? 0) + incrementValue;
          print('Incremented $key to ${player[key]} for player ${player['id']}');
        }
      });
    });
  }

  void _startDecrement(Map<String, dynamic> player, String key, {bool isMinutesPlayed = false, String? subKey}) {
    _decrementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        int decrementValue = isMinutesPlayed ? 5 : 1;
        if (subKey != null) {
          final map = (player[key] as Map<String, dynamic>?) ?? {};
          int currentValue = (map[subKey] as int?) ?? 0;
          if (currentValue >= decrementValue) {
            map[subKey] = currentValue - decrementValue;
          } else {
            map[subKey] = 0;
          }
          player[key] = map;
          print('Decremented $subKey to ${map[subKey]} for player ${player['id']}');
        } else {
          int currentValue = player[key] as int? ?? 0;
          if (currentValue >= decrementValue) {
            player[key] = currentValue - decrementValue;
          } else {
            player[key] = 0;
          }
          print('Decremented $key to ${player[key]} for player ${player['id']}');
        }
      });
    });
  }

  void _stopTimer() {
    _incrementTimer?.cancel();
    _decrementTimer?.cancel();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose(); // Dispose the search controller
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Players Statistics',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'RubikRegular',
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  fontFamily: 'RubikRegular',
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.grey,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Position Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPositionButton(context, 'All Players', 0),
                  const SizedBox(width: 10),
                  _buildPositionButton(context, 'Playing Eleven', 1),
                  const SizedBox(width: 10),
                  _buildPositionButton(context, 'Striker', 2),
                  const SizedBox(width: 10),
                  _buildPositionButton(context, 'Midfielder', 3),
                  const SizedBox(width: 10),
                  _buildPositionButton(context, 'Defender', 4),
                  const SizedBox(width: 10),
                  _buildPositionButton(context, 'Goalkeeper', 5),
                ],
              ),
            ),
          ),
          // Player List
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: _positions.map((position) {
                return _buildPlayerList(position);
              }).toList(),
            ),
          ),
          // Edit/Confirm Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        // Create a deep copy when canceling edit
                        _editedPlayers = _allPlayers.map((player) => jsonDecode(jsonEncode(player)) as Map<String, dynamic>).toList();
                        _filterPlayers(_searchController.text); // Reapply filter after resetting
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    _isEditing ? 'Cancel Edit' : 'Update',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'RubikRegular',
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _updatePlayerRecords,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'RubikRegular',
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionButton(BuildContext context, String position, int pageIndex) {
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: _currentPage == pageIndex ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          position,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'RubikRegular',
            color: _currentPage == pageIndex ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerList(String position) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_filteredPlayers.isEmpty) {
      return const Center(child: Text('No players found.'));
    }

    List<Map<String, dynamic>> filteredPlayers;
    if (position == 'All Players') {
      filteredPlayers = _filteredPlayers;
    } else if (position == 'Playing Eleven') {
      filteredPlayers = _filteredPlayers.where((player) => player['playing_eleven'] == true).toList();
    } else {
      filteredPlayers = _filteredPlayers.where((player) => player['position'] == position).toList();
    }

    if (filteredPlayers.isEmpty) {
      return Center(child: Text('No $position found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: filteredPlayers.length,
        itemBuilder: (context, index) {
          final player = filteredPlayers[index];
          final bool isInPlayingEleven = player['playing_eleven'] == true;

          // Find the index in _editedPlayers by matching the player's id
          final editedIndex = _editedPlayers.indexWhere((p) => p['id'] == player['id']);
          if (_isEditing && editedIndex == -1) {
            // This should not happen, but handle it gracefully
            return const Center(child: Text('Error: Player not found in edited list.'));
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatsDetailedScreen(player: player),
                ),
              );
            },
            onLongPress: () {
              _showPlayingElevenOptions(player, isInPlayingEleven);
            },
            child: _isEditing ? _buildEditableCard(editedIndex) : _buildSimpleCard(player),
          );
        },
      ),
    );
  }

  Widget _buildSimpleCard(Map<String, dynamic> player) {
    return Card(
      elevation: 2,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          player['full_name'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'RubikRegular',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          player['position'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'RubikRegular',
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableCard(int index) {
    final player = _editedPlayers[index];
    final positionSpecificStats = (player['position_specific_stats'] as Map<String, dynamic>?) ?? {};

    return Card(
      elevation: 2,
      color: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                player['full_name'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'RubikRegular',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                player['position'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'RubikRegular',
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildEditableStatRow('Goals', player, 'total_goals'),
            _buildEditableStatRow('Assists', player, 'total_assists'),
            _buildEditableStatRow('Matches', player, 'matches_played'),
            _buildEditableStatRow('T.Played', player, 'minutes_played', isMinutesPlayed: true),
            _buildEditableStatRow('R.Cards', player, 'red_card_received'),
            _buildEditableStatRow('Y.Cards', player, 'yellow_card_received'),
            const SizedBox(height: 8),
            const Text(
              'Position Specific Stats',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'RubikRegular',
                fontWeight: FontWeight.bold,
              ),
            ),
            ...positionSpecificStats.entries.map((entry) {
              return _buildEditableStatRow(entry.key, player, 'position_specific_stats', subKey: entry.key);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableStatRow(String label, Map<String, dynamic> player, String key, {String? subKey, bool isMinutesPlayed = false}) {
    int value;
    if (subKey != null) {
      final map = (player[key] as Map<String, dynamic>?) ?? {};
      value = (map[subKey] as int?) ?? 0;
    } else {
      value = (player[key] as int?) ?? 0;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'RubikRegular',
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    int decrementValue = isMinutesPlayed ? 5 : 1;
                    if (value >= decrementValue) {
                      if (subKey != null) {
                        (player[key] as Map<String, dynamic>)[subKey] = value - decrementValue;
                        print('Tapped: Decremented $subKey to ${(player[key] as Map<String, dynamic>)[subKey]} for player ${player['id']}');
                      } else {
                        player[key] = value - decrementValue;
                        print('Tapped: Decremented $key to ${player[key]} for player ${player['id']}');
                      }
                    } else {
                      if (subKey != null) {
                        (player[key] as Map<String, dynamic>)[subKey] = 0;
                        print('Tapped: Decremented $subKey to 0 for player ${player['id']}');
                      } else {
                        player[key] = 0;
                        print('Tapped: Decremented $key to 0 for player ${player['id']}');
                      }
                    }
                  });
                },
                onLongPressStart: (_) => _startDecrement(player, key, isMinutesPlayed: isMinutesPlayed, subKey: subKey),
                onLongPressEnd: (_) => _stopTimer(),
                child: const Icon(
                  Icons.remove_circle,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'RubikRegular',
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    int incrementValue = isMinutesPlayed ? 5 : 1;
                    if (subKey != null) {
                      (player[key] as Map<String, dynamic>)[subKey] = value + incrementValue;
                      print('Tapped: Incremented $subKey to ${(player[key] as Map<String, dynamic>)[subKey]} for player ${player['id']}');
                    } else {
                      player[key] = value + incrementValue;
                      print('Tapped: Incremented $key to ${player[key]} for player ${player['id']}');
                    }
                  });
                },
                onLongPressStart: (_) => _startIncrement(player, key, isMinutesPlayed: isMinutesPlayed, subKey: subKey),
                onLongPressEnd: (_) => _stopTimer(),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlayingElevenOptions(Map<String, dynamic> player, bool isInPlayingEleven) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          player['full_name'] ?? 'Unknown',
          style: const TextStyle(fontFamily: 'RubikRegular'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                isInPlayingEleven ? 'Remove from Playing 11' : 'Add to Playing 11',
                style: const TextStyle(fontFamily: 'RubikRegular'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _updatePlayingElevenStatus(player['id'].toString(), !isInPlayingEleven);
              },
            ),
          ],
        ),
      ),
    );
  }
}