import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.url, required this.path});
  final String url;
  final String path;
}

/// Stores incident photos at `incidents/{uid}/{incidentId}.jpg`. Putting the
/// uploader's uid in the path lets storage.rules check ownership.
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final path = 'incidents/$uid/$incidentId.jpg';
    final ref = _storage.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return UploadedPhoto(url: await ref.getDownloadURL(), path: path);
  }

  Future<void> deletePhoto(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (e) {
      // Already gone is fine; anything else should surface.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
