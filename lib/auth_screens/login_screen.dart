import 'package:flutter/material.dart';
import 'package:mehran_football_academy/auth_screens/password_recovery/enter_email.dart';
import 'package:mehran_football_academy/auth_screens/sign_up_screen.dart';
import 'package:mehran_football_academy/my_components/my_textfields.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';
import 'package:mehran_football_academy/my_components/title_items.dart';
import 'auth_services/auth_services.dart';
import '../players_screens/player_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? role = await _authService.login(_emailController.text.trim(), _passwordController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful')),
      );

      // Redirect based on role from user_type table
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminHome'); // Navigate to AdminNavBar
      } else if (role == 'player') {
        Navigator.pushReplacementNamed(context, '/playerHome'); // Navigate to PlayerDashboard
      } else {
        throw Exception('Unknown user role');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              FadeTransition(opacity: _animation, child: TitleItems()),
              const SizedBox(height: 40),
              FadeTransition(opacity: _animation, child: const Text('Login Here')),
              const SizedBox(height: 40),
              Column(
                children: [
                  FadeTransition(
                    opacity: _animation,
                    child: LoginTextField(title: 'Email', controller: _emailController, prefixIcon: Icons.email),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _animation,
                    child: PasswordTextField(title: 'Password', controller: _passwordController),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _animation,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>EnterEmail()));
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 67),
              FadeTransition(
                opacity: _animation,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : RoundButton(title: 'Login Now', onTap: login),
              ),
              const SizedBox(height: 10),
              FadeTransition(
                opacity: _animation,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text("Don't have an account?"),
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushReplacement(
                              context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                        },
                        child: const Text(
                          " Register",
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}