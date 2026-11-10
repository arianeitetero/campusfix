import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../supabase_config.dart';

class UploadedPhoto {
  const UploadedPhoto({required this.path, required this.storage});

  final String path;
  final String storage;
}

class StorageService {
  StorageService({
    FirebaseStorage? firebaseStorage,
    SupabaseClient? supabase,
    FirebaseAuth? auth,
    HttpClient? httpClient,
  })  : _firebaseStorage = firebaseStorage ?? FirebaseStorage.instance,
        _supabase = supabase ??
            (SupabaseConfig.configured ? Supabase.instance.client : null),
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? HttpClient();

  final FirebaseStorage _firebaseStorage;
  final SupabaseClient? _supabase;
  final FirebaseAuth _auth;
  final HttpClient _httpClient;

  Future<UploadedPhoto> uploadIncidentPhoto({
    required String uid,
    required String incidentId,
    required File file,
  }) async {
    final size = await file.length();
    if (size > 5 * 1024 * 1024) {
      throw const FormatException('Photos must be smaller than 5 MB.');
    }

    final user = _requireCurrentUser(uid);
    final path =
        'incidents/$uid/${incidentId}_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final request = await _openFunctionRequest(
      user,
      method: 'POST',
      headers: {'x-photo-path': _bucketPath(path)},
      contentType: 'image/jpeg',
    );
    request.contentLength = size;
    await request.addStream(file.openRead());
    final response = await request.close();
    await _checkResponse(response);
    return UploadedPhoto(path: path, storage: 'supabase');
  }

  Future<String> getPhotoUrl({
    required String path,
    required String storage,
  }) async {
    if (storage == 'firebase') {
      return _firebaseStorage.ref(path).getDownloadURL();
    }
    if (storage != 'supabase') {
      throw StateError('Unknown photo storage provider: $storage');
    }

    final user = _requireCurrentUser();
    final response = await _invokeFunction(
      user,
      {'action': 'signed-url', 'path': _bucketPath(path)},
    );
    final data = response.data;
    if (data is! Map || data['url'] is! String) {
      throw const FormatException('The photo service returned an invalid URL.');
    }
    return data['url'] as String;
  }

  Future<void> deletePhoto(String path, {required String storage}) async {
    if (storage == 'firebase') {
      try {
        await _firebaseStorage.ref(path).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
      return;
    }
    if (storage != 'supabase') {
      throw StateError('Unknown photo storage provider: $storage');
    }

    final user = _requireCurrentUser();
    await _invokeFunction(
      user,
      {'action': 'delete', 'path': _bucketPath(path)},
    );
  }

  Future<HttpClientRequest> _openFunctionRequest(
    User user, {
    required String method,
    Map<String, String> headers = const {},
    String? contentType,
  }) async {
    _requireSupabase();
    final request = await _httpClient.openUrl(
      method,
      Uri.parse('${SupabaseConfig.url}/functions/v1/incident-photo'),
    );
    request.headers
      ..set('apikey', SupabaseConfig.anonKey)
      ..set(HttpHeaders.authorizationHeader, 'Bearer ${await user.getIdToken()}');
    if (contentType != null) {
      request.headers.contentType = ContentType.parse(contentType);
    }
    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }
    return request;
  }

  Future<dynamic> _invokeFunction(User user, Map<String, dynamic> body) async {
    return _requireSupabase().functions.invoke(
      'incident-photo',
      headers: {'Authorization': 'Bearer ${await user.getIdToken()}'},
      body: body,
    );
  }

  Future<void> _checkResponse(HttpClientResponse response) async {
    final responseBody = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message = responseBody;
      try {
        final decoded = jsonDecode(responseBody);
        if (decoded is Map && decoded['error'] is String) {
          message = decoded['error'] as String;
        }
      } on FormatException {
        // Keep the response body as the error when it isn't JSON.
      }
      throw HttpException(
        'Photo storage failed (${response.statusCode}): $message',
      );
    }
  }

  SupabaseClient _requireSupabase() {
    final client = _supabase;
    if (client == null) {
      throw StateError(
        'Photo storage is not configured. Set SUPABASE_URL and '
        'SUPABASE_ANON_KEY before running the app.',
      );
    }
    return client;
  }

  User _requireCurrentUser([String? expectedUid]) {
    final user = _auth.currentUser;
    if (user == null || (expectedUid != null && user.uid != expectedUid)) {
      throw StateError('A signed-in Firebase user is required for photo storage.');
    }
    return user;
  }

  static String _bucketPath(String path) {
    const prefix = 'incidents/';
    if (!path.startsWith(prefix)) {
      throw ArgumentError.value(path, 'path', 'Expected an incidents photo path.');
    }
    return path.substring(prefix.length);
  }
}
