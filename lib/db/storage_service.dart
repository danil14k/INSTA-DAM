import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static final StorageService instance = StorageService._init();
  StorageService._init();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube una imagen de perfil y devuelve la URL de descarga
  Future<String> uploadProfileImage(String username, File file) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref().child('profiles/$username$ext');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Sube una imagen/video de post y devuelve la URL de descarga
  Future<String> uploadPostMedia(String postId, File file) async {
    final ext = p.extension(file.path);
    final ref = _storage.ref().child('posts/$postId$ext');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Elimina un archivo de Storage por su URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignorar si el archivo no existe
    }
  }
}
