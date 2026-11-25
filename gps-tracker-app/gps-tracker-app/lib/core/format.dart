/// "just now", "12s ago", "3 min ago"...
String formatAgo(DateTime t, {DateTime? now}) {
  final seconds = (now ?? DateTime.now()).difference(t).inSeconds;
  if (seconds < 5) return 'just now';
  if (seconds < 60) return '${seconds}s ago';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours h ago';
  return '${hours ~/ 24} d ago';
}

/// 09:41:07
String formatClock(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
