import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:tampal_pintar/driving/wake_word/pcm_chunker.dart';

Uint8List pcmBytes(List<int> samples) {
  final b = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    b.setInt16(i * 2, samples[i], Endian.little);
  }
  return b.buffer.asUint8List();
}

void main() {
  test('exactly one chunk from 1280 samples', () {
    final c = PcmChunker();
    final out = c.add(pcmBytes(List.generate(1280, (i) => i - 640)));
    expect(out, hasLength(1));
    expect(out.first.length, 1280);
    expect(out.first[0], -640);
    expect(out.first[1279], 639);
  });

  test('accumulates across calls', () {
    final c = PcmChunker();
    expect(c.add(pcmBytes(List.filled(1000, 7))), isEmpty);
    final out = c.add(pcmBytes(List.filled(300, 8)));
    expect(out, hasLength(1));
    expect(out.first[999], 7);
    expect(out.first[1000], 8);
  });

  test('odd trailing byte carries into the next call', () {
    final c = PcmChunker(chunkSamples: 2);
    final whole = pcmBytes([1000, -1000, 2000, -2000]);
    expect(c.add(whole.sublist(0, 3)), isEmpty); // 1.5 samples
    final out = c.add(whole.sublist(3));
    expect(out, hasLength(2));
    expect(out[0].toList(), [1000, -1000]);
    expect(out[1].toList(), [2000, -2000]);
  });

  test('multiple chunks in one call', () {
    final c = PcmChunker(chunkSamples: 4);
    final out = c.add(pcmBytes(List.generate(9, (i) => i)));
    expect(out, hasLength(2));
    expect(out[1].toList(), [4, 5, 6, 7]);
  });
}
