import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../db/firestore_service.dart';
import '../db/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/strings.dart';
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
  bool _isLoading = false;
  String? _errorText;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() { 
        _selectedFile = File(picked.path); 
        _mediaType = 'image'; 
        _errorText = null;
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
    if (picked != null) {
      setState(() { 
        _selectedFile = File(picked.path); 
        _mediaType = 'video'; 
        _errorText = null;
      });
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library), 
              title: const Text('Galería'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt), 
              title: const Text('Cámara'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }
            ),
            ListTile(
              leading: const Icon(Icons.video_library), 
              title: const Text('Vídeo'),
              onTap: () { Navigator.pop(ctx); _pickVideo(ImageSource.gallery); }
            ),
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
    
    if (_selectedFile == null) {
      setState(() => _errorText = 'Selecciona una imagen');
      return;
    }
    
    if (desc.isEmpty) {
      setState(() => _errorText = Strings.t(context, 'empty_pass_error')); // Reuse or add new
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      String mediaPath = await _saveMediaLocally(_selectedFile!);

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
      
      final created = await FirestoreService.instance.createPost(post);
      
      if (created.id != null) {
        try {
          final url = await StorageService.instance.uploadPostMedia(created.id!, _selectedFile!);
          created.mediaPath = url;
          await FirestoreService.instance.updatePost(created);
        } catch (_) {}
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = Strings.t(context, 'error_generic');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.t(context, 'create_post'), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isLoading 
            ? const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(
                onPressed: _submit,
                child: Text(Strings.t(context, 'publish'), style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectedFile == null ? _showMediaPicker : null,
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                  child: _selectedFile != null
                    ? Image.file(_selectedFile!, fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, size: 50, color: AppTheme.igGrey),
                          const SizedBox(height: 10),
                          Text(Strings.t(context, 'grid_view'), style: const TextStyle(color: AppTheme.igGrey)),
                        ],
                      ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: Strings.t(context, 'description_label'),
                  errorText: _errorText,
                  border: InputBorder.none,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(_location.isEmpty ? Strings.t(context, 'location_label') : _location),
              onTap: () async {
                final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => LocationPickerScreen()));
                if (res != null) setState(() => _location = res);
              },
            ),
          ],
        ),
      ),
    );
  }
}
