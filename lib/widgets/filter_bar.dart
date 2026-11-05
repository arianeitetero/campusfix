import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/incident_category.dart';
import '../models/incident_filter.dart';
import '../models/incident_status.dart';
import '../providers/incident_provider.dart';

/// Search box plus a row of filter chips for the Browse tab. Reads and
/// writes [IncidentProvider.filter], so the list rebuilds automatically.
class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
        text: context.read<IncidentProvider>().filter.query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<IncidentProvider>();
    final filter = context.select<IncidentProvider, IncidentFilter>((p) => p.filter);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: provider.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search title, location or details',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: filter.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        provider.setQuery('');
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                label: const Text('Open only'),
                selected: filter.openOnly,
                onSelected: provider.setOpenOnly,
              ),
              const SizedBox(width: 8),
              _MenuChip<IncidentCategory>(
                label: filter.category?.label ?? 'Category',
                icon: filter.category?.icon ?? Icons.category_outlined,
                selected: filter.category != null,
                options: IncidentCategory.values,
                optionLabel: (c) => c.label,
                optionIcon: (c) => c.icon,
                onSelected: provider.setCategory,
              ),
              const SizedBox(width: 8),
              _MenuChip<IncidentStatus>(
                label: filter.status?.label ?? 'Status',
                icon: filter.status?.icon ?? Icons.flag_outlined,
                selected: filter.status != null,
                options: IncidentStatus.values,
                optionLabel: (s) => s.label,
                optionIcon: (s) => s.icon,
                onSelected: provider.setStatus,
              ),
              const SizedBox(width: 8),
              PopupMenuButton<IncidentSort>(
                tooltip: 'Sort',
                initialValue: filter.sort,
                onSelected: provider.setSort,
                itemBuilder: (_) => [
                  for (final s in IncidentSort.values)
                    PopupMenuItem(value: s, child: Text(s.label)),
                ],
                child: Chip(
                  avatar: const Icon(Icons.sort, size: 18),
                  label: Text(filter.sort.label),
                ),
              ),
              if (filter.hasActiveFilters) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () {
                    _search.clear();
                    provider.clearFilters();
                  },
                  child: const Text('Clear all'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A chip that opens a menu of options plus "Any" to clear the selection.
class _MenuChip<T> extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.options,
    required this.optionLabel,
    required this.optionIcon,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final List<T> options;
  final String Function(T) optionLabel;
  final IconData Function(T) optionIcon;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Wrap the option so "Any" (null) is distinguishable from a dismissed menu.
    return PopupMenuButton<_Choice<T>>(
      onSelected: (choice) => onSelected(choice.value),
      itemBuilder: (_) => [
        const PopupMenuItem(value: _Choice(null), child: Text('Any')),
        for (final o in options)
          PopupMenuItem(
            value: _Choice(o),
            child: Row(children: [
              Icon(optionIcon(o), size: 18),
              const SizedBox(width: 10),
              Text(optionLabel(o)),
            ]),
          ),
      ],
      child: Chip(
        avatar: Icon(icon, size: 18,
            color: selected ? scheme.onSecondaryContainer : null),
        label: Text(label),
        backgroundColor: selected ? scheme.secondaryContainer : null,
      ),
    );
  }
}

class _Choice<T> {
  const _Choice(this.value);
  final T? value;
}
