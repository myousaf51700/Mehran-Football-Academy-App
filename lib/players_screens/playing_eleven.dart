import 'package:flutter/material.dart';
import 'package:mehran_football_academy/my_components/title_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayingEleven extends StatefulWidget {
  const PlayingEleven({super.key});

  @override
  State<PlayingEleven> createState() => _PlayingElevenState();
}

class _PlayingElevenState extends State<PlayingEleven> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> playingElevenPlayers = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchPlayingEleven();
  }

  Future<void> _fetchPlayingEleven() async {
    try {
      final response = await _supabase
          .from('player_statistics')
          .select('full_name, position')
          .eq('playing_eleven', true);

      if (mounted) {
        setState(() {
          playingElevenPlayers = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching players: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          const SizedBox(height: 60),
          const Center(
            child: TitleText(text: 'Academy official Team'),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                ? const Center(child: Text('Failed to load players'))
                : playingElevenPlayers.isEmpty
                ? const Center(child: Text('No players in the playing eleven'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: playingElevenPlayers.length,
              itemBuilder: (context, index) {
                final player = playingElevenPlayers[index];
                return Card(
                  elevation: 3,
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(
                      player['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.black,
                        fontFamily: 'RubikMedium'
                      ),
                    ),
                    trailing: Text(
                      player['position'] ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
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