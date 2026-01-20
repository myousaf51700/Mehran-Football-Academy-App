import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/uploading_module/pending_matches_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScheduleMatch extends StatefulWidget {
  const ScheduleMatch({super.key});

  @override
  State<ScheduleMatch> createState() => _ScheduleMatchState();
}

class _ScheduleMatchState extends State<ScheduleMatch> {
  final _opponentTeamController = TextEditingController();
  final _matchVenueController = TextEditingController();
  final _matchScoreController = TextEditingController();
  final _matchStatusController = TextEditingController();
  final _manOfMatchController = TextEditingController();
  DateTime? _matchTime;
  String? _matchType;
  bool _isLoading = false;
  bool _isTeamVisible = false;
  List<Map<String, dynamic>> _playingElevenPlayers = [];

  final List<String> _matchTypes = ['Friendly', 'Tournament', 'League'];
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _oneSignalAppId = "23241790-a833-4f2e-ae6e-a9c24d7d002e";
  final String _oneSignalRestApiKey = "os_v2_app_emsbpefignhs5ltovhbe27iafyfxv7j6fqbe2ivp773mdwoipzxjo7oezkwgieus3cvovjnuo3pjjyouaqygia2v7giafha74cy2bvi";

  Future<void> _submitMatch() async {
    if (_opponentTeamController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opponent Team cannot be empty!')),
      );
      return;
    }
    if (_matchType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Match Type!')),
      );
      return;
    }
    if (_matchTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Match Time!')),
      );
      return;
    }
    if (_matchVenueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match Ground cannot be empty!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      List<String> teamPlayers = _playingElevenPlayers
          .map((player) => player['full_name']?.toString() ?? 'Unknown')
          .toList();

      final matchData = {
        'opponent_team': _opponentTeamController.text.trim(),
        'match_type': _matchType,
        'match_time': _matchTime!.toIso8601String(),
        'match_venue': _matchVenueController.text.trim(),
        'match_score': _matchScoreController.text.trim().isEmpty ? null : _matchScoreController.text.trim(),
        'result_status': _matchStatusController.text.trim().isEmpty ? null : _matchStatusController.text.trim(),
        'man_of_the_match': _manOfMatchController.text.trim().isEmpty ? null : _manOfMatchController.text.trim(),
        'playing_team': teamPlayers,
        'status': 'pending',
      };

      await _supabase.from('match').insert(matchData);

      final formattedTime = DateFormat('yyyy-MM-dd hh:mm a').format(_matchTime!);
      final announcementContent =
          'A ${_matchType!.toLowerCase()} match will be held against ${_opponentTeamController.text.trim()} '
          'on $formattedTime at ${_matchVenueController.text.trim()}.';

      await _supabase.from('announcement').insert({
        'title': 'Match Announcement',
        'content': announcementContent,
        'type': 'Match',
      });

      // Send OneSignal notification via REST API
      await _sendNotification(
        title: 'Match Alert!',
        message: announcementContent,
        data: {'type': 'match', 'screen': 'notifications'},
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match scheduled and notification sent successfully!')),
      );

      _opponentTeamController.clear();
      _matchVenueController.clear();
      _matchScoreController.clear();
      _matchStatusController.clear();
      _manOfMatchController.clear();
      setState(() {
        _matchTime = null;
        _matchType = null;
        _isTeamVisible = false;
        _playingElevenPlayers = [];
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PendingMatchesScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotification({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic $_oneSignalRestApiKey',
    };
    final body = jsonEncode({
      'app_id': _oneSignalAppId,
      'included_segments': ['Subscribed Users'],
      'headings': {'en': title},
      'contents': {'en': message},
      if (data != null) 'data': data,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        print('Notification sent successfully: ${response.body}');
      } else {
        throw Exception('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
      throw e;
    }
  }

  Future<void> _fetchPlayingEleven() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('player_statistics')
          .select('full_name, position')
          .eq('playing_eleven', true);

      List<Map<String, dynamic>> players = List<Map<String, dynamic>>.from(response);

      players.sort((a, b) {
        const positionOrder = {
          'Striker': 1,
          'Midfielder': 2,
          'Defender': 3,
          'Goalkeeper': 4,
        };
        int orderA = positionOrder[a['position']] ?? 5;
        int orderB = positionOrder[b['position']] ?? 5;
        return orderA.compareTo(orderB);
      });

      setState(() {
        _playingElevenPlayers = players;
        _isTeamVisible = true;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching team: $e')),
      );
      setState(() {
        _isLoading = false;
        _isTeamVisible = false;
      });
    }
  }

  Future<void> _selectMatchTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _matchTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        final DateTime dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );
        setState(() {
          _matchTime = dateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Schedule Match',
                  style: TextStyle(
                    fontFamily: 'RubikMedium',
                    fontSize: 24,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Opponent Team *',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              TextField(
                controller: _opponentTeamController,
                decoration: InputDecoration(
                  hintText: 'Enter opponent team name',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
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
                'Match Type *',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              DropdownButtonFormField<String>(
                value: _matchType,
                hint: Text(
                  'Select Match Type',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                items: _matchTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type, style: TextStyle(fontFamily: 'RubikRegular')),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _matchType = newValue;
                  });
                },
                decoration: InputDecoration(
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
                'Match Time *',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              GestureDetector(
                onTap: () => _selectMatchTime(context),
                child: AbsorbPointer(
                  child: TextField(
                    controller: TextEditingController(
                      text: _matchTime != null
                          ? DateFormat('yyyy-MM-dd hh:mm a').format(_matchTime!)
                          : '',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Select Date and Time',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: Icon(Icons.calendar_today, color: Colors.green.shade700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Match Ground *',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              TextField(
                controller: _matchVenueController,
                decoration: InputDecoration(
                  hintText: 'Enter Ground',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
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
                'Match Result',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              TextField(
                controller: _matchScoreController,
                decoration: InputDecoration(
                  hintText: 'Enter result',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
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
                'Match Status',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              TextField(
                controller: _matchStatusController,
                decoration: InputDecoration(
                  hintText: 'Enter status',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
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
                'Man of the Match',
                style: TextStyle(
                  fontFamily: 'RubikRegular',
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
              TextField(
                controller: _manOfMatchController,
                decoration: InputDecoration(
                  hintText: 'Enter Man of the Match',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              RoundWhiteButton(
                title: 'Create Team',
                onTap: _fetchPlayingEleven,
                loading: _isLoading,
              ),
              const SizedBox(height: 20),
              if (_isTeamVisible)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _playingElevenPlayers.isEmpty
                      ? const Center(child: Text('No players in Playing Eleven'))
                      : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _playingElevenPlayers.length,
                    itemBuilder: (context, index) {
                      final player = _playingElevenPlayers[index];
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              player['full_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontFamily: 'RubikRegular',
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '(${player['position'] ?? 'Unknown'})',
                              style: const TextStyle(
                                fontFamily: 'RubikRegular',
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              RoundButton(
                title: 'Schedule Match',
                onTap: _isLoading ? () {} : _submitMatch,
                loading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _opponentTeamController.dispose();
    _matchVenueController.dispose();
    _matchScoreController.dispose();
    _matchStatusController.dispose();
    _manOfMatchController.dispose();
    super.dispose();
  }
}