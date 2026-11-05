import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident_category.dart';
import '../../models/incident_status.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/incident_card.dart';
import '../reports/incident_list_view.dart';

/// Staff landing tab: workload at a glance, where problems cluster, and the
/// queue of new reports waiting to be triaged.
class StaffDashboardScreen extends StatelessWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final counts = provider.countsByStatus;
    final byCategory = provider.openCountsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final queue = provider.awaitingTriage;
    final theme = Theme.of(context);

    if (provider.isLoading && provider.all.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Staff dashboard')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              for (final s in [
                IncidentStatus.submitted,
                IncidentStatus.inReview,
                IncidentStatus.inProgress,
                IncidentStatus.resolved,
              ])
                _StatTile(status: s, count: counts[s] ?? 0),
            ],
          ),
          const SizedBox(height: 24),
          Text('Open reports by category',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (byCategory.isEmpty)
            const Text('No open reports. Nice work!')
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    for (final e in byCategory)
                      _CategoryBar(
                        category: e.key,
                        count: e.value,
                        max: byCategory.first.value,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Text('Awaiting triage (${queue.length})',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text('Oldest first',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (queue.isEmpty)
            const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Queue is clear',
              message: 'New reports will show up here.',
            )
          else
            for (final incident in queue)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: IncidentCard(
                  incident: incident,
                  onTap: () => openIncident(context, incident.id),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.status, required this.count});
  final IncidentStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(status.icon, size: 18, color: status.color),
              const SizedBox(width: 6),
              Text(status.label, style: theme.textTheme.labelLarge),
            ]),
            Text('$count',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: status.color)),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.category,
    required this.count,
    required this.max,
  });

  final IncidentCategory category;
  final int count;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(category.icon, size: 18, color: category.color),
          const SizedBox(width: 8),
          SizedBox(width: 110, child: Text(category.label)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: count / max,
                minHeight: 8,
                color: category.color,
                backgroundColor: category.color.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
              width: 24, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
