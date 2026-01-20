import 'package:flutter/material.dart';

class AdminFabMenu extends StatelessWidget {
  final VoidCallback onFileTap;
  final VoidCallback onAnnouncementTap;
  final VoidCallback onMatchTap; // Added callback for Match

  const AdminFabMenu({
    super.key,
    required this.onFileTap,
    required this.onAnnouncementTap,
    required this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return _FloatingActionButtonMenu(
      onFileTap: onFileTap,
      onAnnouncementTap: onAnnouncementTap,
      onMatchTap: onMatchTap,
    );
  }
}

class _FloatingActionButtonMenu extends StatefulWidget {
  final VoidCallback onFileTap;
  final VoidCallback onAnnouncementTap;
  final VoidCallback onMatchTap;

  const _FloatingActionButtonMenu({
    required this.onFileTap,
    required this.onAnnouncementTap,
    required this.onMatchTap,
  });

  @override
  _FloatingActionButtonMenuState createState() => _FloatingActionButtonMenuState();
}

class _FloatingActionButtonMenuState extends State<_FloatingActionButtonMenu> with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  OverlayEntry? _overlayEntry;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });

    if (_isMenuOpen) {
      _animationController.forward();
      _showOverlay(context);
    } else {
      _animationController.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }

  void _showOverlay(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset fabPosition = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleMenu,
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            right: 16.0,
            bottom: 100.0, // Increased to avoid overlap with bottom navigation
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FloatingActionButton(
                      mini: true, // Smaller size
                      heroTag: 'announcement_fab',
                      onPressed: () {
                        _toggleMenu();
                        widget.onAnnouncementTap();
                      },
                      backgroundColor: Colors.white,
                      tooltip: 'Announcement',
                      shape: const CircleBorder(), // Ensures circular shape
                      child: const Icon(Icons.campaign, color: Color(0xff3E8530), size: 20), // Smaller icon size
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FloatingActionButton(
                      mini: true, // Smaller size
                      heroTag: 'match_fab',
                      onPressed: () {
                        _toggleMenu();
                        widget.onMatchTap();
                      },
                      backgroundColor: Colors.white,
                      tooltip: 'Schedule Match',
                      shape: const CircleBorder(), // Ensures circular shape
                      child: const Icon(Icons.event, color: Colors.blueAccent, size: 20), // Smaller icon size
                    ),
                  ),
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FloatingActionButton(
                      mini: true, // Smaller size
                      heroTag: 'file_fab',
                      onPressed: () {
                        _toggleMenu();
                        widget.onFileTap();
                      },
                      backgroundColor: Colors.white,
                      tooltip: 'Upload File',
                      shape: const CircleBorder(), // Ensures circular shape
                      child: const Icon(Icons.upload_file, color: Colors.grey, size: 20), // Smaller icon size
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'main_fab',
      onPressed: _toggleMenu,
      backgroundColor: Colors.blueAccent,
      shape: CircleBorder(),
      tooltip: 'Add Content',
      child: Icon(
        _isMenuOpen ? Icons.close : Icons.add,
        color: Colors.white,
      ),
    );
  }
}