import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mehran_football_academy/my_components/round_button.dart';

class MakeAnnouncement extends StatefulWidget {
  const MakeAnnouncement({super.key});

  @override
  State<MakeAnnouncement> createState() => _MakeAnnouncementState();
}

class _MakeAnnouncementState extends State<MakeAnnouncement> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;

  final SupabaseClient supabase = Supabase.instance.client;
  final String _oneSignalAppId = "23241790-a833-4f2e-ae6e-a9c24d7d002e";
  final String _oneSignalRestApiKey = "os_v2_app_emsbpefignhs5ltovhbe27iaf3b2r33tzt6ulqedd624wlkh7p2ynwio6axjrfmy5ex2jdj5h5wdyb5r44xrlw4ohxlzg4y3sbszhra"; // Replace with new key if invalid

  final List<String> _types = ['Training', 'Match', 'Event'];

  Future<void> _submitAnnouncement() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty!')),
      );
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content cannot be empty!')),
      );
      return;
    }
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an announcement type!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Insert announcement into Supabase
      await supabase.from('announcement').insert({
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'type': _selectedType,
      });

      // Send OneSignal notification
      await _sendNotification(
        title: 'Announcement',
        message: _contentController.text.trim(),
        data: {'type': 'announcement', 'screen': 'notifications'},
      );

      _titleController.clear();
      _contentController.clear();
      setState(() => _selectedType = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement created and notification sent successfully!')),
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
    print('Sending notification with App ID: $_oneSignalAppId');
    print('Authorization Header: ${headers['Authorization']}');
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
        print('Failed to send notification: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
      throw e;
    }
  }

  void _onTap() {
    _submitAnnouncement();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'Make Announcement',
                    style: TextStyle(fontFamily: 'RubikMedium', fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Title',
                  style: TextStyle(fontFamily: 'RubikMedium', fontSize: 16),
                ),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Content',
                  style: TextStyle(fontFamily: 'RubikMedium', fontSize: 16),
                ),
                TextField(
                  controller: _contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Announcement Type',
                  style: TextStyle(fontFamily: 'RubikMedium', fontSize: 16),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  hint: const Text('Select Type'),
                  items: _types.map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                  ),
                  validator: (value) => value == null ? ' 좀 더 구체적인 유형을 선택해주세요' : null,
                ),
                const SizedBox(height: 20),
                RoundButton(
                  title: 'Announce',
                  onTap: _isLoading ? () {} : _onTap,
                  loading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}