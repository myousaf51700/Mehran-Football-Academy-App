import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:intl/intl.dart'; // Import intl for date formatting
import 'FeeRecordDetailScreen.dart';

class FeeSectionScreen extends StatefulWidget {
  final String? userId;

  const FeeSectionScreen({super.key, this.userId});

  @override
  State<FeeSectionScreen> createState() => _FeeSectionScreenState();
}

class _FeeSectionScreenState extends State<FeeSectionScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _feeRecords = [];
  bool _isLoading = true;

  // Function to format date from YYYY-MM-DD to Month Day, Year
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return 'N/A';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFeeRecords();
  }

  Future<void> _loadFeeRecords() async {
    try {
      // Verify the userId passed to the screen
      if (widget.userId == null) {
        throw Exception('User ID is null. Please log in.');
      }

      // Verify the logged-in user's ID (should match widget.userId)
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user is logged in. Please log in again.');
      }
      if (currentUser.id != widget.userId) {
        throw Exception('Logged-in user ID (${currentUser.id}) does not match the provided userId (${widget.userId}).');
      }

      // Fetch fee records
      final response = await _supabase
          .from('fee_records')
          .select('*')
          .eq('user_id', widget.userId!)
          .order('created_at', ascending: false);

      print('Fetched fee records: $response');

      setState(() {
        _feeRecords = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      if (_feeRecords.isEmpty) {
        print('No fee records found for userId: ${widget.userId}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fee records: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Fee Records'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: _feeRecords.isEmpty
                  ? const Center(child: Text('No fee records found.'))
                  : ListView.builder(
                itemCount: _feeRecords.length,
                itemBuilder: (context, index) {
                  final record = _feeRecords[index];
                  final paymentStatus = record['payment_status']?.toString().toLowerCase() ?? 'unknown';

                  // Define gradient based on payment status
                  LinearGradient cardGradient;
                  if (paymentStatus == 'unpaid') {
                    cardGradient = LinearGradient(
                      colors: [Colors.red[700]!, Colors.red[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  } else if (paymentStatus == 'paid') {
                    cardGradient = LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  } else {
                    cardGradient = LinearGradient(
                      colors: [Colors.grey[600]!, Colors.grey[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  }

                  return Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: cardGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          'Fee Period: ${formatDate(record['fee_period_start'])} -> ${formatDate(record['fee_period_end'])}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Status: ${record['payment_status'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FeeRecordDetailScreen(feeRecord: record),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}