from pathlib import Path
import re

manifest_path = Path("android/app/src/main/AndroidManifest.xml")
if not manifest_path.exists():
    raise SystemExit(f"Manifest not found: {manifest_path}")

text = manifest_path.read_text(encoding="utf-8")

# Required permissions
permissions = [
    "android.permission.INTERNET",
    "android.permission.ACCESS_NETWORK_STATE",
    "android.permission.WAKE_LOCK",
]

for perm in permissions:
    if perm not in text:
        tag = f'    <uses-permission android:name="{perm}"/>\n'
        text = re.sub(r"(\s*)(<application)", rf"\1{tag}\1\2", text, count=1)

# Cleartext traffic
if "usesCleartextTraffic" not in text:
    text = re.sub(
        r"(<application)(\s)",
        r'\1 android:usesCleartextTraffic="true"\2',
        text,
        count=1,
    )

# App label
text = text.replace('android:label="free_tv"', 'android:label="Free TV"')

manifest_path.write_text(text, encoding="utf-8")
print("=== Patched AndroidManifest.xml ===")
print(text)
print("==================================")
