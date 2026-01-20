import 'package:flutter/material.dart';
class TitleItems extends StatelessWidget {
  const TitleItems({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: AssetImage('assets/logo1.png'),
          backgroundColor: Colors.transparent, // Ensures no unwanted background color
        ),
        Column(
          children: [
            Text(
              'Mehran Football',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Academy',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' Islamabad',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
