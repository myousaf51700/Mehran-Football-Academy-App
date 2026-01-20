import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:mehran_football_academy/auth_screens/login_screen.dart';
import 'package:mehran_football_academy/my_components/my_textfields.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';
import 'package:mehran_football_academy/my_components/title_items.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  // Controllers for text fields
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _permanentAddressController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _expressYourselfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();

  // Variable to store calculated age
  int? _calculatedAge;

  // Variables for dropdowns
  String? _selectedBloodGroup;
  String? _selectedPlayingPosition;

  // Lists for dropdown options
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Don\'t Know'
  ];
  final List<String> _playingPositions = [
    'Striker', 'Midfielder', 'Defender', 'Goalkeeper'
  ];

  late AnimationController _controller;
  late Animation<double> _animation;
  bool isLoading = false;
  final AuthService _authService = AuthService();
  final SupabaseClient _supabase = Supabase.instance.client;

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
    _fullNameController.dispose();
    _fatherNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _permanentAddressController.dispose();
    _currentAddressController.dispose();
    _expressYourselfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  // Function to calculate age from birth date
  int calculateAge(DateTime birthDate) {
    DateTime currentDate = DateTime.now();
    int age = currentDate.year - birthDate.year;
    // Adjust age if the birthday hasn't occurred this year
    if (currentDate.month < birthDate.month ||
        (currentDate.month == birthDate.month && currentDate.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Function to generate position-specific stats
  Map<String, dynamic> generatePositionSpecificStats(String position) {
    switch (position) {
      case 'Striker':
        return {
          'shots_on_target': 0,
          'shots_attempted': 0,
          'penalties_taken': 0,
          'penalties_scored': 0,
          'headed_goals': 0,
        };
      case 'Midfielder':
        return {
          'key_passes': 0,
          'chances_created': 0,
          'total_crosses': 0,
          'ball_recoveries': 0,
          'dribbles_completed': 0,
          'tackles_made': 0,
        };
      case 'Defender':
        return {
          'successive_tackles_made': 0,
          'interceptions': 0,
          'blocks_inside_box': 0,
        };
      case 'Goalkeeper':
        return {
          'total_saves': 0,
          'goals_conceded': 0,
          'clean_sheets': 0,
          'penalties_faced': 0,
          'penalties_saved': 0,
          'total_long_passes': 0,
        };
      default:
        return {};
    }
  }

  Future<void> signUp() async {
    if (_fullNameController.text.trim().isEmpty ||
        _fatherNameController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _selectedBloodGroup == null ||
        _permanentAddressController.text.trim().isEmpty ||
        _currentAddressController.text.trim().isEmpty ||
        _selectedPlayingPosition == null ||
        _expressYourselfController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty ||
        _birthDateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_calculatedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid birth date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if email exists in allowed_players table
      bool emailAllowed = await _authService.checkEmailInAllowedPlayers(_emailController.text.trim());
      if (!emailAllowed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email not allowed. Please contact the admin to add your email.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Additional check: Verify if email already exists in players_records
      final existingPlayer = await _supabase
          .from('players_records')
          .select('email')
          .eq('email', _emailController.text.trim())
          .maybeSingle();

      if (existingPlayer != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('There is another player with this email. Please use a different email.')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final AuthResponse userResponse = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
        fatherName: _fatherNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        bloodGroup: _selectedBloodGroup!,
        permanentAddress: _permanentAddressController.text.trim(),
        currentAddress: _currentAddressController.text.trim(),
        playingPosition: _selectedPlayingPosition!,
        expressYourself: _expressYourselfController.text.trim(),
        playerAge: _calculatedAge!, // Pass calculated age
        birthDate: _birthDateController.text.trim(), // Pass birth date
      );

      if (userResponse.user != null) {
        final userId = userResponse.user!.id;
        await _supabase.from('profiles').insert({
          'id': userId,
          'full_name': _fullNameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        });

        final createdAt = DateTime.now();
        final feePeriodEnd = createdAt.add(Duration(days: 30));

        // Apply fee logic based on calculated age
        double feeAmount;
        if (_calculatedAge! <= 10) {
          feeAmount = 1000.00;
        } else if (_calculatedAge! <= 15) {
          feeAmount = 1500.00;
        } else {
          feeAmount = 2000.00;
        }

        await _supabase.from('fee_records').insert({
          'user_id': userId,
          'fee_amount': feeAmount,
          'payment_status': 'unpaid',
          'fee_period_start': createdAt.toIso8601String().split('T')[0],
          'fee_period_end': feePeriodEnd.toIso8601String().split('T')[0],
          'created_at': createdAt.toIso8601String(),
          'updated_at': createdAt.toIso8601String(),
          'full_name': _fullNameController.text.trim(),
        });

        // Insert into player_statistics with position-specific stats
        await _supabase.from('player_statistics').insert({
          'user_id': userId,
          'full_name': _fullNameController.text.trim(),
          'position': _selectedPlayingPosition!,
          'matches_played': 0,
          'minutes_played': 0,
          'red_card_received': 0,
          'yellow_card_received': 0,
          'total_goals': 0,
          'total_assists': 0,
          'position_specific_stats': generatePositionSpecificStats(_selectedPlayingPosition!),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up successful! Please login now')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during signup: $e')),
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: FadeTransition(
              opacity: _animation,
              child: TitleItems(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _animation,
                      child: const Text('Sign Up Here'),
                    ),
                    const SizedBox(height: 40),
                    Column(
                      children: [
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Full Name',
                            controller: _fullNameController,
                            prefixIcon: Icons.person,
                            keyboardType: TextInputType.name,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Father Name',
                            controller: _fatherNameController,
                            prefixIcon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Contact Number',
                            controller: _contactNumberController,
                            prefixIcon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Email',
                            controller: _emailController,
                            prefixIcon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Blood Group',
                              prefixIcon: Icon(Icons.bloodtype),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _selectedBloodGroup,
                            items: _bloodGroups.map((String group) {
                              return DropdownMenuItem<String>(
                                value: group,
                                child: Text(group),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedBloodGroup = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Permanent Address',
                            controller: _permanentAddressController,
                            prefixIcon: Icons.home,
                            keyboardType: TextInputType.streetAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: LoginTextField(
                            title: 'Current Address',
                            controller: _currentAddressController,
                            prefixIcon: Icons.location_on,
                            keyboardType: TextInputType.streetAddress,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Playing Position',
                              prefixIcon: Icon(Icons.sports_soccer),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _selectedPlayingPosition,
                            items: _playingPositions.map((String position) {
                              return DropdownMenuItem<String>(
                                value: position,
                                child: Text(position),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedPlayingPosition = newValue;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: GestureDetector(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _birthDateController.text = pickedDate.toString().split(' ')[0]; // Format as YYYY-MM-DD
                                  _calculatedAge = calculateAge(pickedDate); // Calculate age
                                });
                              }
                            },
                            child: AbsorbPointer(
                              child: LoginTextField(
                                title: 'Birth Date (YYYY-MM-DD)',
                                controller: _birthDateController,
                                prefixIcon: Icons.cake,
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: PasswordTextField(
                            title: 'Password',
                            controller: _passwordController,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: PasswordTextField(
                            title: 'Confirm Password',
                            controller: _confirmPasswordController,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeTransition(
                          opacity: _animation,
                          child: TextField(
                            controller: _expressYourselfController,
                            maxLines: 3,
                            maxLength: 150,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              labelText: 'Express Yourself',
                              prefixIcon: Icon(Icons.message),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _animation,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Forgot Password?',
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              children: [
                FadeTransition(
                  opacity: _animation,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : RoundButton(title: 'Sign Up Now', onTap: signUp),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _animation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text("Already have an account?"),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          child: const Text(
                            " Login",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}