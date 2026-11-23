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
        # مكتبات Firebase تحتاج أندرويد 6 فأحدث
        s = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23', s)
        s = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', s)
        f.write_text(s, encoding="utf-8")
        print("applicationId and minSdk patched in", name)

# 1ب) R8: تصغير الكود والموارد وإخفاء الأسماء في نسخة الإصدار
shutil.copy(root / "ci" / "android" / "proguard-rules.pro", app / "proguard-rules.pro")
for name in ("build.gradle.kts", "build.gradle"):
    f = app / name
    if not f.exists():
        continue
    s = f.read_text(encoding="utf-8")
    if "proguard-rules.pro" not in s:
        if name.endswith(".kts"):
            block = ('isMinifyEnabled = true\n            isShrinkResources = true\n'
                     '            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")\n'
                     '            signingConfig = signingConfigs.getByName("debug")')
            s = s.replace('signingConfig = signingConfigs.getByName("debug")', block, 1)
        else:
            block = ("minifyEnabled true\n            shrinkResources true\n"
                     "            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'\n"
                     "            signingConfig signingConfigs.debug")
            s = s.replace("signingConfig signingConfigs.debug", block, 1)
        f.write_text(s, encoding="utf-8")
        print("R8 enabled in", name, "proguard-rules.pro" in s)

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
# الإنترنت لازم للمنافسة أون لاين فقط
if "android.permission.INTERNET" not in m:
    m = m.replace("<application", '<uses-permission android:name="android.permission.INTERNET" />\n    <application', 1)
manifest.write_text(m, encoding="utf-8")
print("manifest patched")

# 3) الأيقونة
src = root / "branding" / "android" / "res"
for d in src.iterdir():
    dst = app / "src" / "main" / "res" / d.name
    dst.mkdir(parents=True, exist_ok=True)
    # الأيقونة بصيغة WebP (أصغر حجمًا)، ونحذف نسخة PNG الافتراضية حتى لا يتكرر المورد
    for old in dst.glob("ic_launcher.*"):
        old.unlink()
    for f in d.glob("ic_launcher.*"):
        shutil.copy(f, dst / f.name)
print("icons copied")

# 5) قناة تثبيت الشاشة: نستبدل MainActivity بالنسخة التي تحمل القناة، بالحزمة نفسها
import re as _re
for f in (app / "src" / "main").rglob("MainActivity.kt"):
    pkg = _re.search(r"^package\s+([\w.]+)", f.read_text(encoding="utf-8"), _re.M).group(1)
    tpl = (root / "ci" / "android" / "MainActivity.kt.template").read_text(encoding="utf-8")
    f.write_text(tpl.replace("__PACKAGE__", pkg), encoding="utf-8")
    print("MainActivity patched:", pkg)

