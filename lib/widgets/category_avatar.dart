import 'package:flutter/material.dart';

import '../models/incident_category.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar(this.category, {super.key, this.size = 44});

  final IncidentCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(category.icon, color: category.color, size: size * 0.5),
    );
  }
}
