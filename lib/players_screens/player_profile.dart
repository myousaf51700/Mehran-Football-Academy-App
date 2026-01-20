import 'dart:math' as MainSize;

import 'package:flutter/material.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';
import 'package:mehran_football_academy/players_screens/player_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:image_picker/image_picker.dart'; // For image picking

class PlayerProfile extends StatefulWidget {
  const PlayerProfile({super.key});

  @override
  State<PlayerProfile> createState() => _PlayerProfileState();
}

class _PlayerProfileState extends State<PlayerProfile> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  // State variables to hold player data
  String? _fullName;
  String? _fatherName;
  String? _contactNumber;
  String? _email;
  String? _bloodGroup;
  String? _permanentAddress;
  String? _currentAddress;
  String? _playingPosition;
  String? _expressYourself;
  String? _profileUrl;
  String? _createdAt;
  int? _playerAge; // Added for player_age
  String? _birthDate; // Added for birth_date

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlayerData();
  }

  Future<void> _loadPlayerData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await _supabase
          .from('players_records')
          .select('*')
          .eq('user_id', user.id)
          .limit(1); // Use limit to avoid multiple rows issue

      if (response.isNotEmpty) {
        final data = response.first;
        setState(() {
          _fullName = data['full_name'];
          _fatherName = data['father_name'];
          _contactNumber = data['contact_number'];
          _email = data['email'];
          _bloodGroup = data['blood_group'];
          _permanentAddress = data['permanent_address'];
          _currentAddress = data['current_address'];
          _playingPosition = data['playing_position'];
          _expressYourself = data['express_yourself'];
          _profileUrl = data['profile_url'];
          _createdAt = data['created_at']?.toString().split(' ')[0]; // Date only
          _playerAge = data['player_age']; // Fetch player_age
          _birthDate = data['birth_date']?.toString(); // Fetch birth_date
          _isLoading = false;
        });
        print('Loaded profile URL: $_profileUrl');
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No profile data found for this user')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
      setState(() {
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
        final user = _authService.getCurrentUser();
        if (user == null) {
          print('User not logged in');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to upload a profile picture')),
          );
          return;
        }

        // Check current session
        final session = _supabase.auth.currentSession;
        if (session == null || session.accessToken == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session expired. Please log in again.')),
          );
          return;
        }

        // Ensure the storage client uses the authenticated session
        final storage = _supabase.storage;
        try {
          final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final uploadResponse = await storage
              .from('profile_images')
              .uploadBinary(
            fileName,
            await pickedFile.readAsBytes(),
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );

          final publicUrl = storage.from('profile_images').getPublicUrl(fileName);

          // Update the profile_url in the players_records table
          await _supabase
              .from('players_records')
              .update({'profile_url': publicUrl})
              .eq('user_id', user.id);

          // Force reload of data to refresh the image
          await _loadPlayerData();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated!')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile picture: $e')),
          );
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
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
            // Header with Gradient and Profile Picture with Back Button
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E7D32), // Dark Green
                    Color(0xFF66BB6A), // Light Green
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back Button
                  // Profile Picture
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: _profileUrl != null && _profileUrl!.isNotEmpty
                              ? NetworkImage(_profileUrl!)
                              : AssetImage('assets/profile.jpg') as ImageProvider,
                          backgroundColor: Colors.grey[300],
                          // Force refresh by adding a unique key
                          key: ValueKey(_profileUrl ?? 'default'),
                        ),
                      ),
                    ),
                  ),
                  // Player Name Overlay
                  Positioned(
                    bottom: 45,
                    left: 20,
                    child: Text(
                      _fullName ?? 'Player Name',
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
                        // Navigate to EditProfileScreen and wait for result
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              fullName: _fullName,
                              fatherName: _fatherName,
                              contactNumber: _contactNumber,
                              email: _email,
                              bloodGroup: _bloodGroup,
                              permanentAddress: _permanentAddress,
                              currentAddress: _currentAddress,
                              playingPosition: _playingPosition,
                              expressYourself: _expressYourself,
                              profileUrl: _profileUrl,
                              playerAge: _playerAge, // Pass player_age
                              birthDate: _birthDate, // Pass birth_date
                            ),
                          ),
                        );
                        // Refresh data after returning
                        _loadPlayerData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Edit profile',
                        style: TextStyle(color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Personal Information Card (Uneditable: Full Name, Father Name, Email, DOB, Age)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Full Name', _fullName ?? 'N/A'),
                      _buildInfoRow('Father Name', _fatherName ?? 'N/A'),
                      _buildInfoRow('Email', _email ?? 'N/A'),
                      _buildInfoRow('Date of Birth', _birthDate ?? 'N/A'),
                      _buildInfoRow('Age', _playerAge?.toString() ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
            // Player Details Card (Remaining Editable Attributes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        'Player Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Contact', _contactNumber ?? 'N/A'),
                      _buildInfoRow('Blood Group', _bloodGroup ?? 'N/A'),
                      _buildInfoRow('Playing Position', _playingPosition ?? 'N/A'),
                      _buildInfoRow('Joined On', _createdAt ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
            // Address Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow('Permanent Address', _permanentAddress ?? 'N/A'),
                      _buildInfoRow('Current Address', _currentAddress ?? 'N/A'),
                    ],
                  ),
                ),
              ),
            ),
            // Express Yourself Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        _expressYourself ?? 'No description available',
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
            color: Color(0xFF66BB6A),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 10), // Add some spacing between rows
      ],
    );
  }
}

// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final String? fullName;
  final String? fatherName;
  final String? contactNumber;
  final String? email;
  final String? bloodGroup;
  final String? permanentAddress;
  final String? currentAddress;
  final String? playingPosition;
  final String? expressYourself;
  final String? profileUrl;
  final int? playerAge; // Added for player_age
  final String? birthDate; // Added for birth_date

  const EditProfileScreen({
    this.fullName,
    this.fatherName,
    this.contactNumber,
    this.email,
    this.bloodGroup,
    this.permanentAddress,
    this.currentAddress,
    this.playingPosition,
    this.expressYourself,
    this.profileUrl,
    this.playerAge, // Pass player_age
    this.birthDate, // Pass birth_date
    super.key,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late TextEditingController _fullNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _currentAddressController;
  late TextEditingController _playingPositionController;
  late TextEditingController _expressYourselfController;
  late TextEditingController _playerAgeController; // Added for player_age
  late TextEditingController _birthDateController; // Added for birth_date

  String? _newProfileUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName ?? '');
    _fatherNameController = TextEditingController(text: widget.fatherName ?? '');
    _contactNumberController = TextEditingController(text: widget.contactNumber ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _bloodGroupController = TextEditingController(text: widget.bloodGroup ?? '');
    _permanentAddressController = TextEditingController(text: widget.permanentAddress ?? '');
    _currentAddressController = TextEditingController(text: widget.currentAddress ?? '');
    _playingPositionController = TextEditingController(text: widget.playingPosition ?? '');
    _expressYourselfController = TextEditingController(text: widget.expressYourself ?? '');
    _playerAgeController = TextEditingController(text: widget.playerAge?.toString() ?? ''); // Non-editable
    _birthDateController = TextEditingController(text: widget.birthDate ?? ''); // Non-editable
    _newProfileUrl = widget.profileUrl;
    _loadPlayerData(); // Load initial data
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _bloodGroupController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _playingPositionController.dispose();
    _expressYourselfController.dispose();
    _playerAgeController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final response = await _supabase
          .from('players_records')
          .select('*')
          .eq('user_id', user.id)
          .limit(1);

      if (response.isNotEmpty) {
        final data = response.first;
        setState(() {
          _fullNameController.text = data['full_name'] ?? '';
          _fatherNameController.text = data['father_name'] ?? '';
          _contactNumberController.text = data['contact_number'] ?? '';
          _emailController.text = data['email'] ?? '';
          _bloodGroupController.text = data['blood_group'] ?? '';
          _permanentAddressController.text = data['permanent_address'] ?? '';
          _currentAddressController.text = data['current_address'] ?? '';
          _playingPositionController.text = data['playing_position'] ?? '';
          _expressYourselfController.text = data['express_yourself'] ?? '';
          _playerAgeController.text = data['player_age']?.toString() ?? ''; // Non-editable
          _birthDateController.text = data['birth_date']?.toString() ?? ''; // Non-editable
          _newProfileUrl = data['profile_url'];
        });
        print('Loaded profile URL: $_newProfileUrl');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> _saveChanges() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      // Update all fields except email, full_name, father_name, player_age, and birth_date
      await _supabase.from('players_records').update({
        // Do not include 'email', 'full_name', 'father_name', 'player_age', or 'birth_date' to prevent updates
        'contact_number': _contactNumberController.text,
        'blood_group': _bloodGroupController.text,
        'permanent_address': _permanentAddressController.text,
        'current_address': _currentAddressController.text,
        'playing_position': _playingPositionController.text,
        'express_yourself': _expressYourselfController.text,
        'profile_url': _newProfileUrl,
      }).eq('user_id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      // Refresh data after saving
      await _loadPlayerData();
      Navigator.pop(context); // Return to the profile screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  // Method to show image picker options
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
                print('Attempting to open camera...');
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Upload from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                print('Attempting to open gallery...');
                await _getImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  // Method to get image from camera or gallery
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      print('Picked file: $pickedFile');

      if (pickedFile != null) {
        final user = _authService.getCurrentUser();
        if (user == null) {
          print('User not logged in');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please log in to upload a profile picture')),
          );
          return;
        }

        // Check current session
        final session = _supabase.auth.currentSession;
        if (session == null || session.accessToken == null) {
          print('No valid session found');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session expired. Please log in again.')),
          );
          return;
        }

        // Ensure the storage client uses the authenticated session
        final storage = _supabase.storage;
        try {
          final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          print('Uploading image to Supabase: $fileName');
          final uploadResponse = await storage
              .from('profile_images')
              .uploadBinary(
            fileName,
            await pickedFile.readAsBytes(),
            fileOptions: FileOptions(contentType: 'image/jpeg'),
          );
          print('Upload response: $uploadResponse');

          final publicUrl = storage.from('profile_images').getPublicUrl(fileName);
          print('Public URL: $publicUrl');

          // Update the profile_url in the players_records table
          await _supabase
              .from('players_records')
              .update({'profile_url': publicUrl})
              .eq('user_id', user.id);
          print('Updated profile_url in players_records table');

          // Update the local state
          setState(() {
            _newProfileUrl = publicUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile picture updated!')),
          );
        } catch (e) {
          print('Error uploading image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile picture: $e')),
          );
        }
      } else {
        print('No image selected');
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header with Gradient and Profile Picture with Back Button
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF2E7D32), // Dark Green
                    Color(0xFF66BB6A), // Light Green
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back Button
                  Positioned(
                    top: 20,
                    left: 10,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
                      onPressed: () {
                        Navigator.pop(context); // Navigate back
                      },
                    ),
                  ),
                  // Profile Picture
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, top: 30),
                      child: GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _newProfileUrl != null && _newProfileUrl!.isNotEmpty
                              ? NetworkImage(_newProfileUrl!)
                              : AssetImage('assets/profile.jpg') as ImageProvider,
                          backgroundColor: Colors.grey[300],
                          // Force refresh by adding a unique key
                          key: ValueKey(_newProfileUrl ?? 'default'),
                        ),
                      ),
                    ),
                  ),
                  // Player Name Overlay
                  Positioned(
                    bottom: 5,
                    left: 20,
                    child: Text(
                      _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Player Name',
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Personal Information Card (Uneditable: Full Name, Father Name, Email, DOB, Age)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildInfoRow('Full Name', _fullNameController.text.isNotEmpty ? _fullNameController.text : 'N/A'),
                            _buildInfoRow('Father Name', _fatherNameController.text.isNotEmpty ? _fatherNameController.text : 'N/A'),
                            _buildInfoRow('Email', _emailController.text.isNotEmpty ? _emailController.text : 'N/A'),
                            _buildInfoRow('Date of Birth', _birthDateController.text.isNotEmpty ? _birthDateController.text : 'N/A'),
                            _buildInfoRow('Age', _playerAgeController.text.isNotEmpty ? _playerAgeController.text : 'N/A'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Player Details Card (Editable Attributes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                              'Player Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildEditableInfoRow('Contact Number', _contactNumberController),
                            _buildEditableInfoRow('Blood Group', _bloodGroupController),
                            _buildEditableInfoRow('Playing Position', _playingPositionController),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Address Card
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildEditableInfoRow('Permanent Address', _permanentAddressController),
                            _buildEditableInfoRow('Current Address', _currentAddressController),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // About Me Card
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildEditableTextField('About Me', _expressYourselfController, maxLines: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  RoundButton(
                    title: 'Save Changes',
                    onTap: _saveChanges,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Custom widget for uneditable info rows (used in PlayerProfile)
  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF66BB6A),
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Custom widget for editable info rows (used in EditProfileScreen)
  Widget _buildEditableInfoRow(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF66BB6A),
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF66BB6A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Custom widget for multiline text field (About Me)
  Widget _buildEditableTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF66BB6A),
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF66BB6A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Custom widget for non-editable info rows (used for DOB and Age in EditProfileScreen)
  Widget _buildNonEditableInfoRow(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF66BB6A),
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: false, // Disable editing
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF66BB6A)),
            ),
            filled: true,
            fillColor: Colors.grey[200], // Slightly greyed out to indicate non-editable
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}