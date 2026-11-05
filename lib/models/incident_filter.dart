import 'incident.dart';
import 'incident_category.dart';
import 'incident_status.dart';

enum IncidentSort {
  newest('Newest first'),
  mostConfirmed('Most affected'),
  recentlyUpdated('Recently updated');

  const IncidentSort(this.label);
  final String label;
}

/// Immutable description of what the report list should show. Kept free of
/// Flutter and Firebase so it can be unit tested directly.
class IncidentFilter {
  const IncidentFilter({
    this.query = '',
    this.category,
    this.status,
    this.onlyMine = false,
    this.openOnly = false,
    this.sort = IncidentSort.newest,
  });

  final String query;
  final IncidentCategory? category;
  final IncidentStatus? status;
  final bool onlyMine;
  final bool openOnly;
  final IncidentSort sort;

  bool get hasActiveFilters =>
      category != null || status != null || openOnly || query.isNotEmpty;

  IncidentFilter copyWith({
    String? query,
    IncidentCategory? Function()? category,
    IncidentStatus? Function()? status,
    bool? onlyMine,
    bool? openOnly,
    IncidentSort? sort,
  }) {
    return IncidentFilter(
      query: query ?? this.query,
      category: category != null ? category() : this.category,
      status: status != null ? status() : this.status,
      onlyMine: onlyMine ?? this.onlyMine,
      openOnly: openOnly ?? this.openOnly,
      sort: sort ?? this.sort,
    );
  }

  List<Incident> apply(Iterable<Incident> incidents, {required String uid}) {
    final result = incidents.where((i) {
      if (onlyMine && !i.isReportedBy(uid)) return false;
      if (category != null && i.category != category) return false;
      if (status != null && i.status != status) return false;
      if (openOnly && !i.status.isOpen) return false;
      return i.matchesQuery(query);
    }).toList();

    switch (sort) {
      case IncidentSort.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case IncidentSort.mostConfirmed:
        result.sort((a, b) {
          final byCount = b.confirmations.compareTo(a.confirmations);
          return byCount != 0 ? byCount : b.createdAt.compareTo(a.createdAt);
        });
      case IncidentSort.recentlyUpdated:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return result;
  }
}
