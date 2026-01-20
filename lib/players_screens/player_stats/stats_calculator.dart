import 'package:flutter/material.dart';

// Class to handle rate calculations for different positions
class StatsCalculator {
  final Map<String, dynamic> playerStats;

  StatsCalculator(this.playerStats);

  // Helper method to calculate rate (percentage)
  String _calculateRate(int numerator, int denominator, {int decimalPlaces = 1}) {
    if (denominator <= 0) return '0.0%';
    return '${((numerator / denominator) * 100).toStringAsFixed(decimalPlaces)}%';
  }

  // Helper method to calculate per-match value
  String _calculatePerMatch(int value, int matches, {int decimalPlaces = 1}) {
    if (matches <= 0) return '0.0';
    return (value / matches).toStringAsFixed(decimalPlaces);
  }

  // Get position-specific stats with calculated rates
  List<Map<String, String>> getPositionSpecificStats(String position, Map<String, dynamic> positionStats) {
    final matchesPlayed = playerStats['matches_played'] ?? 0;

    switch (position) {
      case 'Striker':
        return [
          {'title': 'Headed Goals', 'value': positionStats['headed_goals'].toString()},
          {'title': 'Shots', 'value': ''},
          {'title': 'Shots Attempted', 'value': positionStats['shots_attempted'].toString()},
          {'title': 'Shots on Target', 'value': positionStats['shots_on_target'].toString()},
          {
            'title': 'Shots Accuracy (per match)',
            'value': positionStats['shots_attempted'] > 0
                ? _calculateRate(positionStats['shots_on_target'], positionStats['shots_attempted'])
                : '0.0%'
          },
          {'title': 'Penalties', 'value': ''},
          {'title': 'Taken', 'value': positionStats['penalties_taken'].toString()},
          {'title': 'Scored', 'value': positionStats['penalties_scored'].toString()},
        ];
      case 'Midfielder':
        return [
          {'title': 'Key Passes', 'value': ''},
          {'title': 'Key Passes (Per match)', 'value': _calculatePerMatch(positionStats['key_passes'], matchesPlayed)},
          {
            'title': 'Passing Rate',
            'value': _calculateRate(positionStats['key_passes'], matchesPlayed)
          },
          {'title': 'Chance Created', 'value': ''},
          {
            'title': 'Chances Created (per match)',
            'value': _calculatePerMatch(positionStats['chances_created'], matchesPlayed)
          },
          {
            'title': 'Chances Creating Rate',
            'value': _calculateRate(positionStats['chances_created'], matchesPlayed)
          },
          {'title': 'Crossing', 'value': ''},
          {
            'title': 'Crosses (per match)',
            'value': _calculatePerMatch(positionStats['total_crosses'], matchesPlayed)
          },
          {
            'title': 'Crossing Rate',
            'value': _calculateRate(positionStats['total_crosses'], matchesPlayed)
          },
          {'title': 'Ball Recoveries', 'value': ''},
          {
            'title': 'Recoveries Made (per match)',
            'value': _calculatePerMatch(positionStats['ball_recoveries'], matchesPlayed)
          },
          {
            'title': 'Recovery Rate',
            'value': _calculateRate(positionStats['ball_recoveries'], matchesPlayed)
          },
          {'title': 'Dribbling', 'value': ''},
          {
            'title': 'Completed Dribbles (per match)',
            'value': _calculatePerMatch(positionStats['dribbles_completed'], matchesPlayed)
          },
          {
            'title': 'Dribbling Rate',
            'value': _calculateRate(positionStats['dribbles_completed'], matchesPlayed)
          },
          {'title': 'Successive Tackles', 'value': ''},
          {
            'title': 'Tackles made (per match)',
            'value': _calculatePerMatch(positionStats['tackles_made'], matchesPlayed)
          },
          {
            'title': 'Tackling Rate',
            'value': _calculateRate(positionStats['tackles_made'], matchesPlayed)
          },
        ];
      case 'Defender':
        return [
          {'title': 'Interceptions', 'value': ''},
          {'title': 'Total Interceptions', 'value': positionStats['interceptions'].toString()},
          {
            'title': 'Interceptions (per match)',
            'value': _calculatePerMatch(positionStats['interceptions'], matchesPlayed)
          },
          {'title': 'Blocks Inside Box', 'value': ''},
          {'title': 'Total Blocks', 'value': positionStats['blocks_inside_box'].toString()},
          {
            'title': 'Blocking Rate',
            'value': _calculateRate(positionStats['blocks_inside_box'], matchesPlayed)
          },
          {'title': 'Successive Tackles', 'value': ''},
          {
            'title': 'Total made',
            'value': positionStats['successive_tackles_made'].toString()
          },
          {
            'title': 'Tackling Rate',
            'value': _calculateRate(positionStats['successive_tackles_made'], matchesPlayed)
          },
        ];
      case 'Goalkeeper':
        return [
          {'title': 'SAVING RATE', 'value': ''},
          {'title': 'TOTAL SAVES', 'value': positionStats['total_saves'].toString()},
          {
            'title': 'SAVES RATING',
            'value': _calculateRate(positionStats['total_saves'], matchesPlayed)
          },
          {'title': 'CLEAN SHEET', 'value': positionStats['clean_sheets'].toString()},
          {'title': 'GOALS CONCEDED', 'value': positionStats['goals_conceded'].toString()}, // Fixed: Now a standalone title with value
          {'title': 'PENALTIES', 'value': ''},
          {'title': 'TOTAL FACED', 'value': positionStats['penalties_faced'].toString()},
          {'title': 'TOTAL SAVED', 'value': positionStats['penalties_saved'].toString()},
          {'title': 'LONG PASSING', 'value': ''},
          {
            'title': 'LONG PASSES (per match)',
            'value': _calculatePerMatch(positionStats['total_long_passes'], matchesPlayed)
          },
          {
            'title': 'LONG PASSING RATE',
            'value': _calculateRate(positionStats['total_long_passes'], matchesPlayed)
          },
        ];
      default:
        return [{'title': 'No Stats', 'value': 'N/A'}];
    }
  }
}