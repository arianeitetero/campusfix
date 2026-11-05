import 'package:flutter/material.dart';

import '../models/incident_status.dart';

/// Horizontal step indicator: Submitted → In review → In progress → Resolved.
/// A rejected report shows a single banner instead.
class StatusTracker extends StatelessWidget {
  const StatusTracker({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (status == IncidentStatus.rejected) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: status.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(status.icon, color: status.color),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Staff closed this report without action. '
                'See the history below for the reason.'),
          ),
        ]),
      );
    }

    const steps = IncidentStatus.trackerSteps;
    final current = steps.indexOf(status);
    final active = theme.colorScheme.primary;
    final inactive = theme.colorScheme.outlineVariant;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.only(bottom: 22),
                color: i <= current ? active : inactive,
              ),
            ),
          Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: i <= current ? active : inactive,
                child: Icon(
                  i < current ? Icons.check : steps[i].icon,
                  size: 15,
                  color: i <= current ? Colors.white : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[i].label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: i == current ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
