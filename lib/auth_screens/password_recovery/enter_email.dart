import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../my_components/my_textfields.dart';
import '../../my_components/round_button.dart';

class EnterEmail extends StatefulWidget {
  const EnterEmail({super.key});

  @override
  State<EnterEmail> createState() => _EnterEmailState();
}

class _EnterEmailState extends State<EnterEmail> {
  final TextEditingController _emailController = TextEditingController();
  final _supabaseClient = supabase.Supabase.instance.client;
  bool _isLoading = false;

  Future<void> _sendResetLink() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      print('Sending reset link to email: $email'); // Debug log
      await _supabaseClient.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.mehranfootballacademy://reset-password',
      );
      print('Reset link sent successfully'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reset link sent to your email. Please check your inbox.')),
      );
      // Navigate back to login after a delay
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error sending reset link: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending reset link: ${e.toString()}')),
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
                'Forgot Password?',
                style: TextStyle(fontSize: 18, fontFamily: 'RubikMedium'),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your email address',
                style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'RubikRegular'),
              ),
            ),
            const SizedBox(height: 10),
            LoginTextField(
              title: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 40),
            RoundButton(
              title: 'Send Link',
              onTap: _sendResetLink,
              loading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}