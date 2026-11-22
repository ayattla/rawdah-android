"""يضبط مجلد android المولّد: المعرّف واسم التطبيق والأيقونة وصلاحيات النطق، ويزيل أي صلاحية غير لازمة."""
import pathlib
import re
import shutil

root = pathlib.Path(__file__).resolve().parent.parent
app = root / "android" / "app"

# 1) معرّف التطبيق في Google Play
for name in ("build.gradle.kts", "build.gradle"):
    f = app / name
    if f.exists():
        s = f.read_text(encoding="utf-8")
        s = re.sub(r'applicationId\s*=?\s*"[^"]+"',
                   'applicationId = "com.rawdah.kids"' if name.endswith(".kts") else 'applicationId "com.rawdah.kids"', s)
        f.write_text(s, encoding="utf-8")
        print("applicationId patched in", name)

# 2) الاسم الظاهر وصلاحية محرك النطق، دون إنترنت
manifest = app / "src" / "main" / "AndroidManifest.xml"
m = manifest.read_text(encoding="utf-8")
m = re.sub(r'android:label="[^"]*"', 'android:label="روضة"', m, count=1)
if "TTS_SERVICE" not in m:
    q = ('    <queries>\n        <intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n'
         '        </intent>\n    </queries>\n')
    if "<queries>" in m:
        intent = ('\n        <intent>\n            <action android:name="android.intent.action.TTS_SERVICE" />\n'
                  '        </intent>')
        m = m.replace("<queries>", "<queries>" + intent, 1)
    else:
        m = m.replace("</manifest>", q + "</manifest>", 1)
# منع أي مكتبة من إضافة معرّف الإعلانات
if "com.google.android.gms.permission.AD_ID" not in m:
    if "xmlns:tools" not in m:
        m = m.replace("<manifest ", '<manifest xmlns:tools="http://schemas.android.com/tools" ', 1)
    m = m.replace("<application", '<uses-permission android:name="com.google.android.gms.permission.AD_ID" tools:node="remove" />\n    <application', 1)
manifest.write_text(m, encoding="utf-8")
print("manifest patched")

# 3) الأيقونة
src = root / "branding" / "android" / "res"
for d in src.iterdir():
    dst = app / "src" / "main" / "res" / d.name
    dst.mkdir(parents=True, exist_ok=True)
    shutil.copy(d / "ic_launcher.png", dst / "ic_launcher.png")
print("icons copied")
