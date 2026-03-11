import 'package:flutter/material.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../models/post.dart';
import '../utils/strings.dart';
import '../widgets/post_widget.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'reels_screen.dart';

class FeedScreen extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;
  final Function(bool) onToggleTheme;
  FeedScreen({required this.currentUser, required this.onLogout, required this.onToggleTheme});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() async {
    final posts = await DatabaseHelper.instance.getAllPosts();
    setState(() {
      _posts = posts;
    });
  }

  void _onRefresh() => _loadPosts();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      appBar: _currentIndex == 0 ? AppBar(
        title: Image.asset(
          isDark
              ? 'assets/media/logos/logo_negro.png'
              : 'assets/media/logos/logo_blanco.png',
          height: 40,
        ),
        actions: [
          // Theme toggle - always visible
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: brand),
            onPressed: () => widget.onToggleTheme(!isDark),
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          ),
          IconButton(icon: Icon(Icons.favorite_border), onPressed: () {}),
        ],
      ) : null,
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 2) {
             Navigator.pushNamed(context, '/create').then((_) => _loadPosts());
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.movie_outlined), label: 'Reels'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return RefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: _posts.isEmpty
              ? ListView(children: [
                  SizedBox(height: 120),
                  Center(child: Text(Strings.t(context, 'feed_no_posts'), style: TextStyle(fontSize: 16))),
                ])
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, i) => PostWidget(
                    post: _posts[i],
                    currentUser: widget.currentUser,
                    onChanged: _onRefresh,
                  ),
                ),
        );
      case 3:
        return ReelsScreen(currentUser: widget.currentUser);
      case 4:
        return ProfileScreen(currentUser: widget.currentUser);
      default:
        return Center(child: Text('Section $_currentIndex Coming Soon'));
    }
  }
}
