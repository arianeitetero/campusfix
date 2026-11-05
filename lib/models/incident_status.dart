import 'package:flutter/material.dart';

/// Lifecycle of a report. Staff move a report forward through these states;
/// [rejected] covers duplicates, spam, or issues outside campus scope.
enum IncidentStatus {
  submitted('Submitted', Icons.outbox_outlined, Color(0xFF546E7A)),
  inReview('In review', Icons.visibility_outlined, Color(0xFF1565C0)),
  inProgress('In progress', Icons.construction_outlined, Color(0xFFEF6C00)),
  resolved('Resolved', Icons.check_circle_outline, Color(0xFF2E7D32)),
  rejected('Rejected', Icons.block_outlined, Color(0xFFC62828));

  const IncidentStatus(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  bool get isOpen => this != resolved && this != rejected;

  /// Statuses staff may move a report to from this one. Closed reports can be
  /// reopened in case a fix did not hold.
  List<IncidentStatus> get nextOptions => switch (this) {
        submitted => [inReview, inProgress, rejected],
        inReview => [inProgress, resolved, rejected],
        inProgress => [resolved, inReview],
        resolved => [inProgress],
        rejected => [inReview],
      };

  /// Ordered steps shown in the progress tracker on the detail screen.
  static const trackerSteps = [submitted, inReview, inProgress, resolved];

  static IncidentStatus fromName(String? name) => IncidentStatus.values
      .firstWhere((s) => s.name == name, orElse: () => IncidentStatus.submitted);
}
