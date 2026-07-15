import 'dart:typed_data';

/// Accumulates little-endian PCM16 byte buffers and emits fixed-size
/// sample chunks. A dangling odd byte is carried into the next call.
class PcmChunker {
  PcmChunker({this.chunkSamples = 1280});

  final int chunkSamples;
  final List<int> _pending = [];
  int? _carryByte;

  List<Int16List> add(Uint8List bytes) {
    var data = bytes;
    if (_carryByte != null) {
      data = Uint8List(bytes.length + 1);
      data[0] = _carryByte!;
      data.setRange(1, bytes.length + 1, bytes);
      _carryByte = null;
    }
    final sampleCount = data.length >> 1;
    if (data.length.isOdd) _carryByte = data[data.length - 1];
    final bd = ByteData.sublistView(data, 0, sampleCount * 2);
    for (var i = 0; i < sampleCount; i++) {
      _pending.add(bd.getInt16(i * 2, Endian.little));
    }
    final out = <Int16List>[];
    while (_pending.length >= chunkSamples) {
      out.add(Int16List.fromList(_pending.sublist(0, chunkSamples)));
      _pending.removeRange(0, chunkSamples);
    }
    return out;
  }
}
