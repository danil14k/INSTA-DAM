import 'dart:io';
import 'package:flutter/material.dart';
import '../db/firestore_service.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../widgets/post_widget.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  final User currentUser;
  UserProfileScreen({required this.username, required this.currentUser});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? _user;
  List<Post> _userPosts = [];
  bool _isFollowing = false;
  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await FirestoreService.instance.getUserByUsername(widget.username);
    final posts = await FirestoreService.instance.getAllPosts(username: widget.username);
    final following = await FirestoreService.instance.isFollowing(
        widget.currentUser.username, widget.username);
    final followers = await FirestoreService.instance.getFollowersCount(widget.username);
    final followingCount = await FirestoreService.instance.getFollowingCount(widget.username);
    setState(() {
      _user = user;
      _userPosts = posts;
      _isFollowing = following;
      _followersCount = followers;
      _followingCount = followingCount;
    });
  }

  void _toggleFollow() async {
    if (_isFollowing) {
      await FirestoreService.instance.unfollowUser(widget.currentUser.username, widget.username);
    } else {
      await FirestoreService.instance.followUser(widget.currentUser.username, widget.username);
    }
    _loadData();
  }

  void _showFilteredFeed() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text('Posts de ${widget.username}')),
        body: ListView.builder(
          itemCount: _userPosts.length,
          itemBuilder: (context, i) => PostWidget(
            post: _userPosts[i],
            currentUser: widget.currentUser,
            onChanged: _loadData,
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final brand = AppTheme.brandOf(context);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnProfile = widget.username == widget.currentUser.username;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: brand.withValues(alpha: 0.2),
                  backgroundImage: _user!.profileImagePath.isNotEmpty
                      ? FileImage(File(_user!.profileImagePath))
                      : null,
                  child: _user!.profileImagePath.isEmpty
                      ? Icon(Icons.person, size: 50, color: brand)
                      : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat(_userPosts.length, 'Posts'),
                      _buildStat(_followersCount, 'Followers'),
                      _buildStat(_followingCount, 'Following'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_user!.displayName ?? _user!.username,
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (_user!.bio.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(_user!.bio, style: TextStyle(color: secondaryText)),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12),
          if (!isOwnProfile)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: _isFollowing
                          ? ElevatedButton.styleFrom(
                              backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                              foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                              side: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                            )
                          : null,
                      child: Text(_isFollowing ? 'Siguiendo' : 'Seguir'),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(currentUser: widget.currentUser, otherUser: _user!),
                        ));
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brand),
                        foregroundColor: brand,
                      ),
                      child: Text('Mensaje'),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 12),
          Divider(height: 1),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(1),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: _userPosts.length,
              itemBuilder: (context, i) {
                final post = _userPosts[i];
                return GestureDetector(
                  onTap: _showFilteredFeed,
                  child: _buildPostThumbnail(post, isDark, secondaryText),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostThumbnail(Post post, bool isDark, Color? secondaryText) {
    if (post.hasMedia && post.isImage) {
      return Image.file(File(post.mediaPath), fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _gridPlaceholder(isDark, secondaryText));
    }
    if (post.hasMedia && post.isVideo) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Container(color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface),
          Center(child: Icon(Icons.videocam, color: secondaryText, size: 30)),
        ],
      );
    }
    return _gridPlaceholder(isDark, secondaryText);
  }

  Widget _gridPlaceholder(bool isDark, Color? secondaryText) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: Icon(Icons.image, color: secondaryText),
    );
  }

  Widget _buildStat(int count, String label) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
      ],
    );
  }
}
