import 'package:flutter/material.dart';

class StatsDetailedScreen extends StatelessWidget {
  final Map<String, dynamic> player;

  const StatsDetailedScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final positionSpecificStats = (player['position_specific_stats'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Player Details',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'RubikRegular',
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            color: Colors.grey.shade100,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      player['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'RubikRegular',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      player['position'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'RubikRegular',
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.grey),
                  _buildStatRow('Goals', player['total_goals']?.toString() ?? '0'),
                  _buildStatRow('Assists', player['total_assists']?.toString() ?? '0'),
                  _buildStatRow('Matches Played', player['matches_played']?.toString() ?? '0'),
                  _buildStatRow('Minutes Played', player['minutes_played']?.toString() ?? '0'),
                  _buildStatRow('Red Cards', player['red_card_received']?.toString() ?? '0'),
                  _buildStatRow('Yellow Cards', player['yellow_card_received']?.toString() ?? '0'),
                  const SizedBox(height: 16),
                  const Text(
                    'Position Specific Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'RubikRegular',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...positionSpecificStats.entries.map((entry) {
                    return _buildStatRow(entry.key, entry.value?.toString() ?? '0');
                  }).toList(),
                  if (positionSpecificStats.isEmpty)
                    const Text(
                      'No position-specific stats available.',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'RubikRegular',
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'RubikRegular',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}