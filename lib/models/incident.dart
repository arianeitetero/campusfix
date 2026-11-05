import 'package:cloud_firestore/cloud_firestore.dart';

import 'incident_category.dart';
import 'incident_status.dart';

/// A report stored at `incidents/{id}`.
class Incident {
  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.isAnonymous,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.photoPath,
    this.confirmedBy = const [],
    this.latestNote,
  });

  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final IncidentStatus status;
  final String reporterId;

  /// Already blanked out when [isAnonymous] so other students never see it.
  final String reporterName;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? photoUrl;

  /// Storage path of the photo, kept so it can be deleted with the report.
  final String? photoPath;

  /// UIDs of students who tapped "Affects me too". Used to show staff how
  /// widespread a problem is without creating duplicate reports.
  final List<String> confirmedBy;

  /// Most recent staff note, denormalised so list cards can show it.
  final String? latestNote;

  int get confirmations => confirmedBy.length;

  bool isReportedBy(String uid) => reporterId == uid;

  /// Reporters may edit or withdraw a report only until staff pick it up.
  bool canBeChangedBy(String uid) =>
      isReportedBy(uid) && status == IncidentStatus.submitted;

  /// Case-insensitive match against the fields a user is likely to search.
  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        location.toLowerCase().contains(q) ||
        category.label.toLowerCase().contains(q);
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    // Server timestamps are null in the local echo of a write that has not
    // reached the server yet, so fall back to "now".
    DateTime readTime(String key) =>
        (data[key] as Timestamp?)?.toDate() ?? DateTime.now();

    return Incident(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: IncidentCategory.fromName(data['category'] as String?),
      location: data['location'] as String? ?? '',
      status: IncidentStatus.fromName(data['status'] as String?),
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      createdAt: readTime('createdAt'),
      updatedAt: readTime('updatedAt'),
      photoUrl: data['photoUrl'] as String?,
      photoPath: data['photoPath'] as String?,
      confirmedBy: List<String>.from(data['confirmedBy'] as List? ?? const []),
      latestNote: data['latestNote'] as String?,
    );
  }
}

/// The user-editable part of a report, produced by the report form.
class IncidentDraft {
  const IncidentDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.isAnonymous,
  });

  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final bool isAnonymous;

  Map<String, dynamic> toMap() => {
        'title': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'location': location.trim(),
        'isAnonymous': isAnonymous,
      };
}

/// One entry in a report's history, stored at `incidents/{id}/updates/{id}`.
class StatusUpdate {
  const StatusUpdate({
    required this.id,
    required this.status,
    required this.note,
    required this.byName,
    required this.at,
  });

  final String id;
  final IncidentStatus status;
  final String note;
  final String byName;
  final DateTime at;

  factory StatusUpdate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return StatusUpdate(
      id: doc.id,
      status: IncidentStatus.fromName(data['status'] as String?),
      note: data['note'] as String? ?? '',
      byName: data['byName'] as String? ?? '',
      at: (data['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
