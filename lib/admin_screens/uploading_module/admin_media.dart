import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminMedia extends StatefulWidget {
  const AdminMedia({super.key});

  @override
  State<AdminMedia> createState() => _AdminMediaState();
}

class _AdminMediaState extends State<AdminMedia> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> mediaList = [];
  Map<String, bool> userLikes = {};
  Map<String, List<Map<String, dynamic>>> commentsCache = {};
  Map<String, String> userNamesCache = {};
  bool _isDataLoaded = false;
  final Duration cacheDuration = const Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkUserLikes();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedMediaList = prefs.getString('mediaList');
    final String? cachedComments = prefs.getString('commentsCache');
    final String? cachedUserNames = prefs.getString('userNamesCache');
    final int? lastFetchTimestamp = prefs.getInt('lastFetchTimestamp');

    final now = DateTime.now().millisecondsSinceEpoch;
    final cacheExpired = lastFetchTimestamp == null ||
        (now - lastFetchTimestamp) > cacheDuration.inMilliseconds;

    if (cachedMediaList != null &&
        cachedComments != null &&
        cachedUserNames != null &&
        !cacheExpired &&
        !_isDataLoaded) {
      print('Loading data from cache...');
      setState(() {
        mediaList = (jsonDecode(cachedMediaList) as List<dynamic>)
            .cast<Map<String, dynamic>>();
        commentsCache = (jsonDecode(cachedComments) as Map<String, dynamic>)
            .map((key, value) => MapEntry(
            key, (value as List<dynamic>).cast<Map<String, dynamic>>()));
        userNamesCache = (jsonDecode(cachedUserNames) as Map<String, dynamic>)
            .cast<String, String>();
        _isDataLoaded = true;
      });
    } else {
      print('Fetching data from network...');
      await _fetchMedia();
      if (mediaList.isNotEmpty) {
        await _fetchCommentsForAllPosts();
        await prefs.setString('mediaList', jsonEncode(mediaList));
        await prefs.setString('commentsCache', jsonEncode(commentsCache));
        await prefs.setString('userNamesCache', jsonEncode(userNamesCache));
        await prefs.setInt('lastFetchTimestamp', now);
        setState(() {
          _isDataLoaded = true;
        });
      } else {
        print('No media fetched from the network.');
      }
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mediaList');
    await prefs.remove('commentsCache');
    await prefs.remove('userNamesCache');
    await prefs.remove('lastFetchTimestamp');

    setState(() {
      _isDataLoaded = false;
      mediaList = [];
      commentsCache = {};
      userNamesCache = {};
      userLikes = {};
    });

    await _fetchMedia();
    if (mediaList.isNotEmpty) {
      await _fetchCommentsForAllPosts();
      await prefs.setString('mediaList', jsonEncode(mediaList));
      await prefs.setString('commentsCache', jsonEncode(commentsCache));
      await prefs.setString('userNamesCache', jsonEncode(userNamesCache));
      await prefs.setInt('lastFetchTimestamp', DateTime.now().millisecondsSinceEpoch);
    }
    await _checkUserLikes();
    setState(() {
      _isDataLoaded = true;
    });
  }

  Future<void> _fetchMedia() async {
    try {
      final response = await supabase
          .from('posts')
          .select('id, url, title_text, type, timestamp, likes_count, comments_count')
          .order('timestamp', ascending: false);
      setState(() {
        mediaList = response as List<Map<String, dynamic>>;
        print('Fetched media list: $mediaList');
      });
    } catch (e) {
      print('Error fetching media: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching media: $e')),
      );
    }
  }

  Future<void> _checkUserLikes() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('likes')
          .select('post_id')
          .eq('user_id', user.id);
      setState(() {
        userLikes = {for (var like in response) like['post_id'].toString(): true};
      });
    } catch (e) {
      print('Error checking user likes: $e');
    }
  }

  Future<void> _fetchCommentsForAllPosts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final userNamesResponse = await supabase
          .from('players_records')
          .select('user_id, full_name');
      setState(() {
        userNamesCache = {
          for (var user in userNamesResponse) user['user_id'].toString(): user['full_name']
        };
      });

      for (var media in mediaList) {
        final response = await supabase
            .from('comments')
            .select('id, user_id, comment_text, created_at')
            .eq('post_id', media['id'])
            .order('created_at', ascending: false);
        setState(() {
          commentsCache[media['id'].toString()] = response as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      print('Error fetching comments: $e');
    }
  }

  Future<void> _toggleLike(String postId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (userLikes[postId] ?? false) {
        await supabase.from('likes').delete().eq('post_id', postId).eq('user_id', user.id);
        setState(() {
          userLikes[postId] = false;
          for (var media in mediaList) {
            if (media['id'].toString() == postId) {
              media['likes_count'] = (media['likes_count'] ?? 0) - 1;
              break;
            }
          }
        });
      } else {
        await supabase.from('likes').insert({'post_id': postId, 'user_id': user.id});
        setState(() {
          userLikes[postId] = true;
          for (var media in mediaList) {
            if (media['id'].toString() == postId) {
              media['likes_count'] = (media['likes_count'] ?? 0) + 1;
              break;
            }
          }
        });
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mediaList', jsonEncode(mediaList));
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> _deletePost(String postId, String mediaUrl) async {
    try {
      print('Deleting likes for post ID: $postId');
      await supabase.from('likes').delete().eq('post_id', postId);
      print('Likes deleted successfully');

      print('Deleting comments for post ID: $postId');
      await supabase.from('comments').delete().eq('post_id', postId);
      print('Comments deleted successfully');

      print('Deleting post from posts table with ID: $postId');
      await supabase.from('posts').delete().eq('id', postId);
      print('Post deleted from posts table successfully');

      print('Original media URL: $mediaUrl');
      final urlParts = mediaUrl.split('posts.bucket/');
      if (urlParts.length < 2) {
        throw Exception('Invalid media URL format: $mediaUrl');
      }
      final filePath = urlParts[1].split('?')[0];
      print('Extracted file path: $filePath');

      print('Deleting file from posts.bucket: $filePath');
      final deleteResponse = await supabase.storage.from('posts.bucket').remove([filePath]);
      print('Delete response from storage: $deleteResponse');

      setState(() {
        mediaList.removeWhere((media) => media['id'].toString() == postId);
        commentsCache.remove(postId);
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mediaList', jsonEncode(mediaList));
      await prefs.setString('commentsCache', jsonEncode(commentsCache));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
  }

  void _showCommentCard(String postId) {
    final TextEditingController commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (commentsCache[postId]?.isNotEmpty ?? false)
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: commentsCache[postId]?.length ?? 0,
                          itemBuilder: (context, index) {
                            final comment = commentsCache[postId]![index];
                            final userId = comment['user_id'].toString();
                            final currentUser = supabase.auth.currentUser;
                            final isCurrentUser = currentUser != null && userId == currentUser.id;
                            final userName = isCurrentUser
                                ? 'You'
                                : userNamesCache[userId] ?? 'Unknown User';
                            final formattedTime = DateFormat('MMMM d, yyyy hh:mm a')
                                .format(DateTime.parse(comment['created_at']));
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    comment['comment_text'],
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text('No comments yet.'),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: InputDecoration(
                              hintText: 'Add a comment',
                              filled: true,
                              fillColor: Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: Icon(Icons.send, color: Colors.grey.shade500),
                          onPressed: () async {
                            if (commentController.text.isNotEmpty) {
                              final user = supabase.auth.currentUser;
                              if (user != null) {
                                await supabase.from('comments').insert({
                                  'post_id': postId,
                                  'user_id': user.id,
                                  'comment_text': commentController.text,
                                });
                                commentController.clear();
                                await _fetchCommentsForAllPosts();
                                setState(() {
                                  for (var media in mediaList) {
                                    if (media['id'].toString() == postId) {
                                      media['comments_count'] = (media['comments_count'] ?? 0) + 1;
                                      break;
                                    }
                                  }
                                });

                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('commentsCache', jsonEncode(commentsCache));
                                await prefs.setString('mediaList', jsonEncode(mediaList));
                              }
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'RubikMedium',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: mediaList.isEmpty
            ? const Center(child: Text(''))
            : SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: mediaList.map((media) {
                final timestamp = DateTime.parse(media['timestamp']);
                final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
                final mediaType = media['type']?.toString().toLowerCase() ?? 'unknown';
                final mediaUrl = media['url']?.toString() ?? '';
                final postId = media['id'].toString();
                final likesCount = media['likes_count'] ?? 0;
                final commentsCount = media['comments_count'] ?? 0;
                final title = media['title_text']?.toString() ?? 'No Title';

                final sanitizedUrl = mediaUrl.split('?')[0];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deletePost(postId, mediaUrl);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontFamily: 'RubikRegular',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: mediaType == 'image'
                              ? Image.network(
                            sanitizedUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 300,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[300],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading image: $error');
                              return const Center(child: Text('Error loading image'));
                            },
                          )
                              : mediaType == 'video'
                              ? VideoPlayerWidget(videoUrl: sanitizedUrl)
                              : const Center(child: Text('Unsupported media type')),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleLike(postId),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0),
                                  child: Icon(
                                    Icons.favorite,
                                    color: (userLikes[postId] ?? false) ? Colors.red : Colors.grey,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  likesCount.toString(),
                                  style: const TextStyle(fontSize: 16, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showCommentCard(postId),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Comments',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontFamily: 'RubikRegular',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    commentsCount.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      }).catchError((error) {
        print('Error initializing video: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video: $error')),
        );
      });
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _seekForward() {
    final newPosition = _controller.value.position + const Duration(seconds: 5);
    if (newPosition < _controller.value.duration) {
      _controller.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    final newPosition = _controller.value.position - const Duration(seconds: 5);
    if (newPosition > Duration.zero) {
      _controller.seekTo(newPosition);
    } else {
      _controller.seekTo(Duration.zero);
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 300,
      child: _isInitialized
          ? Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                if (!_controller.value.isPlaying)
                  GestureDetector(
                    onTap: () {
                      if (_isInitialized) {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                        setState(() {});
                      }
                    },
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_5, color: Colors.white),
                  onPressed: _seekBackward,
                ),
                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.forward_5, color: Colors.white),
                  onPressed: _seekForward,
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      bufferedColor: Colors.grey,
                      backgroundColor: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}