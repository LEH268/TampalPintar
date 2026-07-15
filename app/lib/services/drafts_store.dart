import 'dart:convert';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/draft.dart';

/// One JSON file per draft (`<dir>`/`<id>`.json). File-per-draft avoids write
/// clashes between the service isolate (creates) and the UI isolate (edits).
class DraftsStore {
  DraftsStore(this._dir);
  final Directory _dir;

  File _file(String id) => File('${_dir.path}${Platform.pathSeparator}$id.json');

  Future<Draft> create({
    required DateTime capturedAt,
    required double lat,
    required double lng,
    double? speedKmh,
    String? vehicleType,
  }) async {
    final draft = Draft(
      id: const Uuid().v4(),
      capturedAt: capturedAt,
      lat: lat,
      lng: lng,
      speedKmh: speedKmh,
      vehicleType: vehicleType,
    );
    await save(draft);
    return draft;
  }

  Future<void> save(Draft draft) async {
    await _dir.create(recursive: true);
    await _file(draft.id).writeAsString(jsonEncode(draft.toJson()));
  }

  Future<List<Draft>> list() async {
    if (!await _dir.exists()) return [];
    final drafts = <Draft>[];
    await for (final f in _dir.list()) {
      if (f is File && f.path.endsWith('.json')) {
        try {
          drafts.add(Draft.fromJson(
              jsonDecode(await f.readAsString()) as Map<String, dynamic>));
        } catch (_) {/* skip corrupt file */}
      }
    }
    drafts.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return drafts;
  }

  Future<void> delete(String id) async {
    final f = _file(id);
    if (await f.exists()) await f.delete();
  }
}
