import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/elapsed.dart';

/// Live "Open for" duration, re-rendered every second (the stored
/// timestamps ARE the timer -- no backend process exists).
class OpenForTicker extends StatefulWidget {
  const OpenForTicker({super.key, required this.reportedAt});
  final DateTime reportedAt;
  @override
  State<OpenForTicker> createState() => _OpenForTickerState();
}

class _OpenForTickerState extends State<OpenForTicker> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        'Open for ${formatOpenFor(DateTime.now().difference(widget.reportedAt))}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
}
