import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/services/dashcam_service.dart';

void main() {
  test('epochFromName parses zero-padded epoch-ms filenames', () {
    expect(DashcamService.epochFromName('0001767950000123.jpg'), 1767950000123);
    expect(DashcamService.epochFromName('1767950000123.jpg'), 1767950000123);
    expect(DashcamService.epochFromName('not-a-photo.txt'), isNull);
    expect(DashcamService.epochFromName('.emptyFolderPlaceholder'), isNull);
  });

  test('isFresh: within 10s window means connected', () {
    final now = DateTime.fromMillisecondsSinceEpoch(1767950010000);
    expect(DashcamService.isFresh(1767950001000, now), isTrue);  // 9s old
    expect(DashcamService.isFresh(1767949999000, now), isFalse); // 11s old
    expect(DashcamService.isFresh(null, now), isFalse);
  });
}
