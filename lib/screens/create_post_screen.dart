import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/database_helper.dart';
import '../theme/app_theme.dart';
import 'location_picker_screen.dart';
import 'mention_users_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final User currentUser;
  CreatePostScreen({required this.currentUser});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedFile;
  String _mediaType = '';
  String _location = '';
  List<String> _mentionedUsers = [];

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() { _selectedFile = File(picked.path); _mediaType = 'image'; });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source, maxDuration: Duration(seconds: 60));
    if (picked != null) {
      setState(() { _selectedFile = File(picked.path); _mediaType = 'video'; });
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.photo_library), title: Text('Imagen de galeria'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
            ListTile(leading: Icon(Icons.camera_alt), title: Text('Tomar foto'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
            ListTile(leading: Icon(Icons.video_library), title: Text('Video de galeria'),
              onTap: () { Navigator.pop(ctx); _pickVideo(ImageSource.gallery); }),
            ListTile(leading: Icon(Icons.videocam), title: Text('Grabar video'),
              onTap: () { Navigator.pop(ctx); _pickVideo(ImageSource.camera); }),
          ],
        ),
      ),
    );
  }

  Future<String> _saveMediaLocally(File file) async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(dir.path, 'instadam_media'));
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    final ext = p.extension(file.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final saved = await file.copy(p.join(mediaDir.path, fileName));
    return saved.path;
  }

  void _submit() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty && _selectedFile == null) return;
    String mediaPath = '';
    if (_selectedFile != null) {
      mediaPath = await _saveMediaLocally(_selectedFile!);
    }

    // Add mentions to description if not already included
    String finalDesc = desc;
    for (final user in _mentionedUsers) {
      if (!finalDesc.contains('@$user')) {
        finalDesc += ' @$user';
      }
    }

    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final post = Post(
      imageUrl: '',
      username: widget.currentUser.username,
      description: finalDesc,
      date: now,
      likes: 0,
      mediaPath: mediaPath,
      mediaType: _mediaType,
      location: _location,
    );
    await DatabaseHelper.instance.createPost(post);
    Navigator.pop(context);
  }

  void _removeMedia() {
    setState(() { _selectedFile = null; _mediaType = ''; });
  }

  void _pickLocation() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => LocationPickerScreen(),
    ));
    if (result != null && result is String) {
      setState(() => _location = result);
    }
  }

  void _pickMentions() async {
    final result = await Navigator.push(context, MaterialPageRoute(
      builder: (_) => MentionUsersScreen(
        currentUsername: widget.currentUser.username,
        alreadyMentioned: _mentionedUsers,
      ),
    ));
    if (result != null && result is List<String>) {
      setState(() => _mentionedUsers = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nuevo Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text('Compartir', style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_selectedFile != null)
              Stack(
                children: [
                  if (_mediaType == 'image')
                    AspectRatio(aspectRatio: 1.0, child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedFile!, fit: BoxFit.cover),
                    ))
                  else
                    AspectRatio(aspectRatio: 1.0, child: Container(
                      color: Colors.black,
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.videocam, color: Colors.white, size: 60),
                        SizedBox(height: 8),
                        Text('Video seleccionado', style: TextStyle(color: Colors.white)),
                      ])),
                    )),
                  Positioned(top: 8, right: 8, child: GestureDetector(
                    onTap: _removeMedia,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  )),
                ],
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 25, backgroundColor: brand.withValues(alpha: 0.2), child: Icon(Icons.person, color: brand, size: 30)),
                  SizedBox(width: 12),
                  Expanded(child: TextField(
                    controller: _descCtrl,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Escribe un pie de foto... (usa @usuario para mencionar)',
                      border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false,
                    ),
                  )),
                ],
              ),
            ),

            // Mentioned users chips
            if (_mentionedUsers.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  children: _mentionedUsers.map((u) => Chip(
                    label: Text('@$u', style: TextStyle(color: brand, fontSize: 13)),
                    backgroundColor: brand.withValues(alpha: 0.1),
                    deleteIcon: Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _mentionedUsers.remove(u)),
                  )).toList(),
                ),
              ),

            Divider(),
            ListTile(leading: Icon(Icons.photo_library, color: brand), title: Text('Anadir foto o video'), onTap: _showMediaPicker),
            Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: _location.isNotEmpty ? brand : null),
              title: Text(_location.isNotEmpty ? _location : 'Anadir ubicacion'),
              trailing: _location.isNotEmpty
                  ? IconButton(icon: Icon(Icons.close, size: 18), onPressed: () => setState(() => _location = ''))
                  : Icon(Icons.chevron_right),
              onTap: _pickLocation,
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.person_outline, color: _mentionedUsers.isNotEmpty ? brand : null),
              title: Text(_mentionedUsers.isNotEmpty
                  ? 'Etiquetados: ${_mentionedUsers.map((u) => '@$u').join(', ')}'
                  : 'Etiquetar personas'),
              trailing: Icon(Icons.chevron_right),
              onTap: _pickMentions,
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
