import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../models/post.dart';
import '../widgets/post_widget.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  ProfileScreen({required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _postCount = 0;
  String? _displayName;
  List<Post> _userPosts = [];
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfilePrefs();
  }

  void _loadData() async {
    final posts = await DatabaseHelper.instance.getAllPosts(username: widget.currentUser.username);
    setState(() {
      _postCount = posts.length;
      _userPosts = posts;
    });
  }

  void _loadProfilePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final d = prefs.getString('displayName') ?? widget.currentUser.displayName ?? widget.currentUser.username;
    setState(() {
      _displayName = d;
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

  @override
  Widget build(BuildContext context) {
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
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatColumn(_postCount, 'Posts', onTap: _showFilteredFeed),
                      _buildStatColumn(120, 'Followers'),
                      _buildStatColumn(150, 'Following'),
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
                Text('Digital Creator', style: TextStyle(color: Colors.grey)),
                Text('Flutter Developer | InstaDAM app'),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.grid_on, color: _isGridView ? null : Colors.grey),
                  onPressed: () => setState(() => _isGridView = true),
                ),
              ),
              Expanded(
                child: IconButton(
                  icon: Icon(Icons.person_pin_outlined, color: !_isGridView ? null : Colors.grey),
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
                  child: post.imageUrl.isNotEmpty
                      ? Image.network(post.imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(int count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
