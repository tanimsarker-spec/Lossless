import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'player_service.dart';

const kBlue = Color(0xFF3D8BFF);
const kSilver = Color(0xFFC9CED6);
const kMute = Color(0xFF7D8590);
const kPanel = Color(0xFF121416);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.tanimsarker.lossless.playback',
    androidNotificationChannelName: 'LOSSLESS playback',
    androidNotificationOngoing: true,
  );
  runApp(const LosslessApp());
}

class LosslessApp extends StatelessWidget {
  const LosslessApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'LOSSLESS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(primary: kBlue, surface: kPanel),
          navigationBarTheme: const NavigationBarThemeData(
              backgroundColor: kPanel, indicatorColor: Color(0x333D8BFF)),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final svc = PlayerService.instance;

  Future<void> pick() async {
    final r = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.audio);
    if (r == null) return;
    await svc.addFiles(r.files.map((f) => f.path).whereType<String>().toList());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      LibraryPage(onAdd: pick, onPlay: (i) async { await svc.playIndex(i); setState(() => tab = 1); }),
      const NowPlayingPage(),
      const EqPage(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        toolbarHeight: 64,
        title: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('LOSSLESS',
              style: TextStyle(letterSpacing: 6, fontWeight: FontWeight.w700, fontSize: 18, color: kSilver)),
          SizedBox(height: 2),
          Text('TanimSarker', style: TextStyle(letterSpacing: 2, fontSize: 10, color: kMute)),
        ]),
      ),
      body: ValueListenableBuilder<String?>(
        valueListenable: svc.error,
        builder: (_, err, __) => Column(children: [
          if (err != null)
            Container(width: double.infinity, color: const Color(0xFF3A1414), padding: const EdgeInsets.all(12), child: Text(err)),
          Expanded(child: pages[tab]),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: 'Now Playing'),
          NavigationDestination(icon: Icon(Icons.equalizer), label: 'Equalizer'),
        ],
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  final VoidCallback onAdd;
  final void Function(int) onPlay;
  const LibraryPage({super.key, required this.onAdd, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final svc = PlayerService.instance;
    return ValueListenableBuilder<List<Track>>(
      valueListenable: svc.tracks,
      builder: (_, tracks, __) {
        if (tracks.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('No music yet', style: TextStyle(fontSize: 18, color: kSilver)),
              const SizedBox(height: 6),
              const Text('Pick FLAC, WAV, MP3, AAC or other audio files.', style: TextStyle(color: kMute)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onAdd, child: const Text('Add music files')),
            ]),
          );
        }
        return Stack(children: [
          ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: tracks.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFF1E2226)),
            itemBuilder: (_, i) => ListTile(
              title: Text(tracks[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(tracks[i].quality, style: const TextStyle(color: kMute, fontSize: 12)),
              onTap: () => onPlay(i),
            ),
          ),
          Positioned(right: 16, bottom: 16, child: FloatingActionButton.extended(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add files'))),
        ]);
      },
    );
  }
}

String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});
  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final svc = PlayerService.instance;
  double? drag;

  @override
  Widget build(BuildContext context) {
    final player = svc.player;
    return ValueListenableBuilder<List<Track>>(
      valueListenable: svc.tracks,
      builder: (_, tracks, __) {
        if (tracks.isEmpty) return const Center(child: Text('Nothing playing', style: TextStyle(color: kMute)));
        return StreamBuilder<int?>(
          stream: player.currentIndexStream,
          builder: (_, snap) {
            final i = (snap.data ?? 0).clamp(0, tracks.length - 1);
            final t = tracks[i];
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF2A3036)),
                          gradient: const LinearGradient(colors: [Color(0xFF1B2128), Color(0xFF0B0D0F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        child: const Icon(Icons.album, size: 96, color: kMute),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(t.title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text('Source: ${t.quality}', style: const TextStyle(color: kBlue, fontSize: 13)),
                const SizedBox(height: 4),
                const Text('Output rate and bit depth depend on your device and route.', style: TextStyle(color: kMute, fontSize: 11)),
                const SizedBox(height: 12),
                StreamBuilder<Duration?>(
                  stream: player.durationStream,
                  builder: (_, ds) {
                    final dur = ds.data ?? Duration.zero;
                    return StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (_, ps) {
                        final pos = ps.data ?? Duration.zero;
                        final max = dur.inMilliseconds.toDouble();
                        final v = drag ?? pos.inMilliseconds.toDouble();
                        return Column(children: [
                          Slider(
                            value: max <= 0 ? 0 : v.clamp(0, max).toDouble(),
                            max: max <= 0 ? 1 : max,
                            onChanged: max <= 0 ? null : (x) => setState(() => drag = x),
                            onChangeEnd: (x) { player.seek(Duration(milliseconds: x.round())); setState(() => drag = null); },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(_fmt(Duration(milliseconds: v.round())), style: const TextStyle(color: kMute, fontSize: 12)),
                              Text(_fmt(dur), style: const TextStyle(color: kMute, fontSize: 12)),
                            ]),
                          ),
                        ]);
                      },
                    );
                  },
                ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  StreamBuilder<bool>(
                    stream: player.shuffleModeEnabledStream,
                    builder: (_, s) => IconButton(
                      icon: Icon(Icons.shuffle, color: (s.data ?? false) ? kBlue : kMute),
                      onPressed: () => player.setShuffleModeEnabled(!(s.data ?? false)),
                    ),
                  ),
                  IconButton(iconSize: 36, icon: const Icon(Icons.skip_previous), onPressed: player.seekToPrevious),
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (_, s) {
                      final playing = s.data?.playing ?? false;
                      return IconButton.filled(
                        iconSize: 40,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: playing ? player.pause : player.play,
                      );
                    },
                  ),
                  IconButton(iconSize: 36, icon: const Icon(Icons.skip_next), onPressed: player.seekToNext),
                  StreamBuilder<LoopMode>(
                    stream: player.loopModeStream,
                    builder: (_, s) {
                      final m = s.data ?? LoopMode.off;
                      return IconButton(
                        icon: Icon(m == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: m == LoopMode.off ? kMute : kBlue),
                        onPressed: () => player.setLoopMode(LoopMode.values[(m.index + 1) % 3]),
                      );
                    },
                  ),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}

class EqPage extends StatelessWidget {
  const EqPage({super.key});
  @override
  Widget build(BuildContext context) {
    final svc = PlayerService.instance;
    if (!svc.eqSupported) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('The system equalizer is only exposed on Android. On iOS, a custom EQ needs the AVAudioEngine module planned for a later stage.', textAlign: TextAlign.center, style: TextStyle(color: kMute))),
      );
    }
    return ValueListenableBuilder<List<Track>>(
      valueListenable: svc.tracks,
      builder: (_, tracks, __) {
        if (tracks.isEmpty) return const Center(child: Text('Load a track to unlock the equalizer.', style: TextStyle(color: kMute)));
        final eq = svc.equalizer;
        return FutureBuilder<AndroidEqualizerParameters>(
          future: eq.parameters,
          builder: (_, snap) {
            final params = snap.data;
            if (params == null) {
              return Center(child: snap.hasError ? Text('Equalizer unavailable: ${snap.error}') : const CircularProgressIndicator());
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              StreamBuilder<bool>(
                stream: eq.enabledStream,
                builder: (_, s) => SwitchListTile(
                  title: const Text('Equalizer'),
                  subtitle: const Text('Off = unprocessed signal (bypass)', style: TextStyle(color: kMute)),
                  value: s.data ?? false,
                  onChanged: eq.setEnabled,
                ),
              ),
              for (final b in params.bands)
                StreamBuilder<double>(
                  stream: b.gainStream,
                  builder: (_, s) {
                    final g = (s.data ?? b.gain).clamp(params.minDecibels, params.maxDecibels).toDouble();
                    final hz = b.centerFrequency;
                    final label = hz >= 1000 ? '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)} kHz' : '${hz.round()} Hz';
                    return Row(children: [
                      SizedBox(width: 70, child: Text(label, style: const TextStyle(color: kSilver, fontSize: 13))),
                      Expanded(child: Slider(value: g, min: params.minDecibels, max: params.maxDecibels, onChanged: b.setGain)),
                      SizedBox(width: 56, child: Text('${g.toStringAsFixed(1)} dB', style: const TextStyle(color: kMute, fontSize: 12), textAlign: TextAlign.right)),
                    ]);
                  },
                ),
            ]);
          },
        );
      },
    );
  }
}
