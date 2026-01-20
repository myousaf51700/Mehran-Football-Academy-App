import 'package:flutter/material.dart';
class PlayerCollection extends StatefulWidget {
  const PlayerCollection({super.key});

  @override
  State<PlayerCollection> createState() => _PlayerCollectionState();
}

class _PlayerCollectionState extends State<PlayerCollection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Removed bottomNavigationBar: PlayerNavBar() to rely on PlayerNavBar via routes
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text('Player Collection screen'))
        ],
      ),
    );
  }
}