import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lossless/flac_info.dart';

void main() {
  test('reads 96 kHz / 24-bit / stereo / 10 s STREAMINFO', () async {
    final d = List<int>.filled(34, 0);
    d[10] = 0x17; d[11] = 0x70; d[12] = 3; d[13] = 0x70;
    d[14] = 0; d[15] = 0x0E; d[16] = 0xA6; d[17] = 0;
    final bytes = [...'fLaC'.codeUnits, 0, 0, 0, 34, ...d];
    final dir = Directory.systemTemp.createTempSync();
    final f = File('${dir.path}/t.flac')..writeAsBytesSync(bytes);
    final info = await readFlacInfo(f.path);
    expect(info, isNotNull);
    expect(info!.sampleRate, 96000);
    expect(info.bitsPerSample, 24);
    expect(info.channels, 2);
    expect(info.seconds, closeTo(10, 0.001));
    dir.deleteSync(recursive: true);
  });

  test('returns null for non-FLAC data', () async {
    final dir = Directory.systemTemp.createTempSync();
    final f = File('${dir.path}/x.flac')..writeAsBytesSync(List<int>.filled(64, 1));
    expect(await readFlacInfo(f.path), isNull);
    dir.deleteSync(recursive: true);
  });
}
