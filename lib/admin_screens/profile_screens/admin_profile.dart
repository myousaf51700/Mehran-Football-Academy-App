import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_edit_screen.dart'; // Import the edit screen

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _adminRecord;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAdminProfile();
  }

  Future<void> _fetchAdminProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final response = await _supabase
          .from('players_records')
          .select('*')
          .eq('user_id', currentUser.id)
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          _adminRecord = Map<String, dynamic>.from(response.first);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No profile found for the current admin.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load admin profile: $e';
        _isLoading = false;
      });
    }
  }

  // Method to show image picker options for the main screen
  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Take a Picture'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Upload from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to get image from camera or gallery for the main screen
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final user = _supabase.auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to upload a profile picture')),
          );
          return;
        }

        final session = _supabase.auth.currentSession;
        if (session == null || session.accessToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session expired. Please log in again.')),
          );
          return;
        }

        final storage = _supabase.storage;
        final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final uploadResponse = await storage
            .from('profile_images')
            .uploadBinary(
          fileName,
          await pickedFile.readAsBytes(),
          fileOptions: FileOptions(contentType: 'image/jpeg'),
        );

        final publicUrl = storage.from('profile_images').getPublicUrl(fileName);

        await _supabase
            .from('players_records')
            .update({'profile_url': publicUrl})
            .eq('user_id', user.id);

        await _fetchAdminProfile(); // Refresh data

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            // Header with Gradient and Profile Picture with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1976D2), // Dark Blue
                      Color(0xFF42A5F5), // Light Blue
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back Button
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    // Profile Picture
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: _adminRecord?['profile_url'] != null &&
                                _adminRecord!['profile_url'].isNotEmpty
                                ? NetworkImage(_adminRecord!['profile_url'])
                                : AssetImage('assets/profile.jpg') as ImageProvider,
                            backgroundColor: Colors.grey[300],
                            key: ValueKey(_adminRecord?['profile_url'] ?? 'default'),
                          ),
                        ),
                      ),
                    ),
                    // Admin Name Overlay
                    Positioned(
                      bottom: 45,
                      left: 20,
                      child: Text(
                        _adminRecord?['full_name'] ?? 'Admin Name',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Edit Profile Button
                    Positioned(
                      bottom: 2,
                      right: 16,
                      child: ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminEditScreen(
                                fullName: _adminRecord?['full_name'],
                                fatherName: _adminRecord?['father_name'],
                                contactNumber: _adminRecord?['contact_number'],
                                email: _adminRecord?['email'],
                                bloodGroup: _adminRecord?['blood_group'],
                                permanentAddress: _adminRecord?['permanent_address'],
                                currentAddress: _adminRecord?['current_address'],
                                expressYourself: _adminRecord?['express_yourself'],
                                profileUrl: _adminRecord?['profile_url'],
                                playerAge: _adminRecord?['player_age'],
                                birthDate: _adminRecord?['birth_date'],
                              ),
                            ),
                          );
                          _fetchAdminProfile(); // Refresh data after editing
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(color: Color(0xFF1976D2)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Personal Information Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Full Name', _adminRecord?['full_name'] ?? 'N/A'),
                      _buildInfoRow('Father Name', _adminRecord?['father_name'] ?? 'N/A'),
                      _buildInfoRow('Email', _adminRecord?['email'] ?? 'N/A'),
                      _buildInfoRow('Date of Birth', _adminRecord?['birth_date']?.toString() ?? 'N/A'),
                      _buildInfoRow('Age', _adminRecord?['player_age']?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
            // Admin Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Contact Number', _adminRecord?['contact_number'] ?? 'N/A'),
                      _buildInfoRow('Blood Group', _adminRecord?['blood_group'] ?? 'N/A'),
                      _buildInfoRow('Joined On', _formatJoinedOn(_adminRecord?['created_at'])),
                    ],
                  ),
                ),
              ),
            ),
            // Addresses Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Addresses',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Permanent Address', _adminRecord?['permanent_address'] ?? 'N/A'),
                      _buildInfoRow('Current Address', _adminRecord?['current_address'] ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
            // About Me Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.white,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _adminRecord?['express_yourself'] ?? 'No description available',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                        textAlign: TextAlign.justify,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF42A5F5),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  String _formatJoinedOn(dynamic createdAt) {
    if (createdAt == null) return 'N/A';
    try {
      DateTime dateTime = DateTime.parse(createdAt.toString());
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}