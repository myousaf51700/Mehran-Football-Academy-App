import 'package:flutter/material.dart';
import 'package:mehran_football_academy/my_components/round_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Assuming RoundButton is defined here

/// Supabase client (already defined in MFA main.dart, so no need to redefine)
final supabase = Supabase.instance.client;

/// Simple preloader inside a Center widget
const preloader = Center(child: CircularProgressIndicator(color: Colors.blue)); // Match MFA theme

/// Basic theme to change the look and feel of the app, aligned with MFA
final appTheme = ThemeData.light().copyWith(
  primaryColor: Colors.blue,
  appBarTheme: const AppBarTheme(
    elevation: 1,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.blue),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 18,
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: Colors.blue),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: Colors.blue,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(color: Colors.blue),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10), // Match MFA's border radius
      borderSide: const BorderSide(color: Colors.grey, width: 2),
    ),
    focusColor: Colors.blue,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.blue, width: 2),
    ),
  ),
);

/// Set of extension methods to easily display a snackbar
extension ShowSnackBar on BuildContext {
  void showSnackBar({required String message, Color backgroundColor = Colors.white}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    ));
  }

  void showErrorSnackBar({required String message}) {
    showSnackBar(message: message, backgroundColor: Colors.red);
  }
}