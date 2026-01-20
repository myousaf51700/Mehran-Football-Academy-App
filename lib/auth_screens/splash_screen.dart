import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../players_screens/player_dashboard.dart';
import '../auth_screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () async {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Ensure user.email is not null before using it
        final String? email = user.email;
        if (email == null) {
          // Handle case where email is null (this should rarely happen but is good to check)
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }

        // Fetch the user's role from user_type table using email
        try {
          final response = await supabase
              .from('user_type')
              .select('role')
              .eq('email', email) // Use email, ensuring it's not null
              .single();

          // Access the 'role' directly from the response (PostgrestMap)
          String? role = response['role'] as String?;

          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/adminHome'); // Navigate to AdminNavBar
          } else if (role == 'player') {
            Navigator.pushReplacementNamed(context, '/playerHome'); // Navigate to PlayerDashboard
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          // Handle any errors (e.g., user not found in user_type)
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/splash.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 30,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MEHRAN FOOTBALL',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'ACADEMY',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          ' ( Islamabad )',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 250.0, bottom: 20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Lottie.asset(
                'assets/lottiefile.json',
                width: 200,
                height: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}