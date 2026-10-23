"""Run AFTER `flutter create --org com.tanimsarker --project-name lossless .`
Patches the generated Android/iOS projects for background audio. Idempotent."""
import pathlib, re
root = pathlib.Path(__file__).resolve().parent.parent

m = root / "android/app/src/main/AndroidManifest.xml"
s = m.read_text()
if "com.ryanheise.audioservice.AudioService" not in s:
    if "xmlns:tools" not in s:
        s = s.replace("<manifest ", '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
    perms = ('    <uses-permission android:name="android.permission.WAKE_LOCK"/>\n'
             '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>\n'
             '    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>\n')
    s = s.replace("<application", perms + "    <application", 1)
    svc = ('    <service android:name="com.ryanheise.audioservice.AudioService" android:foregroundServiceType="mediaPlayback" android:exported="true" tools:ignore="Instantiatable">\n'
           '      <intent-filter><action android:name="android.media.browse.MediaBrowserService"/></intent-filter>\n    </service>\n'
           '    <receiver android:name="com.ryanheise.audioservice.MediaButtonReceiver" android:exported="true" tools:ignore="Instantiatable">\n'
           '      <intent-filter><action android:name="android.intent.action.MEDIA_BUTTON"/></intent-filter>\n    </receiver>\n')
    s = s.replace("</application>", svc + "  </application>", 1)
    m.write_text(s)

for kt in (root / "android/app/src/main/kotlin").rglob("MainActivity.kt"):
    pkg = re.search(r"^package\s+([\w.]+)", kt.read_text(), re.M).group(1)
    kt.write_text(f"package {pkg}\n\nimport com.ryanheise.audioservice.AudioServiceActivity\n\nclass MainActivity : AudioServiceActivity()\n")

plist = root / "ios/Runner/Info.plist"
if plist.exists():
    p = plist.read_text()
    if "UIBackgroundModes" not in p:
        p = p.replace("<dict>", "<dict>\n\t<key>UIBackgroundModes</key>\n\t<array>\n\t\t<string>audio</string>\n\t</array>", 1)
        plist.write_text(p)

wt = root / "test/widget_test.dart"
if wt.exists():
    wt.unlink()
print("Platform patches applied.")
