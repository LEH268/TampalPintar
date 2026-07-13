String formatOpenFor(Duration d) {
  if (d.isNegative) d = Duration.zero;
  if (d.inDays >= 1) return '${d.inDays} hari ${d.inHours % 24} jam';
  if (d.inHours >= 1) {
    return '${d.inHours} jam ${(d.inMinutes % 60).toString().padLeft(2, '0')} min';
  }
  if (d.inMinutes >= 1) {
    return '${d.inMinutes} min ${(d.inSeconds % 60).toString().padLeft(2, '0')} saat';
  }
  return '${d.inSeconds} saat';
}
