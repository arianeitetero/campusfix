import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';

/// Vertical timeline of every status change, streamed from the report's
/// `updates` subcollection.
class StatusHistory extends StatefulWidget {
  const StatusHistory({super.key, required this.incidentId});
  final String incidentId;

  @override
  State<StatusHistory> createState() => _StatusHistoryState();
}

class _StatusHistoryState extends State<StatusHistory> {
  // Created once so rebuilds of the parent don't resubscribe to Firestore.
  late final Stream<List<StatusUpdate>> _stream =
      context.read<IncidentProvider>().historyOf(widget.incidentId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<StatusUpdate>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Could not load history.',
              style: TextStyle(color: theme.colorScheme.error));
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final updates = snap.data!.reversed.toList();
        return Column(
          children: [
            for (var i = 0; i < updates.length; i++)
              _TimelineTile(update: updates[i], isLast: i == updates.length - 1),
          ],
        );
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.update, required this.isLast});
  final StatusUpdate update;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = update.status.color;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(update.status.icon, size: 16, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: theme.colorScheme.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(update.status.label,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700, color: color)),
                  Text('${update.byName} · ${fullDateTime(update.at)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  if (update.note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(update.note, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
