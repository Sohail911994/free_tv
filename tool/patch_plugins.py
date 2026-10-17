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
    if "android {" in text and "namespace " not in text and "namespace=" not in text:
        manifest = gradle.parent / "src" / "main" / "AndroidManifest.xml"
        namespace = None
        if manifest.exists():
            match = re.search(r'package="([^"]+)"', manifest.read_text(errors="ignore"))
            if match:
                namespace = match.group(1)
        if namespace is None and "better_player" in str(gradle):
            namespace = "com.jhomlala.better_player"
        if namespace:
            text = text.replace("android {", f"android {{\n    namespace '{namespace}'", 1)
    text = re.sub(r"compileSdkVersion\s+\d+", "compileSdkVersion 34", text)
    text = re.sub(r"compileSdk\s+\d+", "compileSdk 34", text)
    if text != original:
        gradle.write_text(text)
        print("patched", gradle)
