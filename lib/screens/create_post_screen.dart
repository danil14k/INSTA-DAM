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
              title: const Text('Imagen de galería'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt), 
              title: const Text('Hacer foto'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }
            ),
            ListTile(
              leading: const Icon(Icons.video_library), 
              title: const Text('Vídeo de galería'),
              onTap: () { Navigator.pop(ctx); _pickVideo(ImageSource.gallery); }
            ),
            ListTile(
              leading: const Icon(Icons.videocam), 
              title: const Text('Grabar vídeo'),
              onTap: () { Navigator.pop(ctx); _pickVideo(ImageSource.camera); }
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
      setState(() => _errorText = 'Debes seleccionar una imagen o vídeo');
      return;
    }
    
    if (desc.isEmpty) {
      setState(() => _errorText = 'La descripción es obligatoria');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      String mediaPath = await _saveMediaLocally(_selectedFile!);

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
      
      final created = await FirestoreService.instance.createPost(post);
      
      if (created.id != null) {
        try {
          final url = await StorageService.instance.uploadPostMedia(created.id!, _selectedFile!);
          created.mediaPath = url;
          await FirestoreService.instance.updatePost(created);
        } catch (_) {
          // Fallback to local path if storage fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación compartida correctamente!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Error al publicar. Inténtalo de nuevo.';
      });
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Post', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          _isLoading 
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : Semantics(
                label: 'Botón compartir publicación',
                button: true,
                child: TextButton(
                  onPressed: _submit,
                  child: Text(
                    'Compartir', 
                    style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Selector Area
            Semantics(
              label: _selectedFile == null ? 'Selector de imagen. Cap imatge seleccionada' : 'Imatge seleccionada',
              child: GestureDetector(
                onTap: _selectedFile == null ? _showMediaPicker : null,
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    width: double.infinity,
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    child: _selectedFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_mediaType == 'image')
                              Image.file(_selectedFile!, fit: BoxFit.cover)
                            else
                              const Center(child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam, size: 60, color: AppTheme.igGrey),
                                  Text('Vídeo seleccionado'),
                                ],
                              )),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: _removeMedia,
                                child: Container(
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 60, color: AppTheme.igGrey),
                            SizedBox(height: 12),
                            Text('Toca para añadir una foto o vídeo', style: TextStyle(color: AppTheme.igGrey)),
                          ],
                        ),
                  ),
                ),
              ),
            ),

            // Description Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción', 
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20, 
                        backgroundColor: brand.withAlpha(50), 
                        child: Icon(Icons.person, color: brand, size: 24)
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Escribe un pie de foto...',
                            errorText: _errorText,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: (_) {
                            if (_errorText != null) setState(() => _errorText = null);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Mentioned users chips
            if (_mentionedUsers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  children: _mentionedUsers.map((u) => Chip(
                    label: Text('@$u', style: TextStyle(color: brand, fontSize: 13)),
                    backgroundColor: brand.withAlpha(25),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _mentionedUsers.remove(u)),
                  )).toList(),
                ),
              ),

            const Divider(),
            ListTile(
              leading: Icon(Icons.location_on, color: _location.isNotEmpty ? brand : AppTheme.igGrey),
              title: Text(_location.isNotEmpty ? _location : 'Añadir ubicación'),
              trailing: _location.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18), 
                      onPressed: () => setState(() => _location = '')
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _pickLocation,
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.person_outline, color: _mentionedUsers.isNotEmpty ? brand : AppTheme.igGrey),
              title: Text(_mentionedUsers.isNotEmpty
                  ? 'Personas etiquetadas (${_mentionedUsers.length})'
                  : 'Etiquetar personas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickMentions,
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
