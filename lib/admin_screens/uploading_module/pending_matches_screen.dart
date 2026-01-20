import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/update_match_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PendingMatchesScreen extends StatefulWidget {
  const PendingMatchesScreen({super.key});

  @override
  State<PendingMatchesScreen> createState() => _PendingMatchesScreenState();
}

class _PendingMatchesScreenState extends State<PendingMatchesScreen> {
  List<Map<String, dynamic>> _pendingMatches = [];
  bool _isLoading = false;
  String? _errorMessage;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _fetchPendingMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('match')
          .select()
          .eq('status', 'pending');

      setState(() {
        _pendingMatches = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load pending matches: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPendingMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _pendingMatches.isEmpty
          ? const Center(child: Text('No pending matches'))
          : Column(
        children: [
          const SizedBox(height: 70),
          Center(
            child: Text(
              'Pending Matches',
              style: TextStyle(
                fontFamily: 'RubikMedium',
                fontSize: 20,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _pendingMatches.length,
              itemBuilder: (context, index) {
                final match = _pendingMatches[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      match['opponent_team'] ?? 'Unknown',
                      style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
                    ),
                    subtitle: Text(
                      'Time: ${match['match_time']?.toString().split('T')[0] ?? 'N/A'}',
                      style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 14, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UpdateMatchScreen(matchId: match['match_id'].toString()),
                        ),
                      ).then((_) {
                        // Refresh the list when returning from UpdateMatchScreen
                        _fetchPendingMatches();
                      });
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
}