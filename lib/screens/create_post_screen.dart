import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import 'package:intl/intl.dart';
import '../utils/strings.dart';

class CreatePostScreen extends StatefulWidget {
  final User currentUser;
  CreatePostScreen({required this.currentUser});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  void _submit() async {
    final desc = _descCtrl.text.trim();
    final image = _imageCtrl.text.trim();
    if (desc.isEmpty) return;

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final post = Post(
      imageUrl: image,
      username: widget.currentUser.username,
      description: desc,
      date: now,
      likes: 0,
    );
    await DatabaseHelper.instance.createPost(post);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Write a caption...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('Image URL (optional)'),
            subtitle: TextField(
              controller: _imageCtrl,
              decoration: InputDecoration(
                hintText: 'https://...',
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.location_on_outlined),
            title: Text('Add Location'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Tag People'),
            trailing: Icon(Icons.chevron_right),
          ),
          Divider(),
        ],
      ),
    );
  }
}
