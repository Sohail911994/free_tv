import re
from pathlib import Path

home = Path.home() / ".pub-cache"
if not home.exists():
    raise SystemExit("pub-cache missing")

for gradle in home.rglob("android/build.gradle"):
    text = gradle.read_text(errors="ignore")
    original = text
    if "jcenter()" in text:
        text = text.replace("jcenter()", "mavenCentral()")
    if "android {" in text and "namespace " not in text:
        manifest = gradle.parent / "src" / "main" / "AndroidManifest.xml"
        namespace = None
        if manifest.exists():
            match = re.search(r'package="([^"]+)"', manifest.read_text(errors="ignore"))
            if match:
                namespace = match.group(1)
        if namespace:
            text = text.replace("android {", f"android {{\n    namespace '{namespace}'", 1)
    if text != original:
        gradle.write_text(text)
        print("patched", gradle)

# Naya hissa: build ke Kotlin ko 2.2.21 par set karo
# taake wakelock_plus 1.4.0 ki metadata parh sake
for name in ("android/build.gradle", "android/settings.gradle"):
    path = Path(name)
    if not path.exists():
        continue
    text = path.read_text(errors="ignore")
    new = re.sub(
        r"ext\.kotlin_version\s*=\s*['\"][^'\"]+['\"]",
        "ext.kotlin_version = '2.2.21'",
        text,
    )
    if new != text:
        path.write_text(new)
        print("patched", path)
