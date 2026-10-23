# LOSSLESS — by TanimSarker

Audiophile local music player (Flutter). **Stage 1**: real playback, background audio, gapless queue, FLAC source-quality readout, Android system equalizer with bypass.

## Build
```
flutter create --org com.tanimsarker --project-name lossless .
python3 tool/setup_platforms.py     # background-audio patches (Android + iOS)
flutter pub get
flutter test
flutter run                          # device attached
flutter build apk --release          # Android APK
flutter build appbundle --release    # Play Store AAB (set up your own signing key first)
flutter build ipa                    # iOS, needs macOS + Xcode + Apple signing
```
Pushing to GitHub also runs `.github/workflows/android.yml`, which builds the APK and uploads it as an artifact.

## What works (Stage 1)
- Play local files from the system picker; gapless queue, seek, shuffle, repeat, next/previous
- Background playback + lock-screen/notification controls (just_audio_background)
- FLAC STREAMINFO parsing: shows the **file's** sample rate and bit depth; labels Hi-Res only if above 16-bit/44.1 kHz
- Android: system equalizer (bands from the device) with an on/off bypass

## Honest limits
- Output rate/bit depth are **not** reported; the OS and route decide them. No "bit-perfect" claim is made.
- Bluetooth is always lossy.
- iOS has no equalizer yet (needs an AVAudioEngine module). iOS background audio is patched in but untested by the author on device.
- Not implemented yet: library DB, search, playlists, tag editing, lyrics, ReplayGain, crossfade, parametric EQ, per-device profiles, themes, backup, APE/WMA.
- Untested on real devices by the author: please run on hardware before release.

## Licenses
just_audio (MIT), just_audio_background (MIT), file_picker (MIT), path (BSD-3), Flutter (BSD-3). Check each package's license again before commercial release.

## Roadmap (your priority order)
1. Library scanner + SQLite  2. Output-route display (Android AudioDeviceInfo / iOS AVAudioSession)  3. Shared C++ DSP core (parametric EQ, ReplayGain, limiter)  4. Lyrics/LRC  5. Playlists, history, themes
