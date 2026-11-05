import 'package:flutter/material.dart';

import '../models/incident_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.dense = false});

  final IncidentStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: dense ? 13 : 15, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w600,
              fontSize: dense ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
