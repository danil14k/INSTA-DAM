import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/database_helper.dart';

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

  // Keep video controllers for current, prev, next pages
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadMediaPosts();
  }

  void _loadMediaPosts() async {
    final posts = await DatabaseHelper.instance.getMediaPosts();
    setState(() {
      _mediaPosts = posts;
    });
    if (posts.isNotEmpty) {
      _initController(0);
    }
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
    // Pause previous
    _controllers[_currentPage]?.pause();

    _currentPage = index;

    // Play current
    final current = _controllers[index];
    if (current != null && current.value.isInitialized) {
      current.play();
      current.setLooping(true);
    }

    // Pre-init next
    _initController(index + 1);

    // Dispose far away controllers
    final toRemove = _controllers.keys.where((k) => (k - index).abs() > 2).toList();
    for (final k in toRemove) {
      _disposeController(k);
    }

    // Init current if not yet
    _initController(index);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaPosts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No hay reels todavía', style: TextStyle(color: Colors.white, fontSize: 18)),
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
          );
        },
      ),
    );
  }
}

class _ReelItem extends StatelessWidget {
  final Post post;
  final User currentUser;
  final VideoPlayerController? videoController;

  const _ReelItem({
    required this.post,
    required this.currentUser,
    this.videoController,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Media content
        if (post.isImage)
          Image.file(
            File(post.mediaPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
          )
        else if (post.isVideo && videoController != null && videoController!.value.isInitialized)
          GestureDetector(
            onTap: () {
              if (videoController!.value.isPlaying) {
                videoController!.pause();
              } else {
                videoController!.play();
              }
            },
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: videoController!.value.size.width,
                height: videoController!.value.size.height,
                child: VideoPlayer(videoController!),
              ),
            ),
          )
        else
          Container(color: Colors.grey[900], child: Center(child: CircularProgressIndicator(color: Colors.white))),

        // Gradient overlay at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
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

        // Post info overlay
        Positioned(
          bottom: 80,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text(
                    post.username,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              if (post.description.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  post.description,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Side actions
        Positioned(
          bottom: 100,
          right: 12,
          child: Column(
            children: [
              _SideButton(icon: Icons.favorite_border, label: '${post.likes}'),
              SizedBox(height: 20),
              _SideButton(icon: Icons.chat_bubble_outline, label: ''),
              SizedBox(height: 20),
              _SideButton(icon: Icons.send, label: ''),
              SizedBox(height: 20),
              _SideButton(icon: Icons.bookmark_border, label: ''),
            ],
          ),
        ),
      ],
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SideButton({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
      ],
    );
  }
}
