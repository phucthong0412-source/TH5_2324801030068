String formatNoteDate(DateTime date) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year} · '
      '${two(local.hour)}:${two(local.minute)}';
}

bool isToday(DateTime date) {
  final now = DateTime.now();
  final local = date.toLocal();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}
