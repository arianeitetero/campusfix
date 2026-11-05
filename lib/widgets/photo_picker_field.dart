import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'feedback.dart';

/// Optional photo attachment for the report form. Shows either the newly
/// picked file, the existing uploaded photo (when editing), or a picker.
class PhotoPickerField extends StatelessWidget {
  const PhotoPickerField({
    super.key,
    required this.file,
    required this.existingUrl,
    required this.onPicked,
    required this.onRemoved,
  });

  final File? file;
  final String? existingUrl;
  final ValueChanged<File> onPicked;
  final VoidCallback onRemoved;

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      // Downscale on device: faster uploads on campus Wi-Fi and less storage.
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 75,
      );
      if (picked != null) onPicked(File(picked.path));
    } catch (_) {
      if (context.mounted) {
        showMessage(context, 'Could not open the camera or gallery.',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = file != null || existingUrl != null;

    if (!hasImage) {
      return OutlinedButton.icon(
        onPressed: () => _pick(context),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Add a photo (optional)'),
      );
    }

    final image = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : Image.network(existingUrl!, fit: BoxFit.cover);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          AspectRatio(aspectRatio: 16 / 10, child: image),
          Positioned(
            top: 8,
            right: 8,
            child: Row(children: [
              IconButton.filledTonal(
                tooltip: 'Replace photo',
                onPressed: () => _pick(context),
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                tooltip: 'Remove photo',
                onPressed: onRemoved,
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
