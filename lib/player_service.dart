import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'flac_info.dart';

class Track {
  final String path;
  final FlacInfo? flac;
  Track(this.path, this.flac);

  String get title => p.basenameWithoutExtension(path);
  String get ext => p.extension(path).replaceFirst('.', '').toUpperCase();

  /// Source quality only. Never implies what the output device receives.
  String get quality {
    final f = flac;
    if (f == null) return ext.isEmpty ? 'Audio file' : ext;
    final khz = (f.sampleRate / 1000).toString().replaceAll(RegExp(r'\.0$'), '');
    final tier = (f.sampleRate > 44100 || f.bitsPerSample > 16) ? 'Hi-Res' : 'CD quality';
    return 'FLAC  $khz kHz / ${f.bitsPerSample}-bit  $tier';
  }
}

class PlayerService {
  PlayerService._();
  static final instance = PlayerService._();

  final equalizer = AndroidEqualizer();
  late final AudioPlayer player =
      AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [equalizer]));
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final tracks = ValueNotifier<List<Track>>([]);
  final error = ValueNotifier<String?>(null);
  bool _attached = false;

  bool get eqSupported => Platform.isAndroid;

  Future<void> addFiles(List<String> paths) async {
    try {
      final added = <Track>[];
      for (final path in paths) {
        final info = path.toLowerCase().endsWith('.flac') ? await readFlacInfo(path) : null;
        added.add(Track(path, info));
      }
      if (added.isEmpty) return;
      final wasEmpty = tracks.value.isEmpty;
      tracks.value = [...tracks.value, ...added];
      await _playlist.addAll([
        for (final t in added)
          AudioSource.uri(Uri.file(t.path),
              tag: MediaItem(id: t.path, title: t.title, artist: t.quality)),
      ]);
      if (!_attached) {
        await player.setAudioSource(_playlist);
        _attached = true;
      }
      if (wasEmpty) unawaited(player.play());
      error.value = null;
    } catch (e) {
      error.value = 'Could not load audio: $e';
    }
  }

  Future<void> playIndex(int i) async {
    await player.seek(Duration.zero, index: i);
    unawaited(player.play());
  }
}
