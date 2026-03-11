import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import 'comments_screen.dart';
import 'user_profile_screen.dart';

class ReelsScreen extends StatefulWidget {
  final User currentUser;
  ReelsScreen({required this.currentUser});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  List<Post> _mediaPosts = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadMediaPosts();
  }

  void _loadMediaPosts() async {
    final posts = await DatabaseHelper.instance.getMediaPosts();
    setState(() => _mediaPosts = posts);
    if (posts.isNotEmpty) _initController(0);
  }

  void _initController(int index) {
    if (index < 0 || index >= _mediaPosts.length) return;
    final post = _mediaPosts[index];
    if (post.isVideo && !_controllers.containsKey(index)) {
      final ctrl = VideoPlayerController.file(File(post.mediaPath));
      _controllers[index] = ctrl;
      ctrl.initialize().then((_) {
        if (mounted) setState(() {});
        if (index == _currentPage) {
          ctrl.play();
          ctrl.setLooping(true);
        }
      });
    }
  }

  void _disposeController(int index) {
    _controllers[index]?.dispose();
    _controllers.remove(index);
  }

  void _onPageChanged(int index) {
    _controllers[_currentPage]?.pause();
    _currentPage = index;
    final current = _controllers[index];
    if (current != null && current.value.isInitialized) {
      current.play();
      current.setLooping(true);
    }
    _initController(index + 1);
    final toRemove = _controllers.keys.where((k) => (k - index).abs() > 2).toList();
    for (final k in toRemove) _disposeController(k);
    _initController(index);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No hay reels todavia', style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _mediaPosts.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final post = _mediaPosts[index];
          return _ReelItem(
            post: post,
            currentUser: widget.currentUser,
            videoController: _controllers[index],
            onPostUpdated: () {
              _loadMediaPosts();
            },
          );
        },
      ),
    );
  }
}

class _ReelItem extends StatefulWidget {
  final Post post;
  final User currentUser;
  final VideoPlayerController? videoController;
  final VoidCallback? onPostUpdated;

  const _ReelItem({
    required this.post,
    required this.currentUser,
    this.videoController,
    this.onPostUpdated,
  });

  @override
  State<_ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<_ReelItem> {
  bool _liked = false;
  bool _bookmarked = false;
  int _likeCount = 0;
  int _commentCount = 0;
  User? _postUser;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likes;
    _loadState();
  }

  void _loadState() async {
    if (widget.post.id == null) return;
    final liked = await DatabaseHelper.instance.isPostLikedBy(widget.post.id!, widget.currentUser.username);
    final bookmarked = await DatabaseHelper.instance.isPostBookmarkedBy(widget.post.id!, widget.currentUser.username);
    final comments = await DatabaseHelper.instance.countCommentsForPost(widget.post.id!);
    final likes = await DatabaseHelper.instance.countLikesForPost(widget.post.id!);
    final user = await DatabaseHelper.instance.getUserByUsername(widget.post.username);
    if (mounted) {
      setState(() {
        _liked = liked;
        _bookmarked = bookmarked;
        _commentCount = comments;
        _likeCount = likes;
        _postUser = user;
      });
    }
  }

  void _toggleLike() async {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    if (_liked) {
      await DatabaseHelper.instance.addLike(widget.post.id!, widget.currentUser.username);
    } else {
      await DatabaseHelper.instance.removeLike(widget.post.id!, widget.currentUser.username);
    }
    widget.onPostUpdated?.call();
  }

  void _toggleBookmark() async {
    setState(() => _bookmarked = !_bookmarked);
    if (_bookmarked) {
      await DatabaseHelper.instance.addBookmark(widget.post.id!, widget.currentUser.username);
    } else {
      await DatabaseHelper.instance.removeBookmark(widget.post.id!, widget.currentUser.username);
    }
  }

  void _openComments() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => CommentsScreen(post: widget.post, currentUser: widget.currentUser),
    ));
    final count = await DatabaseHelper.instance.countCommentsForPost(widget.post.id!);
    if (mounted) setState(() => _commentCount = count);
  }

  void _goToProfile() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => UserProfileScreen(username: widget.post.username, currentUser: widget.currentUser),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content
        if (widget.post.isImage)
          Image.file(File(widget.post.mediaPath), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]))
        else if (widget.post.isVideo && widget.videoController != null && widget.videoController!.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (widget.videoController!.value.isPlaying) {
                widget.videoController!.pause();
              } else {
                widget.videoController!.play();
              }
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: widget.videoController!.value.size.width,
                height: widget.videoController!.value.size.height,
                child: VideoPlayer(widget.videoController!),
              ),
            ),
          )
        else
          Container(color: Colors.grey[900], child: Center(child: CircularProgressIndicator(color: Colors.white))),

        // Gradient overlay
        Positioned(
          bottom: 0, left: 0, right: 0, height: 200,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
          ),
        ),

        // Post info
        Positioned(
          bottom: 80, left: 16, right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _goToProfile,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: brand.withValues(alpha: 0.3),
                      backgroundImage: _postUser != null && _postUser!.profileImagePath.isNotEmpty
                          ? FileImage(File(_postUser!.profileImagePath))
                          : null,
                      child: _postUser == null || _postUser!.profileImagePath.isEmpty
                          ? Icon(Icons.person, size: 18, color: Colors.white)
                          : null,
                    ),
                    SizedBox(width: 8),
                    Text(widget.post.username,
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ),
              if (widget.post.location.isNotEmpty) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text(widget.post.location, style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
              if (widget.post.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(widget.post.description, style: TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),

        // Side actions - functional
        Positioned(
          bottom: 100, right: 12,
          child: Column(
            children: [
              // Like
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(_liked ? Icons.favorite : Icons.favorite_border,
                        color: _liked ? brand : Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('$_likeCount', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Comments
              GestureDetector(
                onTap: _openComments,
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text('$_commentCount', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // Share
              Icon(Icons.send, color: Colors.white, size: 28),
              SizedBox(height: 20),
              // Bookmark
              GestureDetector(
                onTap: _toggleBookmark,
                child: Icon(_bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: _bookmarked ? brand : Colors.white, size: 28),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
