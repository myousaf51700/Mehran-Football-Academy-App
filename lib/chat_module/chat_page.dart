import 'package:flutter/material.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:mehran_football_academy/chat_module/models/message.dart';
import 'package:mehran_football_academy/chat_module/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mehran_football_academy/utils/local_storage.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Message>> _messagesStream;
  final Set<String> _pendingMessageIds = {};
  List<Message> _cachedMessages = [];
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _initializeMessagesStream();
    _checkConnectivity();
  }

  Future<void> _loadCachedData() async {
    final cachedMessages = LocalStorage.getCachedMessages();
    setState(() {
      _cachedMessages = cachedMessages;
    });
    _scrollToBottom();
  }

  void _initializeMessagesStream() {
    final myUserId = _authService.getCurrentUser()!.id;
    _messagesStream = supabase.Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) {
      final messages = maps.map((map) => Message.fromMap(map: map, myUserId: myUserId)).toList();
      LocalStorage.saveMessages(messages);

      _pendingMessageIds.removeWhere((pendingId) =>
          messages.any((msg) => msg.id == pendingId));

      setState(() {
        _cachedMessages = messages;
      });

      _scrollToBottom();
      return messages;
    }).handleError((error) {
      debugPrint('Stream error: $error');
      setState(() {
        _cachedMessages = LocalStorage.getCachedMessages();
      });
      return _cachedMessages;
    });
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
    if (_isOffline) {
      _loadCachedData();
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUserId = _authService.getCurrentUser()!.id;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final newMessage = Message(
      id: tempId,
      profileId: currentUserId,
      content: _messageController.text.trim(),
      createdAt: DateTime.now().toUtc(), // Store in UTC
      isMine: true,
    );

    setState(() {
      _pendingMessageIds.add(tempId);
      _cachedMessages.add(newMessage);
      _cachedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    _messageController.clear();
    _scrollToBottom();

    if (_isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are offline. Message will be sent when online.')),
      );
      return;
    }

    try {
      final response = await supabase.Supabase.instance.client
          .from('messages')
          .insert({
        'profile_id': currentUserId,
        'content': newMessage.content,
      })
          .select()
          .single();

      final confirmedMessage = Message.fromMap(
        map: response,
        myUserId: currentUserId,
      );

      setState(() {
        _pendingMessageIds.remove(tempId);
        _cachedMessages.removeWhere((m) => m.id == tempId);
        _cachedMessages.add(confirmedMessage);
        _cachedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      setState(() {
        _pendingMessageIds.remove(tempId);
        _cachedMessages.removeWhere((m) => m.id == tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  final messages = snapshot.hasData && !_isOffline
                      ? snapshot.data!
                      : _cachedMessages;

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isPending = _pendingMessageIds.contains(message.id);

                      return FutureBuilder<Profile?>(
                        future: _isOffline
                            ? Future.value(LocalStorage.getProfileById(message.profileId))
                            : supabase.Supabase.instance.client
                            .from('profiles')
                            .select()
                            .eq('id', message.profileId)
                            .single()
                            .then((value) => Profile.fromMap(value))
                            .catchError((_) => null),
                        builder: (context, profileSnapshot) {
                          return ChatBubble(
                            message: message,
                            profile: profileSnapshot.data,
                            isPending: isPending,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final Message message;
  final Profile? profile;
  final bool isPending;

  const ChatBubble({
    super.key,
    required this.message,
    required this.profile,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final localTime = message.createdAt.toUtc().add(const Duration(hours: 5)); // Convert to PKT (UTC+5)
    final formattedTime = timeFormat.format(localTime);

    return Opacity(
      opacity: isPending ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (profile != null && !message.isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  profile!.full_name,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: message.isMine ? Colors.green.shade200 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(message.content),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (isPending)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}