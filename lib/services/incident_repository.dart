import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_status.dart';
import 'storage_service.dart';

/// All Firestore reads and writes for incident reports.
///
/// Layout:
///   incidents/{incidentId}                 the report
///   incidents/{incidentId}/updates/{id}    status history (timeline)
class IncidentRepository {
  IncidentRepository({FirebaseFirestore? firestore, StorageService? storage})
      : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? StorageService();

  final FirebaseFirestore _db;
  final StorageService _storage;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  CollectionReference<Map<String, dynamic>> _updates(String incidentId) =>
      _incidents.doc(incidentId).collection('updates');

  Stream<List<Incident>> watchAll() => _incidents
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Incident.fromDoc).toList());

  Stream<List<StatusUpdate>> watchUpdates(String incidentId) =>
      _updates(incidentId)
          .orderBy('at')
          .snapshots()
          .map((snap) => snap.docs.map(StatusUpdate.fromDoc).toList());

  /// Uploads the photo first so the report never points at a missing image,
  /// then writes the report and its first timeline entry atomically.
  Future<String> create({
    required IncidentDraft draft,
    required AppUser reporter,
    File? photo,
  }) async {
    final ref = _incidents.doc();
    final uploaded = photo == null
        ? null
        : await _storage.uploadIncidentPhoto(
            uid: reporter.uid, incidentId: ref.id, file: photo);

    final batch = _db.batch()
      ..set(ref, {
        ...draft.toMap(),
        'status': IncidentStatus.submitted.name,
        'reporterId': reporter.uid,
        'reporterName': draft.isAnonymous ? '' : reporter.displayName,
        'photoUrl': null,
        'photoPath': uploaded?.path,
        'photoStorage': uploaded?.storage,
        'confirmedBy': <String>[],
        'latestNote': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_updates(ref.id).doc(), {
        'status': IncidentStatus.submitted.name,
        'note': 'Report submitted',
        'byId': reporter.uid,
        'byName': draft.isAnonymous ? 'Reporter' : reporter.displayName,
        'at': FieldValue.serverTimestamp(),
      });

    try {
      await batch.commit();
    } catch (_) {
      if (uploaded != null) {
        await _storage.deletePhoto(uploaded.path, storage: uploaded.storage);
      }
      rethrow;
    }
    return ref.id;
  }

  /// Reporter edit. [newPhoto] replaces the existing photo; [removePhoto]
  /// clears it without a replacement.
  Future<void> update({
    required Incident incident,
    required IncidentDraft draft,
    required AppUser reporter,
    File? newPhoto,
    bool removePhoto = false,
  }) async {
    final data = <String, dynamic>{
      ...draft.toMap(),
      'reporterName': draft.isAnonymous ? '' : reporter.displayName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    UploadedPhoto? uploaded;
    if (newPhoto != null) {
      uploaded = await _storage.uploadIncidentPhoto(
          uid: reporter.uid, incidentId: incident.id, file: newPhoto);
      data['photoUrl'] = null;
      data['photoPath'] = uploaded.path;
      data['photoStorage'] = uploaded.storage;
    } else if (removePhoto) {
      data['photoUrl'] = null;
      data['photoPath'] = null;
      data['photoStorage'] = null;
    }

    try {
      await _incidents.doc(incident.id).update(data);
    } catch (_) {
      if (uploaded != null) {
        await _storage.deletePhoto(uploaded.path, storage: uploaded.storage);
      }
      rethrow;
    }

    if (uploaded != null && incident.photoPath != null) {
      await _storage.deletePhoto(
        incident.photoPath!,
        storage: incident.photoStorage,
      );
    }

    if (removePhoto && incident.photoPath != null) {
      await _storage.deletePhoto(
        incident.photoPath!,
        storage: incident.photoStorage,
      );
    }
  }

  /// Removes the report, its history and its photo. Firestore does not
  /// delete subcollections automatically, so the history goes in the batch.
  Future<void> delete(Incident incident) async {
    final updates = await _updates(incident.id).get();
    final batch = _db.batch();
    for (final doc in updates.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_incidents.doc(incident.id));
    await batch.commit();

    if (incident.photoPath != null) {
      await _storage.deletePhoto(
        incident.photoPath!,
        storage: incident.photoStorage,
      );
    }
  }

  /// Staff-only (enforced by firestore.rules): changes the status and
  /// records who did it and why.
  Future<void> changeStatus({
    required String incidentId,
    required IncidentStatus status,
    required String note,
    required AppUser staff,
  }) async {
    final trimmed = note.trim();
    final batch = _db.batch()
      ..update(_incidents.doc(incidentId), {
        'status': status.name,
        'latestNote': trimmed.isEmpty ? null : trimmed,
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_updates(incidentId).doc(), {
        'status': status.name,
        'note': trimmed,
        'byId': staff.uid,
        'byName': staff.displayName,
        'at': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  Future<void> setConfirmation({
    required String incidentId,
    required String uid,
    required bool confirmed,
  }) {
    return _incidents.doc(incidentId).update({
      'confirmedBy': confirmed
          ? FieldValue.arrayUnion([uid])
          : FieldValue.arrayRemove([uid]),
    });
  }
}
