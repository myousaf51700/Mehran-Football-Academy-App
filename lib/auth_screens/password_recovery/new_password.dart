import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../my_components/my_textfields.dart';
import '../../my_components/round_button.dart';

class NewPassword extends StatefulWidget {
  const NewPassword({super.key});

  @override
  State<NewPassword> createState() => _NewPasswordState();
}

class _NewPasswordState extends State<NewPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _supabaseClient = supabase.Supabase.instance.client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('NewPassword page initialized'); // Debug log
  }

  Future<void> _updatePassword() async {
    setState(() {
      _isLoading = true;
    });

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both fields')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters long')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('Updating password...'); // Debug log
      await _supabaseClient.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      print('Password updated successfully'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error updating password: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating password: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            const Center(
              child: Text(
                'Create New Password',
                style: TextStyle(fontSize: 18, fontFamily: 'RubikMedium'),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your new password',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'RubikRegular'),
              ),
            ),
            const SizedBox(height: 10),
            LoginTextField(
              title: 'New Password',
              controller: _newPasswordController,
              prefixIcon: Icons.lock,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 20),
            LoginTextField(
              title: 'Confirm Password',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 40),
            RoundButton(
              title: 'Confirm',
              onTap: _updatePassword,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}