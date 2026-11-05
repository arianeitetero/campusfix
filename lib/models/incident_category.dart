import 'package:flutter/material.dart';

/// The kinds of problem a student can report. The [name] of each value is
/// what gets stored in Firestore, so renaming a value is a data migration.
enum IncidentCategory {
  facilities('Broken facilities', Icons.handyman_outlined, Color(0xFF6D4C41)),
  water('Water', Icons.water_drop_outlined, Color(0xFF0277BD)),
  electricity('Electricity', Icons.bolt_outlined, Color(0xFFF9A825)),
  furniture('Furniture', Icons.chair_outlined, Color(0xFF8D6E63)),
  sanitation('Sanitation', Icons.cleaning_services_outlined, Color(0xFF2E7D32)),
  safety('Safety & security', Icons.shield_outlined, Color(0xFFC62828)),
  internet('Internet & IT', Icons.wifi_off_outlined, Color(0xFF5E35B1)),
  other('Other', Icons.more_horiz, Color(0xFF546E7A));

  const IncidentCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static IncidentCategory fromName(String? name) => IncidentCategory.values
      .firstWhere((c) => c.name == name, orElse: () => IncidentCategory.other);
}
