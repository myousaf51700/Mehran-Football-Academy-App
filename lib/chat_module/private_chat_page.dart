import 'package:flutter/material.dart';
import 'package:mehran_football_academy/auth_screens/auth_services/auth_services.dart';
import 'package:mehran_football_academy/chat_module/models/message.dart';
import 'package:mehran_football_academy/chat_module/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:intl/intl.dart';

class PrivateChatPage extends StatefulWidget {
  final Profile receiverProfile;
  const PrivateChatPage({super.key, required this.receiverProfile});

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Stream<List<Message>> _messagesStream;
  final Set<String> _pendingMessageIds = {};
  List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _initializeMessagesStream();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _initializeMessagesStream() {
    final currentUserId = _authService.getCurrentUser()!.id;
    final receiverId = widget.receiverProfile.id;

    _messagesStream = supabase.Supabase.instance.client
        .from('private_messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) {
      final messages = maps.map((map) => Message.fromMap(map: map, myUserId: currentUserId)).toList();

      final filteredMessages = messages.where((message) {
        final senderId = message.profileId;
        final receiverIdFromMap = maps.firstWhere(
              (m) => m['id'] == message.id,
          orElse: () => {},
        )['receiver_id'] as String?;

        return (senderId == currentUserId && receiverIdFromMap == receiverId) ||
            (senderId == receiverId && receiverIdFromMap == currentUserId);
      }).toList();

      _pendingMessageIds.removeWhere((pendingId) =>
          filteredMessages.any((msg) => msg.id == pendingId));

      setState(() {
        _messages = filteredMessages;
      });

      _scrollToBottom();
      return filteredMessages;
    }).handleError((error) {
      debugPrint('Stream error: $error');
      return _messages;
    });
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
      _messages.add(newMessage);
      _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await supabase.Supabase.instance.client
          .from('private_messages')
          .insert({
        'sender_id': currentUserId,
        'receiver_id': widget.receiverProfile.id,
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
        _messages.removeWhere((m) => m.id == tempId);
        _messages.add(confirmedMessage);
        _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      setState(() {
        _pendingMessageIds.remove(tempId);
        _messages.removeWhere((m) => m.id == tempId);
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
      appBar: AppBar(
        title: Text(widget.receiverProfile.full_name, style: const TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                final messages = snapshot.hasData ? snapshot.data! : _messages;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isPending = _pendingMessageIds.contains(message.id);

                    return _ChatBubble(
                      message: message,
                      profile: widget.receiverProfile,
                      isPending: isPending,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Message message;
  final Profile? profile;
  final bool isPending;

  const _ChatBubble({
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Row(
          mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMine) const SizedBox(width: 12),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: message.isMine ? Colors.green.shade200 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message.content),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formattedTime,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (message.isMine) const SizedBox(width: 12),
            if (isPending && message.isMine)
              const Padding(
                padding: EdgeInsets.only(left: 4),
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