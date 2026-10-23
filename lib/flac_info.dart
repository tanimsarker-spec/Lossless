import 'dart:io';

/// Source-file facts read from a FLAC STREAMINFO block.
/// This describes the FILE, not what the output hardware receives.
class FlacInfo {
  final int sampleRate;
  final int bitsPerSample;
  final int channels;
  final double seconds;
  const FlacInfo(this.sampleRate, this.bitsPerSample, this.channels, this.seconds);
}

Future<FlacInfo?> readFlacInfo(String path) async {
  try {
    final f = await File(path).open();
    try {
      final h = await f.read(42);
      if (h.length < 26 || String.fromCharCodes(h.sublist(0, 4)) != 'fLaC') return null;
      if ((h[4] & 0x7f) != 0) return null; // first block must be STREAMINFO
      final d = h.sublist(8);
      final rate = (d[10] << 12) | (d[11] << 4) | (d[12] >> 4);
      final ch = ((d[12] >> 1) & 7) + 1;
      final bits = (((d[12] & 1) << 4) | (d[13] >> 4)) + 1;
      final total = ((d[13] & 15) << 32) | (d[14] << 24) | (d[15] << 16) | (d[16] << 8) | d[17];
      if (rate == 0) return null;
      return FlacInfo(rate, bits, ch, total / rate);
    } finally {
      await f.close();
    }
  } catch (_) {
    return null;
  }
}
