import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_bar.dart';
import 'incident_list_view.dart';

class BrowseReportsScreen extends StatelessWidget {
  const BrowseReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final visible = provider.visible;

    return Scaffold(
      appBar: AppBar(title: const Text('Campus reports')),
      body: Column(
        children: [
          const FilterBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${visible.length} of ${provider.all.length} reports',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          Expanded(
            child: IncidentListView(
              incidents: visible,
              empty: provider.filter.hasActiveFilters
                  ? EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'No reports match',
                      message: 'Try a different search or clear the filters.',
                      action: TextButton(
                        onPressed: provider.clearFilters,
                        child: const Text('Clear filters'),
                      ),
                    )
                  : const EmptyState(
                      icon: Icons.verified_outlined,
                      title: 'No reports yet',
                      message: 'Spotted something broken? Be the first to '
                          'report it.',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
