import 'package:flutter/material.dart';
import '../models/user.dart';
import '../db/firestore_service.dart';
import '../models/post.dart';
import '../utils/strings.dart';
import '../widgets/post_widget.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'reels_screen.dart';
import 'chat_list_screen.dart';

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
    final posts = await FirestoreService.instance.getAllPosts();
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
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: brand),
            onPressed: () => widget.onToggleTheme(!isDark),
            tooltip: Strings.t(context, isDark ? 'light_mode_tooltip' : 'dark_mode_tooltip'),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border), 
            onPressed: () {},
            tooltip: 'Notificaciones',
          ),
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
          BottomNavigationBarItem(
            icon: const Icon(Icons.home), 
            label: Strings.t(context, 'nav_home')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline), 
            label: Strings.t(context, 'nav_messages')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_box_outlined), 
            label: Strings.t(context, 'nav_create')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.movie_outlined), 
            label: Strings.t(context, 'nav_reels')
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline), 
            label: Strings.t(context, 'nav_profile')
          ),
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
                  const SizedBox(height: 120),
                  Center(child: Text(Strings.t(context, 'feed_no_posts'), style: const TextStyle(fontSize: 16))),
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
      case 1:
        return ChatListScreen(currentUser: widget.currentUser);
      case 3:
        return ReelsScreen(currentUser: widget.currentUser);
      case 4:
        return ProfileScreen(currentUser: widget.currentUser);
      default:
        return Center(child: Text('Sección $_currentIndex próximamente'));
    }
  }
}
