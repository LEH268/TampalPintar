import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import 'photo_securer.dart';

class DashcamService {
  DashcamService(this._client);
  final SupabaseClient _client;

  static int? epochFromName(String name) {
    if (!name.endsWith('.jpg')) return null;
    return int.tryParse(name.substring(0, name.length - 4));
  }

  static bool isFresh(int? newestEpochMs, DateTime now) {
    if (newestEpochMs == null) return false;
    return now.millisecondsSinceEpoch - newestEpochMs <=
        kDashcamConnectedWindow.inMilliseconds;
  }

  Future<List<LivePhoto>> listLive(String dashcamId, {int limit = 60}) async {
    final objects = await _client.storage.from('media').list(
        path: 'live/$dashcamId',
        searchOptions: SearchOptions(
            limit: limit,
            sortBy: const SortBy(column: 'name', order: 'desc')));
    final photos = <LivePhoto>[];
    for (final o in objects) {
      final epoch = epochFromName(o.name);
      if (epoch != null) photos.add(LivePhoto('live/$dashcamId/${o.name}', epoch));
    }
    photos.sort((a, b) => a.epochMs.compareTo(b.epochMs));
    return photos;
  }

  Future<bool> isConnected(String dashcamId) async {
    final photos = await listLive(dashcamId, limit: 1);
    return isFresh(photos.isEmpty ? null : photos.last.epochMs, DateTime.now());
  }

  Future<void> copyObject(String src, String dst) =>
      _client.storage.from('media').copy(src, dst);
}
