import 'package:flutter/material.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:mehran_football_academy/chat_module/private_chat_page.dart';
import 'package:mehran_football_academy/chat_module/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:timeago/timeago.dart' as timeago;
import 'package:mehran_football_academy/utils/local_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with AutomaticKeepAliveClientMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  late Stream<List<Profile>> _usersStream;
  final Map<String, Map<String, dynamic>> _latestMessagesCache = {};
  List<Profile> _cachedProfiles = [];
  bool _isOffline = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true; // Keep the state alive across tab switches

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkConnectivity();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _loadCachedProfiles();
    _initializeUsersStream();

    setState(() => _isLoading = false);
  }

  Future<void> _loadCachedProfiles() async {
    try {
      final cachedProfiles = LocalStorage.getCachedProfiles();
      if (cachedProfiles.isNotEmpty && _cachedProfiles.isEmpty) {
        setState(() {
          _cachedProfiles = cachedProfiles;
        });
      }
    } catch (e) {
      debugPrint('Error loading cached profiles: $e');
      setState(() {
        _errorMessage = 'Failed to load cached profiles';
      });
    }
  }

  void _initializeUsersStream() {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
      });
      return;
    }

    _usersStream = supabase.Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .map((maps) {
      try {
        final profiles = maps
            .map((map) => Profile.fromMap(map))
            .where((profile) => profile.id != currentUser.id)
            .toList();

        if (profiles.isNotEmpty) {
          LocalStorage.saveProfiles(profiles);
          if (!_isOffline) {
            for (final profile in profiles) {
              _getLatestMessage(profile.id);
            }
          }
          if (_cachedProfiles.isEmpty) {
            setState(() {
              _cachedProfiles = profiles;
            });
          }
        }

        return profiles;
      } catch (e) {
        debugPrint('Error mapping profiles: $e');
        throw e;
      }
    })
        .handleError((error, stackTrace) {
      debugPrint('Users stream error: $error\nStackTrace: $stackTrace');
      if (_cachedProfiles.isEmpty) {
        setState(() {
          _errorMessage = 'Failed to fetch users: $error';
          _cachedProfiles = LocalStorage.getCachedProfiles();
        });
      }
      return _cachedProfiles;
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });

    if (!_isOffline && _cachedProfiles.isNotEmpty) {
      for (final profile in _cachedProfiles) {
        _getLatestMessage(profile.id);
      }
    }
  }

  Future<void> _getLatestMessage(String receiverId) async {
    try {
      if (!_isOffline) {
        final currentUser = _authService.getCurrentUser();
        if (currentUser == null) return;

        final response = await supabase.Supabase.instance.client
            .from('private_messages')
            .select('content, created_at, sender_id')
            .or(
            'and(sender_id.eq.${currentUser.id},receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.${currentUser.id})')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          setState(() {
            _latestMessagesCache[receiverId] = response;
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting latest message: $e');
    }
  }

  String _getMessageSubtitle(Profile user) {
    final message = _latestMessagesCache[user.id];
    if (message == null) return 'No messages';

    final senderId = message['sender_id'] as String;
    final isMe = senderId == _authService.getCurrentUser()?.id;
    final senderName = isMe ? 'You' : user.full_name;
    final content = message['content'] as String;
    final createdAt = DateTime.parse(message['created_at'] as String);

    return '$senderName: $content â€¢ ${timeago.format(createdAt)}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.normal,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Colors.blueAccent, width: 3),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
              onChanged: (value) => setState(() {}),
              style: const TextStyle(color: Colors.black, fontSize: 16),
              cursorColor: Colors.blueAccent,
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: StreamBuilder<List<Profile>>(
                stream: _usersStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  final users = snapshot.hasData && snapshot.data!.isNotEmpty
                      ? snapshot.data!
                      : _cachedProfiles;

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isOffline
                                ? 'No cached users available offline'
                                : 'No users found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final filteredUsers = users
                      .where((user) => user.full_name
                      .toLowerCase()
                      .contains(_searchController.text.toLowerCase()))
                      .toList();

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return ListTile(
                        title: Text(
                          user.full_name,
                          style: const TextStyle(color: Colors.black),
                        ),
                        subtitle: Text(
                          _getMessageSubtitle(user),
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrivateChatPage(receiverProfile: user),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Offline - Showing cached data',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}