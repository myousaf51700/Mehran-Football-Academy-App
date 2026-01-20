import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this package to your pubspec.yaml

class AddPlayerEmails extends StatefulWidget {
  const AddPlayerEmails({super.key});

  @override
  State<AddPlayerEmails> createState() => _AddPlayerEmailsState();
}

class _AddPlayerEmailsState extends State<AddPlayerEmails> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Initialize Supabase client (replace with your Supabase URL and anon key)
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Method to check if an email already exists in allowed_players table
  Future<bool> _checkEmailExists(String email) async {
    try {
      final response = await supabase
          .from('allowed_players')
          .select('emails')
          .eq('emails', email.trim())
          .maybeSingle();
      return response != null; // Returns true if email exists, false otherwise
    } catch (e) {
      throw Exception('Error checking email existence: $e');
    }
  }

  // Method to insert emails into allowed_players table
  Future<void> _addPlayerEmails() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _successMessage = null;
      });

      try {
        // Split the input by commas, newlines, or semicolons to handle multiple emails
        List<String> emails = _emailController.text
            .split(RegExp(r'[,\n;]'))
            .map((email) => email.trim())
            .where((email) => email.isNotEmpty)
            .toList();

        List<String> addedEmails = [];
        List<String> skippedEmails = [];

        // Check and insert each email
        for (String email in emails) {
          bool emailExists = await _checkEmailExists(email);
          if (emailExists) {
            skippedEmails.add(email);
          } else {
            await supabase.from('allowed_players').insert({
              'emails': email,
            });
            addedEmails.add(email);
          }
        }

        // Prepare the success message
        String message = '';
        if (addedEmails.isNotEmpty) {
          message += 'Added emails: ${addedEmails.join(", ")}';
        }
        if (skippedEmails.isNotEmpty) {
          if (message.isNotEmpty) message += '\n';
          message += 'Skipped emails (already exist): ${skippedEmails.join(", ")}';
        }
        if (message.isEmpty) {
          message = 'No new emails were added.';
        }

        setState(() {
          _successMessage = message;
        });

        // Clear the text field if at least one email was added
        if (addedEmails.isNotEmpty) {
          _emailController.clear();
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error adding emails: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Enter Player Email(s)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    hintText: 'Enter emails (separate multiple with commas, newlines, or semicolons)',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    suffixIcon: Icon(Icons.email, color: Colors.blue.shade600),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter at least one email';
                    }
                    // Basic email validation
                    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    List<String> emails = value
                        .split(RegExp(r'[,\n;]'))
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    for (String email in emails) {
                      if (!emailRegExp.hasMatch(email)) {
                        return 'Please enter valid email(s)';
                      }
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  SizedBox(height: 10),
                  Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                if (_successMessage != null) ...[
                  SizedBox(height: 10),
                  Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addPlayerEmails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFEAC104),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Add Emails',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}