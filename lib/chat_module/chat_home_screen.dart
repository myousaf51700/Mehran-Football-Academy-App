import 'package:flutter/material.dart';
import 'package:mehran_football_academy/chat_module/chat_page.dart';
import 'package:mehran_football_academy/chat_module/users_page.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              const SizedBox(width: 16.0),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.group,
                            color: _currentPage == 0 ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Group Chat',
                            style: TextStyle(
                              color: _currentPage == 0 ? Colors.blue : Colors.grey,
                              fontSize: 12,
                              fontFamily: 'RubikMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48.0),
                    GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            color: _currentPage == 1 ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            'Players',
                            style: TextStyle(
                              color: _currentPage == 1 ? Colors.blue : Colors.grey,
                              fontSize: 12,
                              fontFamily: 'RubikMedium',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: const [
              ChatPage(),
              UsersPage(), // Keep UsersPage alive
            ],
          ),
        ),
      ],
    );
  }
}