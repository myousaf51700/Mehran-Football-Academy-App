import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';

class AdminEditScreen extends StatefulWidget {
  final String? fullName;
  final String? fatherName;
  final String? contactNumber;
  final String? email;
  final String? bloodGroup;
  final String? permanentAddress;
  final String? currentAddress;
  final String? expressYourself;
  final String? profileUrl;
  final int? playerAge;
  final String? birthDate;

  const AdminEditScreen({
    this.fullName,
    this.fatherName,
    this.contactNumber,
    this.email,
    this.bloodGroup,
    this.permanentAddress,
    this.currentAddress,
    this.expressYourself,
    this.profileUrl,
    this.playerAge,
    this.birthDate,
    super.key,
  });

  @override
  State<AdminEditScreen> createState() => _AdminEditScreenState();
}

class _AdminEditScreenState extends State<AdminEditScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

  late TextEditingController _fatherNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emailController;
  late TextEditingController _bloodGroupController;
  late TextEditingController _permanentAddressController;
  late TextEditingController _currentAddressController;
  late TextEditingController _expressYourselfController;
  late TextEditingController _playerAgeController;
  late TextEditingController _birthDateController;

  String? _newProfileUrl;

  @override
  void initState() {
    super.initState();
    _fatherNameController = TextEditingController(text: widget.fatherName ?? '');
    _contactNumberController = TextEditingController(text: widget.contactNumber ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _bloodGroupController = TextEditingController(text: widget.bloodGroup ?? '');
    _permanentAddressController = TextEditingController(text: widget.permanentAddress ?? '');
    _currentAddressController = TextEditingController(text: widget.currentAddress ?? '');
    _expressYourselfController = TextEditingController(text: widget.expressYourself ?? '');
    _playerAgeController = TextEditingController(text: widget.playerAge?.toString() ?? '');
    _birthDateController = TextEditingController(text: widget.birthDate ?? '');
    _newProfileUrl = widget.profileUrl;
  }

  @override
  void dispose() {
    _fatherNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _bloodGroupController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _expressYourselfController.dispose();
    _playerAgeController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final user = _authService.getCurrentUser();
    if (user == null) return;

    try {
      await _supabase.from('players_records').update({
        // Update all fields except full_name and email
        'father_name': _fatherNameController.text,
        'contact_number': _contactNumberController.text,
        'blood_group': _bloodGroupController.text,
        'permanent_address': _permanentAddressController.text,
        'current_address': _currentAddressController.text,
        'express_yourself': _expressYourselfController.text,
        'profile_url': _newProfileUrl,
        'player_age': int.tryParse(_playerAgeController.text) ?? 0,
        'birth_date': _birthDateController.text,
      }).eq('user_id', user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context); // Return to the profile screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

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

  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final user = _authService.getCurrentUser();
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

        setState(() {
          _newProfileUrl = publicUrl;
        });

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
                    Color(0xFF1976D2), // Dark Blue
                    Color(0xFF42A5F5), // Light Blue
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
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AdminDashboard()));
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
                          key: ValueKey(_newProfileUrl ?? 'default'),
                        ),
                      ),
                    ),
                  ),
                  // Admin Name Overlay
                  Positioned(
                    bottom: 5,
                    left: 20,
                    child: Text(
                      widget.fullName ?? 'Admin Name',
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
                  // Personal Information Card
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
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildNonEditableInfoRow('Full Name', TextEditingController(text: widget.fullName ?? 'N/A')),
                            _buildEditableInfoRow('Father Name', _fatherNameController),
                            _buildNonEditableInfoRow('Email', TextEditingController(text: widget.email ?? 'N/A')),
                            _buildEditableInfoRow('Date of Birth', _birthDateController),
                            _buildEditableInfoRow('Age', _playerAgeController),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Admin Details Card
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
                              'Admin Details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            SizedBox(height: 15),
                            _buildEditableInfoRow('Contact Number', _contactNumberController),
                            _buildEditableInfoRow('Blood Group', _bloodGroupController),
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
                                color: Color(0xFF1976D2),
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
                                color: Color(0xFF1976D2),
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
                  ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: Text(
                      'Save Changes',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableInfoRow(String label, TextEditingController controller) {
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
              borderSide: BorderSide(color: Color(0xFF42A5F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
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

  Widget _buildEditableTextField(String label, TextEditingController controller, {int maxLines = 1}) {
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
              borderSide: BorderSide(color: Color(0xFF42A5F5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF1976D2), width: 2),
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

  Widget _buildNonEditableInfoRow(String label, TextEditingController controller) {
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
        SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Color(0xFF42A5F5)),
            ),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}