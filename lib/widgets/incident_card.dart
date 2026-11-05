import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../models/incident.dart';
import 'category_avatar.dart';
import 'status_chip.dart';

class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.incident,
    required this.onTap,
    this.isMine = false,
  });

  final Incident incident;
  final VoidCallback onTap;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryAvatar(incident.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            incident.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(incident.status, dense: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 8),
                    DefaultTextStyle(
                      style: theme.textTheme.labelSmall!.copyWith(color: muted),
                      child: Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: muted),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(incident.location,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 10),
                          Text(timeAgo(incident.createdAt)),
                          if (incident.confirmations > 0) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.group_outlined, size: 14, color: muted),
                            const SizedBox(width: 2),
                            Text('${incident.confirmations}'),
                          ],
                          if (incident.photoUrl != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.photo_outlined, size: 14, color: muted),
                          ],
                          if (isMine) ...[
                            const Spacer(),
                            Text('Yours',
                                style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
