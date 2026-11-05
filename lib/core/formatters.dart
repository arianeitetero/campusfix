import 'package:intl/intl.dart';

/// "just now", "5 min ago", "3 h ago", "2 d ago", then an absolute date.
String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes} min ago';
  if (diff.inDays < 1) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return DateFormat.yMMMd().format(time);
}

String fullDateTime(DateTime time) => DateFormat('d MMM y, HH:mm').format(time);
