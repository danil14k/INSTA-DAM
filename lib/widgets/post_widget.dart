import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../screens/comments_screen.dart';
import '../theme/app_theme.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final User currentUser;
  final VoidCallback? onChanged;
  PostWidget({required this.post, required this.currentUser, this.onChanged});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  late Post _post;
  bool _liked = false;
  int _commentsCount = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadCommentsCount();
    _loadLikedState();
    if (_post.isVideo && _post.mediaPath.isNotEmpty) {
      _initVideo();
    }
  }

  void _initVideo() {
    _videoController = VideoPlayerController.file(File(_post.mediaPath))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _loadLikedState() async {
    if (_post.id == null) return;
    final liked = await DatabaseHelper.instance.isPostLikedBy(_post.id!, widget.currentUser.username);
    setState(() => _liked = liked);
  }

  void _loadCommentsCount() async {
    final c = await DatabaseHelper.instance.countCommentsForPost(_post.id!);
    setState(() => _commentsCount = c);
  }

  void _showEditDialog() {
    final _editCtrl = TextEditingController(text: _post.description);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar descripcion'),
        content: TextField(controller: _editCtrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(
            onPressed: () async {
              _post.description = _editCtrl.text;
              await DatabaseHelper.instance.updatePost(_post);
              Navigator.pop(context);
              setState(() {});
              widget.onChanged?.call();
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleLike() async {
    setState(() {
      _liked = !_liked;
    });
    if (_liked) {
      await DatabaseHelper.instance.addLike(_post.id!, widget.currentUser.username);
    } else {
      await DatabaseHelper.instance.removeLike(_post.id!, widget.currentUser.username);
    }
    final updated = await DatabaseHelper.instance.getAllPosts();
    final refreshed = updated.firstWhere((p) => p.id == _post.id, orElse: () => _post);
    setState(() => _post = refreshed);
    widget.onChanged?.call();
  }

  Widget _buildMediaContent() {
    if (_post.hasMedia) {
      if (_post.isImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_post.mediaPath), fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder()),
        );
      } else if (_post.isVideo && _videoController != null) {
        return _videoController!.value.isInitialized
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      if (!_videoController!.value.isPlaying)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.play_arrow, color: Colors.white, size: 40),
                        ),
                    ],
                  ),
                ),
              )
            : _placeholder();
      }
    }

    if (_post.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_post.imageUrl, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder()),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image, size: 50, color: Theme.of(context).textTheme.bodyMedium?.color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final secondaryText = Theme.of(context).textTheme.bodyMedium?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: brand.withValues(alpha: 0.2),
                child: Icon(Icons.person, size: 20, color: brand),
              ),
              SizedBox(width: 10),
              Text(_post.username, style: TextStyle(fontWeight: FontWeight.bold)),
              if (_post.isVideo) ...[
                SizedBox(width: 6),
                Icon(Icons.videocam, size: 16, color: secondaryText),
              ],
              Spacer(),
              IconButton(
                icon: Icon(Icons.more_vert),
                onPressed: () {
                  if (_post.username == widget.currentUser.username) {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Editar descripcion'),
                            onTap: () {
                              Navigator.pop(context);
                              _showEditDialog();
                            },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete, color: AppTheme.error),
                            title: Text('Borrar publicacion', style: TextStyle(color: AppTheme.error)),
                            onTap: () async {
                              await DatabaseHelper.instance.deletePost(_post.id!);
                              Navigator.pop(context);
                              widget.onChanged?.call();
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: _buildMediaContent(),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(
                _liked ? Icons.favorite : Icons.favorite_border,
                color: _liked ? brand : null,
              ),
              onPressed: _toggleLike,
            ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(post: _post, currentUser: widget.currentUser)));
                _loadCommentsCount();
                widget.onChanged?.call();
              },
            ),
            Spacer(),
            IconButton(icon: Icon(Icons.bookmark_border), onPressed: () {}),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_post.likes} likes', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(text: _post.username, style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '  ${_post.description}'),
                  ],
                ),
              ),
              if (_commentsCount > 0)
                GestureDetector(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => CommentsScreen(post: _post, currentUser: widget.currentUser)));
                    _loadCommentsCount();
                    widget.onChanged?.call();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Ver comentarios ($_commentsCount)',
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  ),
                ),
              SizedBox(height: 4),
              Text(
                _post.date,
                style: TextStyle(color: secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Divider(height: 1),
        SizedBox(height: 4),
      ],
    );
  }
}
