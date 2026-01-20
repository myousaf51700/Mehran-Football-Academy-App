import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';

// New RoundRedButton widget for the Dispose button
class RoundRedButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;

  const RoundRedButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red, // Red color for Dispose button
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RubikRegular',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateMatchScreen extends StatefulWidget {
  final String matchId;

  const UpdateMatchScreen({super.key, required this.matchId});

  @override
  State<UpdateMatchScreen> createState() => _UpdateMatchScreenState();
}

class _UpdateMatchScreenState extends State<UpdateMatchScreen> {
  final _matchScoreController = TextEditingController();
  final _matchStatusController = TextEditingController();
  final _manOfMatchController = TextEditingController();
  bool _isLoading = false;
  String? _opponentTeam;
  String? _matchType;
  String? _matchTime;
  String? _matchVenue;
  List<String>? _playingTeam;

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _fetchMatchDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('match')
          .select()
          .eq('match_id', widget.matchId)
          .single();

      setState(() {
        _opponentTeam = response['opponent_team']?.toString();
        _matchType = response['match_type']?.toString();
        _matchTime = response['match_time']?.toString().split('T')[0];
        _matchVenue = response['match_venue']?.toString();
        _playingTeam = List<String>.from(response['playing_team'] ?? []);
        _matchScoreController.text = response['match_score']?.toString() ?? '';
        _matchStatusController.text = response['result_status']?.toString() ?? '';
        _manOfMatchController.text = response['man_of_the_match']?.toString() ?? '';
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching match details: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateMatch() async {
    if (_matchScoreController.text.trim().isEmpty ||
        _matchStatusController.text.trim().isEmpty ||
        _manOfMatchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required for final submission!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('match').update({
        'match_score': _matchScoreController.text.trim(),
        'result_status': _matchStatusController.text.trim(),
        'man_of_the_match': _manOfMatchController.text.trim(),
        'status': 'completed',
      }).eq('match_id', widget.matchId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match updated and finalized successfully!')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating match: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelForm() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm'),
          content: const Text('Are you sure you want to dispose of this form? This will remove the match from the pending list.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await _supabase
                      .from('match')
                      .delete()
                      .eq('match_id', widget.matchId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match removed from pending list successfully!')),
                  );
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pop(); // Return to PendingMatchesScreen
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing match: $e')),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchMatchDetails();
  }

  @override
  void dispose() {
    _matchScoreController.dispose();
    _matchStatusController.dispose();
    _manOfMatchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Complete the Form',
                  style: TextStyle(
                    fontFamily: 'RubikMedium',
                    fontSize: 20,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Opponent Team: $_opponentTeam',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Match Type: $_matchType',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Match Time: $_matchTime',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Match Ground: $_matchVenue',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
              ),
              const SizedBox(height: 20),
              Text(
                'Playing Team',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _playingTeam?.isEmpty ?? true
                    ? const Center(child: Text('No players in team'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _playingTeam?.length ?? 0,
                  itemBuilder: (context, index) {
                    return Text(
                      _playingTeam![index],
                      style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16),
                    );
                  },
                ),
              ),
              Text(
                'Match Result *',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16, color: Colors.grey),
              ),
              TextField(
                controller: _matchScoreController,
                decoration: InputDecoration(
                  hintText: 'Enter result',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Match Status *',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16, color: Colors.grey),
              ),
              TextField(
                controller: _matchStatusController,
                decoration: InputDecoration(
                  hintText: 'Enter status',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'MTM *',
                style: const TextStyle(fontFamily: 'RubikRegular', fontSize: 16, color: Colors.grey),
              ),
              TextField(
                controller: _manOfMatchController,
                decoration: InputDecoration(
                  hintText: 'Enter MTM',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Dispose Button (Red)
              RoundRedButton(
                title: 'Dispose',
                onTap: _isLoading ? () {} : _cancelForm,
                loading: _isLoading,
              ),
              const SizedBox(height: 10),
              // Final Submit Button
              RoundButton(
                title: 'Final Submit',
                onTap: _isLoading ? () {} : _updateMatch,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}