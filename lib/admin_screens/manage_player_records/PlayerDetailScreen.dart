import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class PlayerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10,),
            // Header with Back Button and Profile Picture
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
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
                      padding: const EdgeInsets.only(left: 16.0),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage: player['profile_url'] != null && player['profile_url'].isNotEmpty
                            ? NetworkImage(player['profile_url'])
                            : AssetImage('assets/profile.jpg') as ImageProvider,
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),
                  // Player Name Overlay
                  Positioned(
                    bottom: 10,
                    left: 16,
                    child: Text(
                      player['full_name'] ?? 'No Name',
                      style: TextStyle(
                        fontSize: 28,
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
            SizedBox(height: 20),
            // Player Details Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Player Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildDetailRow('Father Name', player['father_name'] ?? 'N/A'),
                    _buildDetailRow('Contact Number', player['contact_number'] ?? 'N/A'),
                    _buildDetailRow('Email', player['email'] ?? 'N/A'),
                    _buildDetailRow('Blood Group', player['blood_group'] ?? 'N/A'),
                    _buildDetailRow('Playing Position', player['playing_position'] ?? 'N/A'),
                    _buildDetailRow('Joined On', _formatJoinedOn(player['created_at'])), // Updated Joined On format
                    _buildDetailRow('Date of Birth', player['birth_date']?.toString() ?? 'N/A'), // Added birth_date
                    _buildDetailRow('Age', player['player_age']?.toString() ?? 'N/A'), // Added player_age
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Addresses Card
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              child: Container(
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
                    _buildDetailRow('Permanent Address', player['permanent_address'] ?? 'N/A'),
                    _buildDetailRow('Current Address', player['current_address'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // About Me Card
            Card(
              elevation: 6,
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
                      player['express_yourself'] ?? 'No description available',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF42A5F5),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatJoinedOn(dynamic createdAt) {
    if (createdAt == null) return 'N/A';
    try {
      // Parse the timestamp string to DateTime
      DateTime dateTime = DateTime.parse(createdAt.toString());
      // Format the date as "MMMM d, yyyy" (e.g., "March 12, 2025")
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return 'N/A'; // Fallback if parsing fails
    }
  }
}