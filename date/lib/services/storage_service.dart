import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String> uploadPhoto(String uid, File file) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    final ref = _storage.ref('users/$uid/photos/$fileName');
    final task = await ref.putFile(
      file,
      SettableMetadata(contentType: _contentTypeForFile(file)),
    );
    return task.ref.getDownloadURL();
  }

  String _contentTypeForFile(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic') || path.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  Future<void> deletePhoto(String uid, String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Photo may already be gone; deletion is best-effort.
    }
  }
}
