import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  // Updated signUp method to include playerAge and birthDate parameters
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String fatherName,
    required String contactNumber,
    required String bloodGroup,
    required String permanentAddress,
    required String currentAddress,
    required String playingPosition,
    required String expressYourself,
    required int playerAge, // Added parameter
    required String birthDate, // Added parameter
  }) async {
    try {
      // Check if email exists in allowed_players
      bool emailAllowed = await checkEmailInAllowedPlayers(email);
      if (!emailAllowed) {
        throw Exception('Email not allowed. Please contact the admin to add your email.');
      }

      // Sign up the user with Supabase Auth
      final AuthResponse response = await supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );
      if (response.user == null) {
        throw Exception('Sign-up failed: User not created');
      }

      // After successful sign-up, add the user to user_type table with role 'player'
      await supabase.from('user_type').insert({
        'id': response.user!.id.hashCode,
        'email': email.trim(),
        'role': 'player',
      });

      // Insert additional user information into players_records table with playerAge and birthDate
      await supabase.from('players_records').insert({
        'user_id': response.user!.id, // Link to auth.users
        'full_name': fullName.trim(),
        'father_name': fatherName.trim(),
        'contact_number': contactNumber.trim(),
        'email': email.trim(),
        'blood_group': bloodGroup,
        'permanent_address': permanentAddress.trim(),
        'current_address': currentAddress.trim(),
        'playing_position': playingPosition,
        'express_yourself': expressYourself.trim(),
        'profile_url': null, // Initially null
        'player_age': playerAge, // Added
        'birth_date': birthDate, // Added
        'created_at': DateTime.now().toIso8601String(),
      });

      return response; // Return the AuthResponse
    } on AuthException catch (e) {
      throw Exception('Sign-up failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during sign-up: $e');
    }
  }

  // Login with email and password
  Future<String?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (response.user == null) {
        throw Exception('Login failed: Invalid credentials');
      }

      // Fetch the user's role from user_type table using email
      String? role = await getUserRole(email);
      return role;
    } on AuthException catch (e) {
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during login: $e');
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Sign-out failed: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred during sign-out: $e');
    }
  }

  // Get the current user
  User? getCurrentUser() {
    final user = supabase.auth.currentUser;
    return user;
  }

  // Check if email exists in allowed_players table
  Future<bool> checkEmailInAllowedPlayers(String email) async {
    try {
      final response = await supabase.from('allowed_players').select('emails').eq('emails', email.trim()).single();
      return response['emails'] != null;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return false;
      }
      throw Exception('Failed to check email in allowed_players: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while checking email in allowed_players: $e');
    }
  }

  // Get user's role from user_type table using email
  Future<String?> getUserRole(String email) async {
    try {
      final response = await supabase.from('user_type').select('role').eq('email', email.trim()).single();
      return response['role'] as String?;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return null;
      }
      throw Exception('Failed to fetch user role: ${e.message}');
    } catch (e) {
      throw Exception('An error occurred while fetching user role: $e');
    }
  }

  // Method to delete user by calling the Edge Function
  Future<void> deleteUser(String userId, String userEmail) async {
    try {
      final url = 'https://muxyklfwehoeifagwmzg.supabase.co/functions/v1/delete-user';
      final session = supabase.auth.currentSession;
      if (session == null || session.accessToken == null) {
        throw Exception('No valid session found. Please log in again.');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'userId': userId,
          'email': userEmail.trim(),
        }),
      );

      if (response.statusCode == 200) {
        // No action needed on success
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Failed to delete user: $error');
      }
    } catch (e) {
      rethrow; // Rethrow the exception to be caught by the calling method
    }
  }
}