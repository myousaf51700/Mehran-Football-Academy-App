import 'package:flutter/material.dart';
import 'package:mehran_football_academy/admin_screens/admin_dashboard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'detailed_player_fee_record.dart';

class FeeHomeScreen extends StatefulWidget {
  const FeeHomeScreen({super.key});

  @override
  State<FeeHomeScreen> createState() => _FeeHomeScreenState();
}

class _FeeHomeScreenState extends State<FeeHomeScreen> {
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _playerFeeSummaries = [];
  List<Map<String, dynamic>> _filteredPlayerFeeSummaries = []; // Filtered list for search and sort
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _selectedSortOption = 'All'; // Default sort option

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

  // Summarize fee statuses for each player
  Future<void> _loadPlayerFeeSummaries() async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user is logged in. Please log in as admin.');
      }

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
          .order('created_at', ascending: false);

      print('Fetched fee records: $response');

      final Map<String, Map<String, dynamic>> summaries = {};
      for (var record in response) {
        final userId = record['user_id'].toString();
        if (!summaries.containsKey(userId)) {
          summaries[userId] = {
            'full_name': record['full_name'] ?? 'Unknown Player',
            'total_records': 0,
            'latest_status': '',
            'latest_fee_period_start': '',
            'latest_fee_period_end': '',
          };
        }
        summaries[userId]!['total_records'] = (summaries[userId]!['total_records'] ?? 0) + 1;

        if (summaries[userId]!['latest_status'] == '' ||
            DateTime.parse(record['created_at']).isAfter(DateTime.parse(summaries[userId]!['latest_created_at'] ?? '1970-01-01'))) {
          summaries[userId]!['latest_status'] = record['payment_status'] ?? 'Unknown';
          summaries[userId]!['latest_fee_period_start'] = formatDate(record['fee_period_start']);
          summaries[userId]!['latest_fee_period_end'] = formatDate(record['fee_period_end']);
          summaries[userId]!['latest_created_at'] = record['created_at'];
        }
      }

      _playerFeeSummaries = summaries.entries.map((entry) {
        final userId = entry.key;
        final summary = entry.value;
        return {
          'user_id': userId,
          'full_name': summary['full_name'],
          'total_records': summary['total_records'],
          'latest_status': summary['latest_status'],
          'latest_fee_period_start': summary['latest_fee_period_start'],
          'latest_fee_period_end': summary['latest_fee_period_end'],
        };
      }).toList();

      _filteredPlayerFeeSummaries = List.from(_playerFeeSummaries);
      _applySortFilter();

      setState(() {
        _isLoading = false;
      });

      if (_playerFeeSummaries.isEmpty) {
        print('No fee records found for any players');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fee summaries: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPlayers(String query) {
    setState(() {
      List<Map<String, dynamic>> tempFilteredList;

      if (query.isEmpty) {
        tempFilteredList = List.from(_playerFeeSummaries);
      } else {
        tempFilteredList = _playerFeeSummaries
            .where((summary) =>
            summary['full_name'].toString().toLowerCase().contains(query.toLowerCase()))
            .toList();
      }

      if (_selectedSortOption != 'All') {
        _filteredPlayerFeeSummaries = tempFilteredList
            .where((summary) =>
        summary['latest_status']?.toString().toLowerCase() ==
            _selectedSortOption.toLowerCase())
            .toList();
      } else {
        _filteredPlayerFeeSummaries = tempFilteredList;
      }
    });
  }

  void _applySortFilter() {
    String currentQuery = _searchController.text;
    _filterPlayers(currentQuery);
  }

  @override
  void initState() {
    super.initState();
    _loadPlayerFeeSummaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Fee Overview'),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
            //Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AdminDashboard()));
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search records',
                          hintStyle: TextStyle(color: Colors.grey[600]), // Darker grey for hint text
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]), // Darker grey for icon
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none, // No visible border
                            borderRadius: BorderRadius.circular(30.0), // Increased border radius
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide.none, // No visible border
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide.none, // No visible border
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100], // Light grey background
                          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                        ),
                        style: TextStyle(color: Colors.grey[600]), // Darker grey for input text
                        onChanged: (value) {
                          _filterPlayers(value);
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Row(
                    children: [
                      Text('Sorted By:'),
                      IconButton(
                        icon: Icon(Icons.sort),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    title: Text('All'),
                                    onTap: () {
                                      setState(() {
                                        _selectedSortOption = 'All';
                                      });
                                      _applySortFilter();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: Text('Paid'),
                                    onTap: () {
                                      setState(() {
                                        _selectedSortOption = 'Paid';
                                      });
                                      _applySortFilter();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: Text('Unpaid'),
                                    onTap: () {
                                      setState(() {
                                        _selectedSortOption = 'Unpaid';
                                      });
                                      _applySortFilter();
                                      Navigator.pop(context);
                                    },
                                  ),
                                  ListTile(
                                    title: Text('Waiting for Confirmation'),
                                    onTap: () {
                                      setState(() {
                                        _selectedSortOption = 'Waiting for Confirmation';
                                      });
                                      _applySortFilter();
                                      Navigator.pop(context);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: _filteredPlayerFeeSummaries.isEmpty
                  ? const Center(child: Text('No Such Records'))
                  : ListView.builder(
                itemCount: _filteredPlayerFeeSummaries.length,
                itemBuilder: (context, index) {
                  final summary = _filteredPlayerFeeSummaries[index];
                  LinearGradient cardGradient;
                  final paymentStatus = summary['latest_status']?.toString().toLowerCase() ?? 'unknown';
                  if (paymentStatus == 'paid') {
                    cardGradient = LinearGradient(
                      colors: [Colors.green[700]!, Colors.green[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  } else if (paymentStatus == 'unpaid') {
                    cardGradient = LinearGradient(
                      colors: [Colors.red[700]!, Colors.red[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  } else if (paymentStatus == 'waiting for confirmation') {
                    cardGradient = LinearGradient(
                      colors: [Colors.grey[600]!, Colors.grey[300]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    );
                  } else {
                    cardGradient = LinearGradient(
                      colors: [Colors.blue[700]!, Colors.blue[300]!],
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
                          summary['full_name'],
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Fee Records: ${summary['total_records']}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Latest Fee Period: ${summary['latest_fee_period_start']} -> ${summary['latest_fee_period_end']}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            Text(
                              'Latest Fee Status: ${summary['latest_status']}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailedPlayerFeeRecord(userId: summary['user_id']),
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