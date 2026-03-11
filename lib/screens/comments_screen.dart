import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/comment.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import 'package:intl/intl.dart';
import '../utils/strings.dart';

class CommentsScreen extends StatefulWidget {
  final Post post;
  final User currentUser;
  CommentsScreen({required this.post, required this.currentUser});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  List<Comment> _comments = [];
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    final c = await DatabaseHelper.instance.getCommentsForPost(widget.post.id!);
    setState(() => _comments = c);
  }

  void _add() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final comment = Comment(
      postId: widget.post.id!,
      username: widget.currentUser.username,
      text: text,
      date: now,
    );
    await DatabaseHelper.instance.createComment(comment);
    _ctrl.clear();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.t(context, 'comments')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(text: widget.post.username, style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '  ${widget.post.description}'),
                          ],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(widget.post.date, style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _comments.length,
              itemBuilder: (context, i) {
                final c = _comments[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.white, size: 18),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(text: c.username, style: TextStyle(fontWeight: FontWeight.bold)),
                                  TextSpan(text: '  ${c.text}'),
                                ],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(c.date, style: TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.favorite_border, size: 14, color: Colors.grey),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: '${Strings.t(context, 'add_comment')}...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _add,
                  child: Text(
                    Strings.t(context, 'publish'),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
