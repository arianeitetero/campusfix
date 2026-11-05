import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../models/incident.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feedback.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/status_tracker.dart';
import '../staff/status_update_sheet.dart';
import 'report_form_screen.dart';
import 'status_history.dart';

/// Looks the report up by id in [IncidentProvider] rather than receiving an
/// [Incident] object, so staff updates and edits appear here live.
class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.incidentId});

  final String incidentId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IncidentProvider>();
    final incident = provider.byId(incidentId);
    final user = provider.currentUser;

    if (incident == null || user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.delete_sweep_outlined,
          title: 'Report not available',
          message: 'It may have been withdrawn by the reporter.',
        ),
      );
    }

    final canChange = incident.canBeChangedBy(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report details'),
        actions: [
          if (canChange)
            PopupMenuButton<String>(
              onSelected: (action) => action == 'edit'
                  ? Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ReportFormScreen(existing: incident)))
                  : _withdraw(context, incident),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Withdraw report')),
                ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: user.isStaff
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: () => showStatusUpdateSheet(context, incident),
                  icon: const Icon(Icons.published_with_changes),
                  label: const Text('Update status'),
                ),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (incident.photoUrl != null) _Photo(url: incident.photoUrl!),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(incident: incident),
                const SizedBox(height: 20),
                StatusTracker(status: incident.status),
                const SizedBox(height: 20),
                _InfoCard(incident: incident, viewerIsStaff: user.isStaff),
                const SizedBox(height: 16),
                Text('Description',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(incident.description,
                    style: Theme.of(context).textTheme.bodyMedium),
                if (!incident.isReportedBy(user.uid) &&
                    incident.status.isOpen) ...[
                  const SizedBox(height: 16),
                  _ConfirmButton(incident: incident, uid: user.uid),
                ],
                const SizedBox(height: 24),
                Text('History',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                StatusHistory(incidentId: incident.id),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _withdraw(BuildContext context, Incident incident) async {
    final ok = await confirmAction(
      context,
      title: 'Withdraw this report?',
      message: 'It will be permanently deleted, including its photo.',
      confirmLabel: 'Withdraw',
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    final provider = context.read<IncidentProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.withdraw(incident);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report withdrawn.')));
    }
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
              backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(
            child: InteractiveViewer(child: Image.network(url)),
          ),
        ),
      )),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined, size: 48)),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.incident});
  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryAvatar(incident.category, size: 52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(incident.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusChip(incident.status),
                  Text(incident.category.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.incident, required this.viewerIsStaff});
  final Incident incident;
  final bool viewerIsStaff;

  @override
  Widget build(BuildContext context) {
    final reporter = incident.isAnonymous
        ? (viewerIsStaff ? 'Anonymous to students' : 'Anonymous')
        : incident.reporterName;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            _InfoRow(Icons.place_outlined, 'Location', incident.location),
            _InfoRow(Icons.person_outline, 'Reported by', reporter),
            _InfoRow(Icons.schedule, 'Reported',
                fullDateTime(incident.createdAt)),
            _InfoRow(Icons.update, 'Last updated', timeAgo(incident.updatedAt)),
            _InfoRow(Icons.group_outlined, 'Also affected',
                '${incident.confirmations} other student(s)'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20),
      title: Text(label,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

/// "Affects me too" lets other students signal impact instead of filing a
/// duplicate report.
class _ConfirmButton extends StatefulWidget {
  const _ConfirmButton({required this.incident, required this.uid});
  final Incident incident;
  final String uid;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final error =
        await context.read<IncidentProvider>().toggleConfirmation(widget.incident);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) showMessage(context, error, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = widget.incident.confirmedBy.contains(widget.uid);
    return OutlinedButton.icon(
      onPressed: _busy ? null : _toggle,
      icon: Icon(confirmed ? Icons.check : Icons.group_add_outlined),
      label: Text(confirmed
          ? 'You are affected too (tap to undo)'
          : 'This affects me too'),
    );
  }
}
