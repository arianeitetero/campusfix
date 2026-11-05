import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/incident.dart';
import '../../models/incident_status.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';

Future<void> showStatusUpdateSheet(BuildContext context, Incident incident) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StatusUpdateSheet(incident: incident),
  );
}

/// Staff-only form for moving a report to its next status with a note that
/// the reporter will see in the history.
class _StatusUpdateSheet extends StatefulWidget {
  const _StatusUpdateSheet({required this.incident});
  final Incident incident;

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  late IncidentStatus _selected = widget.incident.status.nextOptions.first;
  bool _saving = false;

  /// Closing a report always needs an explanation for the reporter.
  bool get _noteRequired =>
      _selected == IncidentStatus.rejected || _selected == IncidentStatus.resolved;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final error = await context
        .read<IncidentProvider>()
        .changeStatus(widget.incident, _selected, _note.text);
    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      showMessage(context, error, isError: true);
    } else {
      Navigator.pop(context);
      messenger.showSnackBar(
          SnackBar(content: Text('Status changed to ${_selected.label}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = widget.incident.status.nextOptions;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Currently: ${widget.incident.status.label}',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in options)
                  ChoiceChip(
                    avatar: Icon(s.icon, size: 18,
                        color: _selected == s ? null : s.color),
                    label: Text(s.label),
                    selected: _selected == s,
                    onSelected: (_) => setState(() => _selected = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => _noteRequired && (v?.trim().isEmpty ?? true)
                  ? 'Tell the reporter why this is ${_selected.label.toLowerCase()}'
                  : null,
              decoration: InputDecoration(
                labelText: _noteRequired ? 'Note to reporter' : 'Note (optional)',
                hintText: 'e.g. Plumber scheduled for Tuesday morning',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            LoadingButton(label: 'Save', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
