import 'package:flutter/material.dart';
class RoundButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;

  const RoundButton({
    Key? key,
    required this.title,
    required this.onTap,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap, // Disable onTap when loading
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xff3E8530),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: loading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'RubikRegular',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class RoundWhiteButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool loading;
  const RoundWhiteButton({
    Key? key,
    required this.title,
    this.loading = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color(0xff0662aa),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Color(0xff0662aa),
            width: 1, // Outline width
          ),
        ),
        child: Center(
          child: loading
              ? CircularProgressIndicator()
              : Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'RubikRegular',
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}