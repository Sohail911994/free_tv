from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
text = manifest.read_text()

for permission in (
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.WAKE_LOCK",
):
    tag = f'<uses-permission android:name="{permission}"/>'
    if permission not in text:
        text = text.replace("<application", f"    {tag}\n    <application", 1)

if "usesCleartextTraffic" not in text:
    text = text.replace("<application", '<application android:usesCleartextTraffic="true"', 1)

text = text.replace('android:label="free_tv"', 'android:label="Free TV"')
manifest.write_text(text)
print("patched", manifest)
