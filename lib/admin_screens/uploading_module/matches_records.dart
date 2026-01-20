import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../my_components/title_text.dart';

class MatchesRecords extends StatefulWidget {
  const MatchesRecords({super.key});

  @override
  State<MatchesRecords> createState() => _MatchesRecordsState();
}

class _MatchesRecordsState extends State<MatchesRecords> {
  List<Map<String, dynamic>> _matches = [];
  int _wins = 0;
  int _draws = 0;
  int _losses = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      final response = await Supabase.instance.client
          .from('match')
          .select('*')
          .eq('status', 'completed');

      if (response.isNotEmpty) {
        setState(() {
          _matches = (response as List<dynamic>).cast<Map<String, dynamic>>();
          _wins = _matches.where((match) =>
          match['result_status']?.toLowerCase() == 'won' ||
              match['result_status']?.toLowerCase() == 'win').length;
          _draws = _matches.where((match) =>
          match['result_status']?.toLowerCase() == 'draw').length;
          _losses = _matches.where((match) =>
          match['result_status']?.toLowerCase() == 'lost' ||
              match['result_status']?.toLowerCase() == 'loss').length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching matches: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 60),
          const TitleText(text: 'Match Records'),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  _buildSummaryCard('Wins', _wins, [Colors.green[700]!, Colors.green[200]!]),
                  const SizedBox(width: 2),
                  _buildSummaryCard('Draws', _draws, [Colors.yellow[700]!, Colors.yellow[200]!]),
                  const SizedBox(width: 2),
                  _buildSummaryCard('Losses', _losses, [Colors.red[700]!, Colors.red[200]!]),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      match['opponent_team']?.toString() ?? 'Unknown Team',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${match['match_venue']?.toString() ?? 'Unknown Venue'} - Result: ${match['result_status']?.toString() ?? 'N/A'}',
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedMatchRecord(match: match),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, List<Color> gradientColors) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailedMatchRecord extends StatelessWidget {
  final Map<String, dynamic> match;

  const DetailedMatchRecord({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    if (match.isEmpty) {
      return Scaffold(
        body: const Center(child: Text('No match data available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(top: 40.0, left: 20, right: 20, bottom: 40),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            color: Colors.grey.shade300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.people, 'Opponent Team', _safeToString(match['opponent_team'])),
                  _buildDetailRow(Icons.sports_baseball, 'Match Type', _safeToString(match['match_type'])),
                  _buildDetailRow(Icons.schedule, 'Match Time', _formatMatchTime(match['match_time'])),
                  _buildDetailRow(Icons.location_on, 'Venue', _safeToString(match['match_venue'])),
                  _buildDetailRow(Icons.scoreboard, 'Score', _safeToString(match['match_score'])),
                  _buildDetailRow(Icons.flag, 'Result Status', _safeToString(match['result_status'])),
                  _buildDetailRow(Icons.emoji_events, 'Man of the Match', _safeToString(match['man_of_the_match'])),
                  _buildDetailRow(Icons.group, 'Playing Team', _safeToString(match['playing_team'])),
                  _buildDetailRow(Icons.check_circle, 'Status', _safeToString(match['status'])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _safeToString(dynamic value) {
    if (value == null) return 'N/A';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  String _formatMatchTime(dynamic value) {
    if (value == null) return 'N/A';
    try {
      // Parse the timestamp string into a DateTime object
      final dateTime = DateTime.parse(value.toString()).toLocal();
      // Format the DateTime to "yyyy-MM-dd h:mm a" (e.g., "2025-05-04 4:30 PM")
      final formatter = DateFormat('yyyy-MM-dd h:mm a');
      return formatter.format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}