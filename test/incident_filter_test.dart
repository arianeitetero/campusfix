import 'package:campusfix/models/incident.dart';
import 'package:campusfix/models/incident_category.dart';
import 'package:campusfix/models/incident_filter.dart';
import 'package:campusfix/models/incident_status.dart';
import 'package:flutter_test/flutter_test.dart';

Incident _incident(
  String id, {
  String title = 'Something broken',
  IncidentCategory category = IncidentCategory.other,
  IncidentStatus status = IncidentStatus.submitted,
  String reporterId = 'u1',
  String location = 'Library',
  int daysAgo = 0,
  int confirmations = 0,
}) {
  final created = DateTime(2026, 11, 1).subtract(Duration(days: daysAgo));
  return Incident(
    id: id,
    title: title,
    description: 'Details about the problem',
    category: category,
    location: location,
    status: status,
    reporterId: reporterId,
    reporterName: 'Test',
    isAnonymous: false,
    createdAt: created,
    updatedAt: created,
    confirmedBy: List.generate(confirmations, (i) => 'c$i'),
  );
}

void main() {
  final items = [
    _incident('a', title: 'No water in hostel', category: IncidentCategory.water,
        daysAgo: 3, confirmations: 5),
    _incident('b', title: 'Power cut', category: IncidentCategory.electricity,
        status: IncidentStatus.resolved, reporterId: 'u2', daysAgo: 1),
    _incident('c', title: 'Broken chair', category: IncidentCategory.furniture,
        status: IncidentStatus.inProgress, location: 'Cafeteria', daysAgo: 2,
        confirmations: 1),
  ];

  List<String> ids(IncidentFilter f, {String uid = 'u1'}) =>
      f.apply(items, uid: uid).map((i) => i.id).toList();

  test('default filter shows everything newest first', () {
    expect(ids(const IncidentFilter()), ['b', 'c', 'a']);
  });

  test('filters by category and status', () {
    expect(ids(const IncidentFilter(category: IncidentCategory.water)), ['a']);
    expect(ids(const IncidentFilter(status: IncidentStatus.resolved)), ['b']);
  });

  test('openOnly hides resolved and rejected', () {
    expect(ids(const IncidentFilter(openOnly: true)), ['c', 'a']);
  });

  test('onlyMine keeps the current user\'s reports', () {
    expect(ids(const IncidentFilter(onlyMine: true), uid: 'u2'), ['b']);
  });

  test('search matches title, location and category label', () {
    expect(ids(const IncidentFilter(query: 'WATER')), ['a']);
    expect(ids(const IncidentFilter(query: 'cafeteria')), ['c']);
    expect(ids(const IncidentFilter(query: 'electric')), ['b']);
  });

  test('sorts by number of affected students', () {
    expect(ids(const IncidentFilter(sort: IncidentSort.mostConfirmed)),
        ['a', 'c', 'b']);
  });

  test('copyWith can clear a nullable field', () {
    const f = IncidentFilter(category: IncidentCategory.water);
    expect(f.copyWith(category: () => null).category, isNull);
    expect(f.copyWith(query: 'x').category, IncidentCategory.water);
  });

  test('reporter can only change a report while it is submitted', () {
    expect(items[0].canBeChangedBy('u1'), isTrue);
    expect(items[0].canBeChangedBy('u2'), isFalse);
    expect(items[2].canBeChangedBy('u1'), isFalse);
  });

  test('status transitions never offer the current status', () {
    for (final s in IncidentStatus.values) {
      expect(s.nextOptions, isNot(contains(s)));
      expect(s.nextOptions, isNotEmpty);
    }
  });
}
