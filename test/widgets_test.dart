import 'package:campusfix/core/formatters.dart';
import 'package:campusfix/models/incident_status.dart';
import 'package:campusfix/widgets/status_chip.dart';
import 'package:campusfix/widgets/status_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('StatusChip shows the status label', (tester) async {
    await tester.pumpWidget(_wrap(const StatusChip(IncidentStatus.inProgress)));
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('StatusTracker shows all steps for an open report',
      (tester) async {
    await tester
        .pumpWidget(_wrap(const StatusTracker(status: IncidentStatus.inReview)));
    for (final s in IncidentStatus.trackerSteps) {
      expect(find.text(s.label), findsOneWidget);
    }
    // Completed step gets a check mark.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('StatusTracker explains a rejected report', (tester) async {
    await tester
        .pumpWidget(_wrap(const StatusTracker(status: IncidentStatus.rejected)));
    expect(find.textContaining('without action'), findsOneWidget);
  });

  test('timeAgo formats recent times', () {
    final now = DateTime(2026, 11, 5, 12);
    expect(timeAgo(now, now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 h ago');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2 d ago');
  });
}
