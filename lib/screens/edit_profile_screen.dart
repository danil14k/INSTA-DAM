import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../db/firestore_service.dart';
import '../db/storage_service.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;
  final Function(User) onUpdated;
  EditProfileScreen({required this.currentUser, required this.onUpdated});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _usernameCtrl;
  String _profileImagePath = '';
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _displayNameCtrl = TextEditingController(text: widget.currentUser.displayName ?? widget.currentUser.username);
    _bioCtrl = TextEditingController(text: widget.currentUser.bio);
    _usernameCtrl = TextEditingController(text: widget.currentUser.username);
    _profileImagePath = widget.currentUser.profileImagePath;
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory(p.join(dir.path, 'instadam_media', 'profiles'));
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
      final ext = p.extension(picked.path);
      final fileName = 'profile_${widget.currentUser.username}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final saved = await File(picked.path).copy(p.join(mediaDir.path, fileName));
      setState(() => _profileImagePath = saved.path);
    }
  }

  void _save() async {
    final newUsername = _usernameCtrl.text.trim();
    if (newUsername.isEmpty) return;

    // Check if username changed and if new one is taken
    if (newUsername != widget.currentUser.username) {
      final existing = await FirestoreService.instance.getUserByUsername(newUsername);
      if (existing != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El nombre de usuario "$newUsername" ya existe')),
        );
        return;
      }
    }

    widget.currentUser.displayName = _displayNameCtrl.text.trim();
    widget.currentUser.bio = _bioCtrl.text.trim();
    widget.currentUser.profileImagePath = _profileImagePath;
    widget.currentUser.username = newUsername;

    // Subir foto de perfil a Firebase Storage si cambió
    if (_profileImagePath.isNotEmpty && _profileImagePath != widget.currentUser.profileImagePath) {
      try {
        final url = await StorageService.instance.uploadProfileImage(
          newUsername, File(_profileImagePath));
        widget.currentUser.profileImagePath = url;
      } catch (_) {
        // Si falla la subida, mantener la ruta local
      }
    }

    await FirestoreService.instance.updateUser(widget.currentUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', widget.currentUser.displayName ?? newUsername);
    await prefs.setString('username', newUsername);

    widget.onUpdated(widget.currentUser);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final brand = AppTheme.brandOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: brand),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile image
            GestureDetector(
              onTap: _pickProfileImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: brand.withValues(alpha: 0.2),
                    backgroundImage: _profileImagePath.isNotEmpty
                        ? FileImage(File(_profileImagePath))
                        : null,
                    child: _profileImagePath.isEmpty
                        ? Icon(Icons.person, size: 50, color: brand)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: brand,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            TextButton(
              onPressed: _pickProfileImage,
              child: Text('Cambiar foto de perfil', style: TextStyle(color: brand, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 24),

            // Username
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre de usuario',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            SizedBox(height: 16),

            // Display name
            TextField(
              controller: _displayNameCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre para mostrar',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 16),

            // Bio
            TextField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Biografía',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.info_outline),
                ),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                child: Text('Guardar cambios', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
