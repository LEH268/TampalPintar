import '../config.dart';
import 'pick_seven.dart';

class LivePhoto {
  const LivePhoto(this.path, this.epochMs);
  final String path;
  final int epochMs;
}

class SecuredPhotos {
  const SecuredPhotos(this.paths, this.immediateIndex);
  final List<String> paths;
  final int immediateIndex;
}

/// Copies the 7-photo evidence window out of live/ into the draft's
/// reports/ folder at wake time, so an ESP32 reboot can't destroy it.
class PhotoSecurer {
  PhotoSecurer({
    required this.list,
    required this.copy,
    this.wait = Future.delayed,
    this.pollInterval = kPhotoPollInterval,
    this.timeout = kPhotoPollTimeout,
    this.slackMs = 300,
  });

  final Future<List<LivePhoto>> Function() list;
  final Future<void> Function(String src, String dst) copy;
  final Future<void> Function(Duration) wait;
  final Duration pollInterval;
  final Duration timeout;
  final int slackMs;

  Future<SecuredPhotos?> secure({
    required int wakeMs,
    required String uid,
    required String draftId,
  }) async {
    var photos = await list();
    var elapsed = Duration.zero;
    while (_countAfter(photos, wakeMs) < 3 && elapsed < timeout) {
      await wait(pollInterval);
      elapsed += pollInterval;
      photos = await list();
    }
    final sorted = [...photos]..sort((a, b) => a.epochMs.compareTo(b.epochMs));
    final pick = pickSeven([for (final p in sorted) p.epochMs], wakeMs,
        slackMs: slackMs);
    if (pick == null) return null;
    final byEpoch = {for (final p in sorted) p.epochMs: p.path};
    final dsts = <String>[];
    for (var i = 0; i < pick.epochsMs.length; i++) {
      final dst = 'reports/$uid/$draftId/f$i.jpg';
      await copy(byEpoch[pick.epochsMs[i]]!, dst);
      dsts.add(dst);
    }
    return SecuredPhotos(dsts, pick.immediateIndex);
  }

  int _countAfter(List<LivePhoto> photos, int wakeMs) =>
      photos.where((p) => p.epochMs > wakeMs + slackMs).length;
}
