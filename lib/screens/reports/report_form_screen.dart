import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators.dart';
import '../../models/incident.dart';
import '../../models/incident_category.dart';
import '../../providers/incident_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/loading_button.dart';
import '../../widgets/photo_picker_field.dart';

/// Creates a new report, or edits [existing] while it is still "Submitted".
class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, this.existing});

  final Incident? existing;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  /// Common spots on campus, offered as one-tap fills for the location field.
  static const _locationSuggestions = [
    'Library',
    'Cafeteria',
    'Main hall',
    'Classroom block',
    'Hostel',
    'Sports field',
    'Parking',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _location;
  IncidentCategory? _category;
  bool _anonymous = false;
  File? _photo;
  bool _removeExistingPhoto = false;
  bool _saving = false;
  bool _categoryError = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _description = TextEditingController(text: e?.description);
    _location = TextEditingController(text: e?.location);
    _category = e?.category;
    _anonymous = e?.isAnonymous ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  String? get _existingPhotoUrl =>
      _removeExistingPhoto ? null : widget.existing?.photoUrl;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final formOk = _formKey.currentState!.validate();
    setState(() => _categoryError = _category == null);
    if (!formOk || _category == null) {
      showMessage(context, 'Please fix the highlighted fields.', isError: true);
      return;
    }

    final draft = IncidentDraft(
      title: _title.text,
      description: _description.text,
      category: _category!,
      location: _location.text,
      isAnonymous: _anonymous,
    );
    final provider = context.read<IncidentProvider>();

    setState(() => _saving = true);
    final error = _isEditing
        ? await provider.edit(widget.existing!, draft,
            newPhoto: _photo, removePhoto: _removeExistingPhoto)
        : await provider.submit(draft, photo: _photo);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      showMessage(context, error, isError: true);
      return;
    }
    showMessage(
        context,
        _isEditing
            ? 'Report updated.'
            : 'Report submitted. Staff have been notified.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // Don't let a half-finished upload be abandoned by the back gesture.
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit report' : 'Report an issue')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SectionLabel('What kind of issue is it?',
                  error: _categoryError ? 'Choose a category' : null),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in IncidentCategory.values)
                    ChoiceChip(
                      avatar: Icon(c.icon,
                          size: 18, color: _category == c ? null : c.color),
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() {
                        _category = c;
                        _categoryError = false;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Details'),
              TextFormField(
                controller: _title,
                maxLength: Validators.titleMax,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.incidentTitle,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. No water in block B showers',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _location,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: Validators.location,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'Building, floor, room',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _locationSuggestions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_locationSuggestions[i]),
                    onPressed: () =>
                        _location.text = '${_locationSuggestions[i]}, ',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                maxLength: Validators.descriptionMax,
                textCapitalization: TextCapitalization.sentences,
                validator: Validators.incidentDescription,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is wrong, since when, and how it affects '
                      'people',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Photo'),
              PhotoPickerField(
                file: _photo,
                existingUrl: _existingPhotoUrl,
                onPicked: (f) => setState(() => _photo = f),
                onRemoved: () => setState(() {
                  if (_photo != null) {
                    _photo = null;
                  } else {
                    _removeExistingPhoto = true;
                  }
                }),
              ),
              const SizedBox(height: 16),
              Card(
                child: SwitchListTile(
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                  title: const Text('Hide my name from other students'),
                  subtitle: Text(
                    'Useful for safety concerns. Campus staff can still '
                    'contact you about the report.',
                    style: theme.textTheme.bodySmall,
                  ),
                  secondary: const Icon(Icons.visibility_off_outlined),
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                label: _isEditing ? 'Save changes' : 'Submit report',
                icon: _isEditing ? Icons.save_outlined : Icons.send_outlined,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.error});

  final String text;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(text,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (error != null) ...[
            const SizedBox(width: 8),
            Text(error!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}
