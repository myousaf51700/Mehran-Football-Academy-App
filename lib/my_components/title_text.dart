import 'package:flutter/material.dart';

class TitleText extends StatelessWidget {
  final String text;

  const TitleText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontFamily: 'RubikMedium',
          fontSize: 20,
        ),
      ),
    );
  }
}
