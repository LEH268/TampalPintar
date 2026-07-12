import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';
import '../services/dashcam_service.dart';
import '../services/drafts_store.dart';
import '../services/photo_securer.dart';
import '../services/position_resolver.dart';
import 'notifications.dart';
import 'wake_word/onnx_ort_runner.dart';
import 'wake_word/pcm_chunker.dart';
import 'wake_word/wake_word_gate.dart';

@pragma('vm:entry-point')
void startDrivingCallback() {
  FlutterForegroundTask.setTaskHandler(DrivingTaskHandler());
}

class DrivingTaskHandler extends TaskHandler {
  final _chunker = PcmChunker();
  final _gate =
      WakeWordGate(threshold: kWakeThreshold, debounce: kWakeDebounce);
  final _positions = PositionResolver();
  LoadedWakeWord? _models;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _sub;
  DraftsStore? _drafts;
  DashcamService? _dashcam;
  String? _uid, _dashcamId, _defaultVehicle;
  bool _scoring = false;
  bool _handlingWake = false;
  int _chunkCount = 0;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Own engine, own isolate: initialize everything from scratch here.
    // Uses `publishableKey` (not the brief's `anonKey`) so this new call site
    // doesn't add a second `deprecated_member_use` info beyond the one
    // pre-existing baseline info in lib/main.dart -- same key, non-deprecated
    // parameter name.
    await Supabase.initialize(
        url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);
    await AppNotifications.init();
    // Everything below can throw (missing/offline profile row, model load
    // failure, mic stream failure, ...), and by this point the native
    // "TampalPintar is listening" foreground notification is already
    // posted. Without this guard, an exception here would leave
    // `isRunningService` reporting true while `_models`/`_recorder`/`_sub`
    // stay null -- a zombie service that neither listens nor wakes on
    // anything, with zero feedback to the user. Stop the service instead of
    // lingering inert.
    try {
      final client = Supabase.instance.client;
      _uid = client.auth.currentUser?.id;
      if (_uid == null) {
        await FlutterForegroundTask.stopService();
        return;
      }
      final profile =
          await client.from('profiles').select().eq('id', _uid!).single();
      _dashcamId = profile['dashcam_id'] as String?;
      _defaultVehicle = profile['default_vehicle_type'] as String?;
      _dashcam = DashcamService(client);
      final docs = await getApplicationDocumentsDirectory();
      _drafts =
          DraftsStore(Directory('${docs.path}${Platform.pathSeparator}drafts'));
      _models = await WakeWordModels.load();

      _recorder = AudioRecorder();
      final stream = await _recorder!.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1));
      _sub = stream.listen(_onAudio);
      // ignore: avoid_print
      print('[wake] service started, listening');
    } catch (e) {
      // ignore: avoid_print
      print('[wake] service start FAILED: $e');
      FlutterForegroundTask.sendDataToMain({'event': 'start_failed'});
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _onAudio(Uint8List bytes) async {
    for (final chunk in _chunker.add(bytes)) {
      if (_scoring) continue; // drop chunks while inference runs (cheap + safe)
      _scoring = true;
      try {
        final score = await _models!.pipeline.processChunk(chunk);
        _chunkCount++;
        if (score != null && _chunkCount % 25 == 0) {
          // heartbeat for manual verification: ~every 2s
          // ignore: avoid_print
          print('[wake] score=${score.toStringAsFixed(3)}');
        }
        if (score != null && _gate.shouldFire(score)) {
          // ignore: avoid_print
          print('[wake] gate FIRED score=${score.toStringAsFixed(3)}');
          unawaited(_onWake());
        }
      } finally {
        _scoring = false;
      }
    }
  }

  Future<void> _onWake() async {
    // Reentrancy guard: `_onWake` can run for up to `kPhotoPollTimeout`
    // (15s), but `WakeWordGate`'s debounce is only `kWakeDebounce` (3s), so
    // a second wake 3-15s after the first would otherwise pass the gate and
    // spawn a concurrent `_onWake` -- duplicate draft, duplicate
    // notification, duplicate `securer.secure()` racing the same dashcam
    // folder. No `await` between the check and the set, so this is atomic
    // w.r.t. Dart's single-threaded event loop (same pattern as `_scoring`
    // in `_onAudio`).
    if (_handlingWake) {
      // ignore: avoid_print
      print('[wake] wake ignored: previous wake still in progress');
      return;
    }
    _handlingWake = true;
    try {
      final wakeAt = DateTime.now();
      // ignore: avoid_print
      print('[wake] requesting GPS fix...');
      final pos = await _positions.resolve();
      if (pos == null) {
        // ignore: avoid_print
        print('[wake] no GPS fix from any source — report skipped');
        await AppNotifications.recordingFailed();
        return;
      }
      // ignore: avoid_print
      print('[wake] GPS fix ok: ${pos.latitude},${pos.longitude}');
      final speedKmh =
          (pos.speed.isFinite && pos.speed > 0) ? pos.speed * 3.6 : null;
      final draft = await _drafts!.create(
        capturedAt: wakeAt,
        lat: pos.latitude,
        lng: pos.longitude,
        speedKmh: speedKmh,
        vehicleType: _defaultVehicle, // spec: prefill materialized at creation
      );
      // ignore: avoid_print
      print('[wake] draft created id=${draft.id}');
      await AppNotifications.potholeRecorded();
      // ignore: avoid_print
      print('[wake] notification posted');
      FlutterForegroundTask.sendDataToMain({'event': 'draft_created'});

      if (_dashcamId != null) {
        final securer = PhotoSecurer(
          list: () => _dashcam!.listLive(_dashcamId!),
          copy: _dashcam!.copyObject,
        );
        try {
          final secured = await securer.secure(
              wakeMs: wakeAt.millisecondsSinceEpoch,
              uid: _uid!,
              draftId: draft.id);
          if (secured != null) {
            draft.mediaPaths = secured.paths;
            draft.immediateIndex = secured.immediateIndex;
            await _drafts!.save(draft);
            FlutterForegroundTask.sendDataToMain({'event': 'draft_updated'});
          }
          // ignore: avoid_print
          print('[wake] photos secured: ${secured?.paths.length ?? 0}');
        } catch (e) {
          // ignore: avoid_print
          print('[wake] photo securing failed: $e');
          // Photo securing failed mid-copy (e.g. network drop in a moving
          // car). The notification already fired and the draft already has
          // GPS/timestamp/speed/vehicle prefill -- keep it as a photo-less,
          // still-reviewable pending report rather than losing it.
        }
      }
    } finally {
      _handlingWake = false;
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
    await _recorder?.stop();
    _recorder?.dispose();
    await _models?.dispose();
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') FlutterForegroundTask.stopService();
  }
}
