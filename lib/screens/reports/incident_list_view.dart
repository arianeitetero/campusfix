import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import 'report_detail_screen.dart';

/// Scrollable list of incident cards with the shared loading and error
/// states. Used by the Browse, My reports and staff screens.
class IncidentListView extends StatelessWidget {
  const IncidentListView({
    super.key,
    required this.incidents,
    required this.empty,
  });

  final List<Incident> incidents;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final uid = provider.currentUser?.uid ?? '';

    if (provider.isLoading && provider.all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.all.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load reports',
        message: provider.error,
      );
    }
    if (incidents.isEmpty) return empty;

    return ListView.separated(
      // Bottom padding keeps the last card clear of the floating button.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: incidents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final incident = incidents[i];
        return IncidentCard(
          incident: incident,
          isMine: incident.isReportedBy(uid),
          onTap: () => openIncident(context, incident.id),
        );
      },
    );
  }
}

void openIncident(BuildContext context, String id) {
  Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReportDetailScreen(incidentId: id)));
}
