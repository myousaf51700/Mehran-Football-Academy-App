import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters

class LoginTextField extends StatelessWidget {
  final String title;
  final TextEditingController? controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType; // Add keyboardType parameter
  final List<TextInputFormatter>? inputFormatters; // Optional input formatters

  const LoginTextField({
    super.key,
    required this.title,
    this.controller,
    required this.prefixIcon,
    this.keyboardType, // Make it optional
    this.inputFormatters, // Make it optional
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType, // Pass the keyboardType
      inputFormatters: inputFormatters, // Pass the input formatters
      decoration: InputDecoration(
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.grey[600],
          size: 24,
        ),
        labelText: title,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blueGrey),
        ),
      ),
    );
  }
}

class PasswordTextField extends StatefulWidget {
  final String title;
  final TextEditingController? controller;

  const PasswordTextField({super.key, required this.title, this.controller});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: !_isPasswordVisible,
      keyboardType: TextInputType.visiblePassword, // Use appropriate keyboard for passwords
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.lock,
          color: Colors.grey[600],
          size: 24,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        labelText: widget.title,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blueGrey),
        ),
      ),
    );
  }
}