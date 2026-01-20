import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:intl/intl.dart'; // For date formatting

class DetailedPlayerFeeRecord extends StatefulWidget {
  final String userId;

  const DetailedPlayerFeeRecord({super.key, required this.userId});

  @override
  State<DetailedPlayerFeeRecord> createState() => _DetailedPlayerFeeRecordState();
}

class _DetailedPlayerFeeRecordState extends State<DetailedPlayerFeeRecord> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _feeRecords = [];
  String _fullName = 'Unknown Player'; // Store the player's full name
  bool _isLoading = true;
  Map<String, dynamic>? _selectedRecord; // Track the selected record for detailed view
  bool _isUpdatingStatus = false; // Track status update loading state

  // Function to format date from YYYY-MM-DD or ISO 8601 to Month Day, Year
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      // Handle ISO 8601 format (e.g., "2025-03-11T21:16:25.277+00:00")
      final datePart = dateStr.contains('T') ? dateStr.split('T')[0] : dateStr;
      final date = DateTime.parse(datePart);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return 'N/A';
    }
  }

  Future<void> _loadFeeRecords() async {
    try {
      // Verify admin role
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user is logged in. Please log in as admin.');
      }

      // Fetch all fee records for the specific user
      final response = await _supabase
          .from('fee_records')
          .select('''
            id,
            user_id,
            fee_amount,
            payment_status,
            payment_date,
            fee_period_start,
            fee_period_end,
            created_at,
            updated_at,
            payment_proof_url,
            full_name
          ''')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      print('Fetched fee records for user ${widget.userId}: $response');

      // Extract full name from the first record
      if (response.isNotEmpty) {
        _fullName = response[0]['full_name'] ?? 'Unknown Player';
      }

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

  // Function to update payment status and payment_date
  Future<void> _updatePaymentStatus(String newStatus) async {
    if (_selectedRecord == null) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final recordId = _selectedRecord!['id'];
      // Format the current date as "March 23, 2025" when status is updated to "paid"
      String? paymentDate = newStatus.toLowerCase() == 'paid'
          ? DateFormat('MMMM d, yyyy').format(DateTime.now())
          : _selectedRecord!['payment_date']; // Keep existing date for other statuses

      await _supabase
          .from('fee_records')
          .update({
        'payment_status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
        'payment_date': paymentDate, // Update payment_date only for "paid" status
      })
          .eq('id', recordId);

      // Update the local state to reflect the change
      setState(() {
        _selectedRecord!['payment_status'] = newStatus;
        _selectedRecord!['updated_at'] = DateTime.now().toIso8601String();
        _selectedRecord!['payment_date'] = paymentDate; // Update local payment_date
        // Update the original record in the list
        final index = _feeRecords.indexWhere((record) => record['id'] == recordId);
        if (index != -1) {
          _feeRecords[index]['payment_status'] = newStatus;
          _feeRecords[index]['updated_at'] = DateTime.now().toIso8601String();
          _feeRecords[index]['payment_date'] = paymentDate; // Update list payment_date
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment status updated to $newStatus successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update payment status: $e')),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFeeRecords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('All Fee Records For $_fullName'),
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
              child: _selectedRecord == null
                  ? _feeRecords.isEmpty
                  ? const Center(child: Text('No Such Records'))
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Amount: ${record['fee_amount']?.toString() ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Payment Status: ${record['payment_status'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Payment Date: ${formatDate(record['payment_date'])}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Created At: ${formatDate(record['created_at'])}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Updated At: ${formatDate(record['updated_at'])}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                        onTap: () {
                          setState(() {
                            _selectedRecord = record;
                          });
                        },
                      ),
                    ),
                  );
                },
              )
                  : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 50),
                    Align(
                      alignment: Alignment.topCenter,
                      child: const Text(
                        'Detailed Slip',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Full Name: ${_selectedRecord!['full_name'] ?? 'N/A'}'),
                            const SizedBox(height: 10),
                            Text('Fee Amount: ${_selectedRecord!['fee_amount']?.toString() ?? 'N/A'}'),
                            const SizedBox(height: 10),
                            Text('Payment Status: ${_selectedRecord!['payment_status'] ?? 'N/A'}'),
                            const SizedBox(height: 10),
                            Text('Payment Date: ${formatDate(_selectedRecord!['payment_date'])}'),
                            const SizedBox(height: 10),
                            Text('Fee Period Start: ${formatDate(_selectedRecord!['fee_period_start'])}'),
                            const SizedBox(height: 10),
                            Text('Fee Period End: ${formatDate(_selectedRecord!['fee_period_end'])}'),
                            const SizedBox(height: 10),
                            Text('Created At: ${formatDate(_selectedRecord!['created_at'])}'),
                            const SizedBox(height: 10),
                            Text('Updated At: ${formatDate(_selectedRecord!['updated_at'])}'),
                            if (_selectedRecord!['payment_proof_url'] != null &&
                                _selectedRecord!['payment_status']?.toString().toLowerCase() == 'waiting for confirmation')
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Image.network(_selectedRecord!['payment_proof_url']),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Show "Fee Paid" button for unpaid status
                    if (_selectedRecord!['payment_status']?.toString().toLowerCase() == 'unpaid')
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _isUpdatingStatus
                                  ? null
                                  : () => _updatePaymentStatus('paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size(120, 40),
                              ),
                              child: _isUpdatingStatus
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                'Fee Paid',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Show "Confirm" and "Reject" buttons for "waiting for confirmation" status
                    if (_selectedRecord!['payment_status']?.toString().toLowerCase() == 'waiting for confirmation')
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isUpdatingStatus
                                  ? null
                                  : () => _updatePaymentStatus('paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size(120, 40),
                              ),
                              child: _isUpdatingStatus
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                'Confirm',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _isUpdatingStatus
                                  ? null
                                  : () => _updatePaymentStatus('unpaid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                minimumSize: const Size(120, 40),
                              ),
                              child: _isUpdatingStatus
                                  ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text(
                                'Reject',
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Show the "Back" button only if the status is not "waiting for confirmation"
                    if (_selectedRecord!['payment_status']?.toString().toLowerCase() != 'waiting for confirmation')
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedRecord = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(120, 40),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}