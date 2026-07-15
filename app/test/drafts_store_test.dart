import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/services/drafts_store.dart';

void main() {
  late Directory dir;
  late DraftsStore store;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('drafts_test');
    store = DraftsStore(dir);
  });
  tearDown(() async => dir.delete(recursive: true));

  test('create persists a file and round-trips all fields', () async {
    final d = await store.create(
        capturedAt: DateTime.utc(2026, 7, 9, 8, 30),
        lat: 3.07,
        lng: 101.52,
        speedKmh: 64.5,
        vehicleType: 'car');
    final listed = await store.list();
    expect(listed, hasLength(1));
    final r = listed.first;
    expect(r.id, d.id);
    expect(r.capturedAt, DateTime.utc(2026, 7, 9, 8, 30));
    expect(r.lat, 3.07);
    expect(r.speedKmh, 64.5);
    expect(r.vehicleType, 'car'); // profile default materialized at creation
    expect(r.lanePosition, isNull);
    expect(r.mediaPaths, isEmpty);
  });

  test('save updates media + answers; other drafts untouched', () async {
    final a = await store.create(
        capturedAt: DateTime.utc(2026, 1, 1), lat: 1, lng: 2, vehicleType: 'car');
    final b = await store.create(
        capturedAt: DateTime.utc(2026, 1, 2), lat: 3, lng: 4, vehicleType: 'car');
    a.mediaPaths = ['reports/u/x/f0.jpg'];
    a.immediateIndex = 0;
    a.vehicleType = 'motorcycle'; // per-draft override
    a.impactSeverity = 'swerve';
    await store.save(a);
    final listed = await store.list();
    final ra = listed.singleWhere((d) => d.id == a.id);
    final rb = listed.singleWhere((d) => d.id == b.id);
    expect(ra.vehicleType, 'motorcycle');
    expect(ra.mediaPaths, ['reports/u/x/f0.jpg']);
    expect(rb.vehicleType, 'car'); // override confined to draft a
  });

  test('list is newest-first; delete removes only that draft', () async {
    final old = await store.create(
        capturedAt: DateTime.utc(2026, 1, 1), lat: 1, lng: 2);
    final recent = await store.create(
        capturedAt: DateTime.utc(2026, 6, 1), lat: 1, lng: 2);
    expect((await store.list()).first.id, recent.id);
    await store.delete(recent.id);
    final left = await store.list();
    expect(left, hasLength(1));
    expect(left.first.id, old.id);
  });
}
