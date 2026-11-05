import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_filter.dart';
import '../models/incident_status.dart';
import '../services/incident_repository.dart';

/// Holds the live list of incident reports plus the browse filter, and
/// exposes every incident action. Because all screens read incidents from
/// here, a status change made anywhere shows up everywhere at once.
class IncidentProvider extends ChangeNotifier {
  IncidentProvider(this._repo);

  final IncidentRepository _repo;
  StreamSubscription<List<Incident>>? _sub;

  AppUser? _user;
  List<Incident> _incidents = const [];
  bool _loading = false;
  String? _error;
  IncidentFilter _filter = const IncidentFilter();

  bool get isLoading => _loading;
  String? get error => _error;
  IncidentFilter get filter => _filter;
  AppUser? get currentUser => _user;
  String get _uid => _user?.uid ?? '';

  /// Reports for the Browse tab, after search, filters and sorting.
  List<Incident> get visible => _filter.apply(_incidents, uid: _uid);

  /// The signed-in user's own reports, newest first.
  List<Incident> get mine =>
      _incidents.where((i) => i.isReportedBy(_uid)).toList();

  List<Incident> get all => _incidents;

  Incident? byId(String id) {
    for (final i in _incidents) {
      if (i.id == id) return i;
    }
    return null;
  }

  Map<IncidentStatus, int> get countsByStatus => {
        for (final s in IncidentStatus.values)
          s: _incidents.where((i) => i.status == s).length,
      };

  Map<IncidentCategory, int> get openCountsByCategory {
    final counts = <IncidentCategory, int>{};
    for (final i in _incidents.where((i) => i.status.isOpen)) {
      counts[i.category] = (counts[i.category] ?? 0) + 1;
    }
    return counts;
  }

  /// New reports waiting for staff, oldest first so nothing is starved.
  List<Incident> get awaitingTriage => _incidents
      .where((i) => i.status == IncidentStatus.submitted)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  /// Wired to [AuthProvider] through a ChangeNotifierProxyProvider. Starts
  /// listening when someone signs in and drops all data when they sign out.
  void bindUser(AppUser? user) {
    final previousUid = _user?.uid;
    _user = user;
    if (user?.uid == previousUid) return;

    _sub?.cancel();
    _sub = null;
    _incidents = const [];
    _filter = const IncidentFilter();
    _error = null;
    if (user == null) return;

    _loading = true;
    _sub = _repo.watchAll().listen(
      (items) {
        _incidents = items;
        _loading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _loading = false;
        _error = _describe(e);
        notifyListeners();
      },
    );
  }

  // ---- Filters -----------------------------------------------------------

  void _setFilter(IncidentFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setQuery(String q) => _setFilter(_filter.copyWith(query: q));
  void setCategory(IncidentCategory? c) =>
      _setFilter(_filter.copyWith(category: () => c));
  void setStatus(IncidentStatus? s) =>
      _setFilter(_filter.copyWith(status: () => s));
  void setOpenOnly(bool v) => _setFilter(_filter.copyWith(openOnly: v));
  void setSort(IncidentSort s) => _setFilter(_filter.copyWith(sort: s));
  void clearFilters() =>
      _setFilter(IncidentFilter(sort: _filter.sort, onlyMine: _filter.onlyMine));

  // ---- Actions -----------------------------------------------------------
  // Each returns null on success or a user-facing error message.

  AppUser get _requireUser {
    final user = _user;
    if (user == null) throw StateError('Not signed in');
    return user;
  }

  Future<String?> submit(IncidentDraft draft, {File? photo}) => _guard(() =>
      _repo.create(draft: draft, reporter: _requireUser, photo: photo));

  Future<String?> edit(
    Incident incident,
    IncidentDraft draft, {
    File? newPhoto,
    bool removePhoto = false,
  }) =>
      _guard(() => _repo.update(
            incident: incident,
            draft: draft,
            reporter: _requireUser,
            newPhoto: newPhoto,
            removePhoto: removePhoto,
          ));

  Future<String?> withdraw(Incident incident) =>
      _guard(() => _repo.delete(incident));

  Future<String?> changeStatus(
    Incident incident,
    IncidentStatus status,
    String note,
  ) {
    if (!(_user?.isStaff ?? false)) {
      return Future.value('Only campus staff can update a report status.');
    }
    return _guard(() => _repo.changeStatus(
          incidentId: incident.id,
          status: status,
          note: note,
          staff: _requireUser,
        ));
  }

  Future<String?> toggleConfirmation(Incident incident) {
    final confirmed = incident.confirmedBy.contains(_uid);
    return _guard(() => _repo.setConfirmation(
          incidentId: incident.id,
          uid: _uid,
          confirmed: !confirmed,
        ));
  }

  Stream<List<StatusUpdate>> historyOf(String incidentId) =>
      _repo.watchUpdates(incidentId);

  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
      return null;
    } catch (e) {
      debugPrint('Incident action failed: $e');
      return _describe(e);
    }
  }

  static String _describe(Object e) {
    if (e is FirebaseException) {
      return switch (e.code) {
        'permission-denied' || 'unauthorized' =>
          'You do not have permission to do that.',
        'unavailable' => 'You appear to be offline. Try again shortly.',
        _ => e.message ?? 'Something went wrong (${e.code}).',
      };
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
