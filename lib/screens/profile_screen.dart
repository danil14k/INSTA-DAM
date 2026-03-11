import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../models/post.dart';
import '../widgets/post_widget.dart';
import '../theme/app_theme.dart';
import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  ProfileScreen({required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _postCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _displayName;
  List<Post> _userPosts = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final user = await DatabaseHelper.instance.getUserByUsername(widget.currentUser.username);
    if (user != null) {
      widget.currentUser.displayName = user.displayName;
      widget.currentUser.bio = user.bio;
      widget.currentUser.profileImagePath = user.profileImagePath;
    }
    final posts = await DatabaseHelper.instance.getAllPosts(username: widget.currentUser.username);
    final followers = await DatabaseHelper.instance.getFollowersCount(widget.currentUser.username);
    final following = await DatabaseHelper.instance.getFollowingCount(widget.currentUser.username);
    setState(() {
      _postCount = posts.length;
      _userPosts = posts;
      _followersCount = followers;
      _followingCount = following;
      _displayName = widget.currentUser.displayName ?? widget.currentUser.username;
    });
  }

  void _showFilteredFeed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Posts de ${widget.currentUser.username}')),
          body: ListView.builder(
            itemCount: _userPosts.length,
            itemBuilder: (context, i) => PostWidget(
              post: _userPosts[i],
              currentUser: widget.currentUser,
              onChanged: _loadData,
            ),
          ),
        ),
      ),
    );
  }

  void _showUserList(String title, Future<List<User>> Function() getter) async {
    final users = await getter();
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) {
            final user = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.brandOf(context).withValues(alpha: 0.2),
                backgroundImage: user.profileImagePath.isNotEmpty
                    ? FileImage(File(user.profileImagePath))
                    : null,
                child: user.profileImagePath.isEmpty
                    ? Icon(Icons.person, color: AppTheme.brandOf(context))
                    : null,
              ),
              title: Text(user.username, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.displayName ?? ''),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => UserProfileScreen(username: user.username, currentUser: widget.currentUser),
                ));
              },
            );
          },
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentUser.username, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: Icon(Icons.add_box_outlined), onPressed: () {}),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
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
                  backgroundImage: widget.currentUser.profileImagePath.isNotEmpty
                      ? FileImage(File(widget.currentUser.profileImagePath))
                      : null,
                  child: widget.currentUser.profileImagePath.isEmpty
                      ? Icon(Icons.person, size: 50, color: brand)
                      : null,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(_postCount, 'Posts', onTap: _showFilteredFeed),
                      _buildStatColumn(_followersCount, 'Followers', onTap: () =>
                        _showUserList('Followers', () => DatabaseHelper.instance.getFollowers(widget.currentUser.username))),
                      _buildStatColumn(_followingCount, 'Following', onTap: () =>
                        _showUserList('Following', () => DatabaseHelper.instance.getFollowing(widget.currentUser.username))),
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
                Text(_displayName ?? widget.currentUser.username, style: TextStyle(fontWeight: FontWeight.bold)),
                if (widget.currentUser.bio.isNotEmpty)
                  Text(widget.currentUser.bio, style: TextStyle(color: secondaryText))
                else
                  Text('Flutter Developer | InstaDAM app', style: TextStyle(color: secondaryText)),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Edit profile button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      currentUser: widget.currentUser,
                      onUpdated: (updated) {
                        _loadData();
                      },
                    ),
                  ));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                  foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                child: Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.grid_on, color: _isGridView ? brand : secondaryText),
                  onPressed: () => setState(() => _isGridView = true),
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.person_pin_outlined, color: !_isGridView ? brand : secondaryText),
                  onPressed: () => setState(() => _isGridView = false),
                ),
              ),
            ],
          ),
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

  Widget _buildStatColumn(int count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }
}
