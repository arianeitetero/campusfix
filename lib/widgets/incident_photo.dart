import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class IncidentPhoto extends StatefulWidget {
  const IncidentPhoto({
    super.key,
    required this.path,
    required this.storage,
    this.url,
    this.fit = BoxFit.cover,
  });

  final String? path;
  final String storage;
  final String? url;
  final BoxFit fit;

  @override
  State<IncidentPhoto> createState() => _IncidentPhotoState();
}

class _IncidentPhotoState extends State<IncidentPhoto> {
  late Future<String>? _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = _resolvePhotoUrl();
  }

  @override
  void didUpdateWidget(covariant IncidentPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.path != widget.path ||
        oldWidget.storage != widget.storage) {
      _photoUrl = _resolvePhotoUrl();
    }
  }

  Future<String>? _resolvePhotoUrl() {
    if (widget.url != null) return Future.value(widget.url);
    final path = widget.path;
    if (path == null) return null;
    return StorageService().getPhotoUrl(path: path, storage: widget.storage);
  }

  @override
  Widget build(BuildContext context) {
    final future = _photoUrl;
    if (future == null) return _errorIcon();

    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _errorIcon();
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return Image.network(
          snapshot.data!,
          fit: widget.fit,
          errorBuilder: (_, _, _) => _errorIcon(),
        );
      },
    );
  }

  Widget _errorIcon() =>
      const Center(child: Icon(Icons.broken_image_outlined, size: 48));
}
