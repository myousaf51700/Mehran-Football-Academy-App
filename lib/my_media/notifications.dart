import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For formatting dates
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isAdmin = false; // Track if the user is an admin
  // Track which announcements have been opened (persistently)
  final Set<String> _openedAnnouncements = {};

  @override
  void initState() {
    super.initState();
    _loadOpenedAnnouncements(); // Load opened state from SharedPreferences
    _checkUserRole(); // Check if the user is an admin
    _fetchAnnouncements();
  }

  // Load the opened announcements from SharedPreferences
  Future<void> _loadOpenedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    final openedList = prefs.getStringList('opened_announcements') ?? [];
    setState(() {
      _openedAnnouncements.addAll(openedList);
    });
  }

  // Save the opened announcements to SharedPreferences
  Future<void> _saveOpenedAnnouncements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('opened_announcements', _openedAnnouncements.toList());
  }

  // Check if the current user is an admin
  Future<void> _checkUserRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('user_type')
          .select('role')
          .eq('email', user.email!)
          .limit(1);

      if (response.isNotEmpty) {
        final role = response.first['role'] as String?;
        setState(() {
          _isAdmin = role?.toLowerCase() == 'admin';
        });
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _supabase
          .from('announcement')
          .select()
          .order('created_at', ascending: false); // Sort by creation date, newest first

      setState(() {
        _announcements = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load announcements: $e';
        _isLoading = false;
      });
    }
  }

  // Delete an announcement by ID
  Future<void> _deleteAnnouncement(int announcementId) async {
    try {
      await _supabase.from('announcement').delete().eq('id', announcementId);
      setState(() {
        _announcements.removeWhere((announcement) => announcement['id'] == announcementId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete announcement: $e')),
      );
    }
  }

  // Show delete confirmation dialog
  Future<void> _showDeleteDialog(int announcementId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text('Are you sure you want to delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteAnnouncement(announcementId); // Delete the announcement
              },
              child: const Text('Delete?', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0),
            child: Text(
              'Announcements',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'RubikMedium',
                color: Colors.blueGrey.shade900,
              ),
            ),
          ),
          // Announcements List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _announcements.isEmpty
                ? const Center(child: Text('No announcements available.'))
                : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                // Use the unique ID for each announcement
                final announcementId = announcement['id'].toString();
                final isOpened = _openedAnnouncements.contains(announcementId);
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  color: isOpened ? Colors.white : Colors.grey.shade300, // Grey if not opened, white if opened
                  child: ListTile(
                    title: Text(
                      announcement['type'] ?? 'No Type',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      _formatDate(announcement['created_at']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _openedAnnouncements.add(announcementId); // Mark as opened
                      });
                      _saveOpenedAnnouncements(); // Save the updated state
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnnouncementDetail(
                            title: announcement['title'] ?? 'No Title',
                            content: announcement['content'] ?? 'No Content',
                            date: announcement['created_at'],
                          ),
                        ),
                      );
                    },
                    onLongPress: _isAdmin
                        ? () {
                      // Convert the ID to int before passing to _showDeleteDialog
                      final intId = announcement['id'] is String
                          ? int.parse(announcement['id'])
                          : announcement['id'] as int;
                      _showDeleteDialog(intId); // Show delete dialog if user is admin
                    }
                        : null, // Disable long press if not admin
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy – h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}

class AnnouncementDetail extends StatelessWidget {
  final String title;
  final String content;
  final dynamic date;

  const AnnouncementDetail({
    super.key,
    required this.title,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blueGrey.shade50,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 10),
              // Content
              Text(
                content,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              // Date
              Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Date not available';
    try {
      final dateTime = DateTime.parse(date.toString());
      return DateFormat('MMM d, yyyy – h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid date';
    }
  }
}