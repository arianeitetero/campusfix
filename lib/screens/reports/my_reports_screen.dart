import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/empty_state.dart';
import 'incident_list_view.dart';

/// The user's own reports, split into open and closed so they can see at a
/// glance what is still being worked on.
class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mine = context.select<IncidentProvider, List<Incident>>((p) => p.mine);
    final open = mine.where((i) => i.status.isOpen).toList();
    final closed = mine.where((i) => !i.status.isOpen).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My reports'),
          bottom: TabBar(tabs: [
            Tab(text: 'Open (${open.length})'),
            Tab(text: 'Closed (${closed.length})'),
          ]),
        ),
        body: TabBarView(
          children: [
            IncidentListView(
              incidents: open,
              empty: const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'No open reports',
                message: 'Reports you submit appear here so you can track '
                    'their progress.',
              ),
            ),
            IncidentListView(
              incidents: closed,
              empty: const EmptyState(
                icon: Icons.task_alt,
                title: 'Nothing closed yet',
                message: 'Resolved and rejected reports move here.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
