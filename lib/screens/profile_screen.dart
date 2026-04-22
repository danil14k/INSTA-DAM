import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../db/firestore_service.dart';
import '../models/post.dart';
import '../widgets/post_widget.dart';
import '../theme/app_theme.dart';
import '../utils/strings.dart';
import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  ProfileScreen({required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  int _postCount = 0;
  int _followersCount = 0;
  int _followingCount = 0;
  String? _displayName;
  List<Post> _userPosts = [];
  bool _isGridView = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final user = await FirestoreService.instance.getUserByUsername(widget.currentUser.username);
    if (user != null) {
      widget.currentUser.displayName = user.displayName;
      widget.currentUser.bio = user.bio;
      widget.currentUser.profileImagePath = user.profileImagePath;
    }
    final posts = await FirestoreService.instance.getAllPosts(username: widget.currentUser.username);
    final followers = await FirestoreService.instance.getFollowersCount(widget.currentUser.username);
    final following = await FirestoreService.instance.getFollowingCount(widget.currentUser.username);
    if (mounted) {
      setState(() {
        _postCount = posts.length;
        _userPosts = posts;
        _followersCount = followers;
        _followingCount = following;
        _displayName = widget.currentUser.displayName ?? widget.currentUser.username;
      });
    }
  }

  void _showFilteredFeed() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          appBar: AppBar(title: Text(Strings.t(context, 'profile'))),
          body: ListView.builder(
            itemCount: _userPosts.length,
            itemBuilder: (context, i) => PostWidget(
              post: _userPosts[i],
              currentUser: widget.currentUser,
              onChanged: _loadData,
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
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
              leading: Hero(
                tag: 'profile_${user.username}',
                child: CircleAvatar(
                  backgroundColor: AppTheme.igBlue.withValues(alpha: 0.1),
                  backgroundImage: user.profileImagePath.isNotEmpty
                      ? FileImage(File(user.profileImagePath))
                      : null,
                  child: user.profileImagePath.isEmpty
                      ? const Icon(Icons.person, color: AppTheme.igBlue)
                      : null,
                ),
              ),
              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final secondaryText = AppTheme.igGrey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentUser.username, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Ajustes',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Semantics(
                    label: 'Foto de perfil',
                    child: Hero(
                      tag: 'my_profile_pic',
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.igGrey.withValues(alpha: 0.2),
                        backgroundImage: widget.currentUser.profileImagePath.isNotEmpty
                            ? FileImage(File(widget.currentUser.profileImagePath))
                            : null,
                        child: widget.currentUser.profileImagePath.isEmpty
                            ? const Icon(Icons.person, size: 50, color: AppTheme.igGrey)
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn(_postCount, 'Publicaciones', onTap: _showFilteredFeed),
                        _buildStatColumn(_followersCount, 'Seguidores', onTap: () =>
                          _showUserList('Seguidores', () => FirestoreService.instance.getFollowers(widget.currentUser.username))),
                        _buildStatColumn(_followingCount, 'Seguidos', onTap: () =>
                          _showUserList('Seguidos', () => FirestoreService.instance.getFollowing(widget.currentUser.username))),
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
                  Text(_displayName ?? widget.currentUser.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.currentUser.bio.isNotEmpty)
                    Text(widget.currentUser.bio)
                  else
                    const Text('Bio de InstaDAM 🚀'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: const Text('Editar perfil'),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.grid_on, color: _isGridView ? (isDark ? Colors.white : Colors.black) : AppTheme.igGrey),
                    onPressed: () => setState(() => _isGridView = true),
                    tooltip: 'Vista de cuadrícula',
                  ),
                ),
                Expanded(
                  child: IconButton(
                    icon: Icon(Icons.person_pin_outlined, color: !_isGridView ? (isDark ? Colors.white : Colors.black) : AppTheme.igGrey),
                    onPressed: () => setState(() => _isGridView = false),
                    tooltip: 'Fotos en las que apareces',
                  ),
                ),
              ],
            ),
            Expanded(
              child: _userPosts.isEmpty 
                ? Center(child: Text(Strings.t(context, 'feed_no_posts'), style: const TextStyle(color: AppTheme.igGrey)))
                : GridView.builder(
                  padding: const EdgeInsets.all(1),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 1,
                    mainAxisSpacing: 1,
                  ),
                  itemCount: _userPosts.length,
                  itemBuilder: (context, i) {
                    final post = _userPosts[i];
                    return Semantics(
                      label: 'Publicación ${i + 1}',
                      onTap: _showFilteredFeed,
                      child: GestureDetector(
                        onTap: _showFilteredFeed,
                        child: _buildPostThumbnail(post, isDark),
                      ),
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostThumbnail(Post post, bool isDark) {
    if (post.hasMedia && post.isImage) {
      return Image.file(
        File(post.mediaPath), 
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gridPlaceholder(isDark),
      );
    }
    return _gridPlaceholder(isDark);
  }

  Widget _gridPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: const Icon(Icons.image, color: AppTheme.igGrey),
    );
  }

  Widget _buildStatColumn(int count, String label, {VoidCallback? onTap}) {
    return Semantics(
      button: true,
      label: '$count $label',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
